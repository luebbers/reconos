-------------------------------------------------------------------------------
-- Filename:        ac97_fifo.vhd
--
-- Description:     This module provides a simple FIFO interface for the AC97
--                  module and provides an asyncrhonous interface for a
--                  higher level module that is not synchronous with the AC97
--                  clock (Bit_Clk).
--
--                  This module will handle all of the initial commands
--                  for the AC97 interface.
--
--                  This module provides a bus independent interface so the
--                  module can be used for more than one bus interface.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              ac97_core
--                 ac97_timing
--              srl_fifo
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
-- Revision:        $$
-- Date:            $$
--
-- History:
--   Mike Wirthlin  
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;

entity ac97_if is
  port (
    ClkIn : in std_logic;
    Reset : in std_logic;
    
    -- All signals synchronous to ClkIn
    PCM_Playback_Left: in std_logic_vector(15 downto 0);
    PCM_Playback_Right: in std_logic_vector(15 downto 0);
    PCM_Playback_Accept: out std_logic;
    
    PCM_Record_Left: out std_logic_vector(15 downto 0);
    PCM_Record_Right: out std_logic_vector(15 downto 0);
    PCM_Record_Valid: out std_logic;

    Debug : out std_logic_Vector(3 downto 0);
    
    AC97Reset_n : out std_logic;        -- AC97Clk
    AC97Clk   : in  std_logic;
    Sync      : out std_logic;
    SData_Out : out std_logic;
    SData_In  : in  std_logic

    );

end entity ac97_if;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;

library unisim;
use unisim.all;

architecture IMP of ac97_if is

  component ac97_core is
  generic (
    C_PCM_DATA_WIDTH : integer := 16
    );
  port (

    Reset : in std_logic;

    -- signals attaching directly to AC97 codec
    AC97_Bit_Clk   : in  std_logic;
    AC97_Sync      : out std_logic;
    AC97_SData_Out : out std_logic;
    AC97_SData_In  : in  std_logic;

    -- AC97 register interface
    AC97_Reg_Addr            : in  std_logic_vector(0 to 6);
    AC97_Reg_Write_Data      : in  std_logic_vector(0 to 15);
    AC97_Reg_Read_Data       : out std_logic_vector(0 to 15);
    AC97_Reg_Read_Strobe     : in  std_logic;  -- initiates a "read" command
    AC97_Reg_Write_Strobe    : in  std_logic;  -- initiates a "write" command
    AC97_Reg_Busy            : out std_logic;
    AC97_Reg_Error           : out std_logic;
    AC97_Reg_Read_Data_Valid : out std_logic;
    
    -- Playback signal interface
    PCM_Playback_Left: in std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
    PCM_Playback_Right: in std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
    PCM_Playback_Left_Valid: in std_logic;
    PCM_Playback_Right_Valid: in std_logic;
    PCM_Playback_Left_Accept: out std_logic;
    PCM_Playback_Right_Accept: out std_logic;

    -- Record signal interface
    PCM_Record_Left: out std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
    PCM_Record_Right: out std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
    PCM_Record_Left_Valid: out std_logic;
    PCM_Record_Right_Valid: out std_logic;

    -- 
    CODEC_RDY : out std_logic

    );
  end component ac97_core;

  component ac97_command_rom is
  port (
    ClkIn : in std_logic;

    ROMAddr : in std_logic_vector(3 downto 0);
    ROMData : out std_logic_vector(24 downto 0)

    );
  end component ac97_command_rom;

  signal pcm_playback_accept_ac97clk : std_logic;
  signal pcm_playback_accept_ClkIn_0 : std_logic;
  signal pcm_playback_accept_ClkIn_1 : std_logic;
  signal pcm_playback_accept_ClkIn : std_logic;
  
  signal pcm_record_valid_ac97clk, pcm_record_valid_ClkIn_0, pcm_record_valid_ClkIn_1 : std_logic;
  signal pcm_record_valid_ClkIn : std_logic;

  signal command_addr : std_logic_vector(6 downto 0);
  signal write_data : std_logic_vector(15 downto 0);
  signal read_data : std_logic_vector(15 downto 0);

  signal codec_rdy : std_logic;
  signal debug_i : std_logic_vector(3 downto 0);
  
  signal reg_write_strobe_ac97, reg_busy_ac97, reg_error_ac97 : std_logic;

  signal get_next_command : std_logic;
  signal valid_command : std_logic;
  signal command_num : unsigned(3 downto 0) := "0000";
  type read_access_states is (AC97_READY, WARM_START,
                              REVIEW_COMMAND,ISSUE_COMMAND,
                              WAIT_COMMAND, NEXT_COMMAND,
                              READ_COMMAND, DONE);
  signal command_SM : read_access_states;
  signal reset_counter : unsigned(10 downto 0) := (others => '0');
  signal AC97Reset_n_i : std_logic := '0';

  signal rom_data : std_logic_vector(24 downto 0);
  signal command_addr_i : std_logic_Vector(3 downto 0);

  signal start_frame_delay : natural range 0 to 3 := 0;

  attribute rom_style: string;
  --attribute rom_style of ac97_command_rom: entity is "distributed";
  
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Command loading
  -----------------------------------------------------------------------------
  load_commands_SM_PROCESS : process (AC97clk) is
  begin
    if AC97clk'event and AC97clk = '1' then

      if Reset = '1' then
        command_SM <= AC97_READY;
        command_num <= "0000";
      else
        
        case command_SM is

          -- Issue some reset?
          when AC97_READY =>
            -- wait until codec is ready
            if codec_rdy = '1' then
              command_SM <= REVIEW_COMMAND;
              start_frame_delay <= 0;
            end if;

          when WARM_START =>
            if pcm_playback_accept_ac97clk = '1' then
              if start_frame_delay = 3 then
                command_SM <= REVIEW_COMMAND;
              else
                start_frame_delay <= start_frame_delay + 1;
              end if;
            end if;
            
          when REVIEW_COMMAND =>
            -- if command is valid, go on to issue command. otherwise, go to
            -- end state.
            if valid_command = '1' then
              command_SM <= ISSUE_COMMAND;
            else
              command_SM <= DONE;
            end if;

          when ISSUE_COMMAND =>
            -- strobe is issued in output forming logic
            command_SM <= WAIT_COMMAND;

          when WAIT_COMMAND =>
            if reg_busy_ac97 = '0' then
              command_SM <= NEXT_COMMAND;
            end if;

          -- error processing?
          when NEXT_COMMAND =>
            command_SM <= READ_COMMAND;
            command_num <= command_num + 1;

          when READ_COMMAND =>
            command_SM <= REVIEW_COMMAND;
            
          when DONE =>
            -- do nothing
          when others => NULL;

        end case;
      end if;
    end if;
  end process;

  reg_write_strobe_ac97 <= '1' when command_SM = ISSUE_COMMAND else
                           '0';
  get_next_command <= '1' when command_SM = NEXT_COMMAND else
                      '0';
  

  --  ClkIn processes
  -- The AC97 reset signal needs to be driven by ClkIn
  -- (AC97 clock does not operate when reset asserted)
  reset_process : process (ClkIn)  is
  begin
    if Reset = '1' then
      reset_counter <= (others => '0');
      AC97Reset_n_i <= '0';
    elsif ClkIn'event and ClkIn='1' then
      if reset_counter(10) = '1' then
        AC97Reset_n_i <= '1';
      else
        reset_counter <= reset_counter+1;
        AC97Reset_n_i <= '0';
      end if;
    end if;
  end process;
  AC97Reset_n <= AC97Reset_n_i;

  process (ClkIn)
  begin
    if ClkIn'event and ClkIn='1' then
      pcm_playback_accept_ClkIn_0 <= pcm_playback_accept_ac97clk;  -- async
      pcm_playback_accept_ClkIn_1 <= pcm_playback_accept_ClkIn_0;
      pcm_playback_accept_ClkIn <= pcm_playback_accept_ClkIn_0 and not pcm_playback_accept_ClkIn_1;
    end if;
  end process;
  PCM_Playback_Accept <= pcm_playback_accept_ClkIn;
  
  process (ClkIn)
  begin
    if ClkIn'event and ClkIn='1' then
      pcm_record_valid_ClkIn_0 <= pcm_record_valid_ac97clk;  -- async
      pcm_record_valid_ClkIn_1 <= pcm_record_valid_ClkIn_0;
      pcm_record_valid_ClkIn <= pcm_record_valid_ClkIn_0 and not pcm_record_valid_ClkIn_1;
    end if;
  end process;
  PCM_Record_Valid <= pcm_record_valid_ClkIn;
  
  -----------------------------------------------------------------------------
  -- Command ROM
  -----------------------------------------------------------------------------
  ROM : ac97_command_rom
  port map (
    ClkIn => AC97Clk,

    ROMAddr => command_addr_i,
    ROMData => rom_data

    );
  command_addr_i <= CONV_STD_LOGIC_VECTOR(command_num, 4);
  
  write_data <= rom_data(15 downto 0);
  command_addr <= rom_data(22 downto 16);
  valid_command <= rom_data(24); 

--   debug_i(0) <= codec_rdy;
--   debug_i(1) <= '1' when command_SM = DONE else
--               '0';
--   debug_i(2) <= AC97Reset_n_i;
--   debug_i(3) <= reg_error_ac97;
  debug_i <= command_addr_i;

  debug <= debug_i;
  
  -----------------------------------------------------------------------------
  -- Instantiating the core
  -----------------------------------------------------------------------------
  ac97_core_I : ac97_core
  port map (

      Reset => Reset,

      AC97_Bit_Clk => AC97Clk,
      AC97_Sync => Sync,
      AC97_SData_Out => SData_Out,
      AC97_SData_In => SData_In,

      AC97_Reg_Addr => command_addr,
      AC97_Reg_Write_Data => write_data,
      AC97_Reg_Read_Data  => open, -- No reading from AC97
      AC97_Reg_Read_Strobe => '0', -- No reading from AC97
      AC97_Reg_Write_Strobe => reg_write_strobe_ac97, -- do
      AC97_Reg_Busy         => reg_busy_ac97, -- do
      AC97_Reg_Error        => reg_error_ac97, -- do
      AC97_Reg_Read_Data_Valid => open,  -- No reading from AC97
    
      PCM_Playback_Left => PCM_Playback_Left,  -- async
      PCM_Playback_Right => PCM_Playback_right,  -- async
      PCM_Playback_Left_Valid => '1',
      PCM_Playback_Right_Valid => '1',
      PCM_Playback_Left_Accept => pcm_playback_accept_ac97clk,
      PCM_Playback_Right_Accept => open,           -- use left_accept

      PCM_Record_Left => PCM_Record_Left,
      PCM_Record_Right => PCM_Record_Right,
      PCM_Record_Left_Valid => pcm_record_valid_ac97clk,
      PCM_Record_Right_Valid => open,   -- use left_valid

      CODEC_RDY  => codec_rdy

    );

--   leds(3) <= not codec_rdy; -- and (command_SM = DONE);
--   leds(2) <= '0' when command_SM = INIT else '1';
--   leds(1) <= '0';
--   leds(0) <= AC97Clk; -- '0' when command_SM = DONE else '1';
  

end architecture IMP;
