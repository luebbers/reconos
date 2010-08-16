-------------------------------------------------------------------------------
-- ac97_core.vhd
-------------------------------------------------------------------------------
--
-- Mike Wirthlin
--
-------------------------------------------------------------------------------
-- Filename:        ac97_acore.vhd
--
-- Description:     Provides a simple synchronous interface to a
--                  AC97 codec. This was designed for the National
--                  LM4549A and only supports slots 0-4.
--                  This interface does not have any data buffering.
--
--                  The interface to the AC97 is straightforward.
--                  To transfer playback data, this interface will
--                  sample the playback data and control signals
--                  when the PCM_Playback_X_Accept signals are asserted.
--                  This sample will
--                  be sent to the codec during the next frame. The Record (
--                  input) data is provided as an ouptput and is valid when
--                  new_frame is asserted.
--                  
--                  This core supports the full 20-bit PCM sample size. The
--                  actual size of the PCM can be modified to a lower value for
--                  easier interfacing using the C_PCM_DATA_WIDTH generic. This
--                  core will stuff the remaining lsb bits with '0' if a value
--                  lower than 20 is used.
--
--                  This core is synchronous to the AC97_Bit_Clk and all
--                  signals interfacing to this core should be synchronized to
--                  this clock.
--
-- AC97 Register Interface
--
--  This core provides a simple interface to the AC97 codec registers. To write
--  a new value to the register, drive the AC97_Reg_Addr and
--  AC97_Reg_Write_Data input signals and assert the AC97_Reg_Write_Strobe
--  signal. To read a register value, drive the AC97_Reg_Addr and assert
--  the AC97_Reg_Read_Strobe signal. Once either strobe has been asserted, the
--  register interface state machine will process the request to the CODEC and
--  assert the AC97_Reg_Busy signal. The strobe control signals will be ignored
--  while the state machine is busy (the AC97 only supports one read or write
--  transaction at a time).
--
--  When the transaction is complete, the state machine will respond as
--  follows: first, the AC97_Reg_Busy signal will be deasserted indicating that
--  the transaction is complete and that the interface is ready to handle
--  another interface. If there was an error with the response (i.e. the AC97
--  codec did not respond properly to the request), the AC97_Reg_Error signal
--  will be asserted. This signal will remain asserted until a new register
--  transfer has been initiated.
--
--  On the successful completion of a register read operation, the
--  AC97_Reg_Read_Data_Valid signal will be asserted to validate the data
--  read from the AC97 controller. This signal will remain asserted until a new
--  register transaction is initiated.
--
--
--  This core will produce valid data on the AC97_SData_Out signal
--  during the following slots:
--
--  Slot 0: Tag Phase (indicates valid slots in packet)
--  Slot 1: Read/Write, Control Address
--  Slot 2: Command Data
--  Slot 3: PCM Left
--  Slot 4: PCM Right
--
--  This core will recognize valid data on the AC97_SData_In signal
--  during the following slots:
--
--  Slot 0: Codec/Slot Status Bits
--  Slot 1: Status Address / Slot Request
--  Slot 2: Status Data
--  Slot 3: PCM Record Left
--  Slot 4: PCM Record Righ
--
-- To Do:
-- - signal to validate recorded data
-- - signal to "request" playback data
-- 
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--    - ac97_core
--      - ac97_timing
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
--
-- History:
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use std.TextIO.all;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;

-------------------------------------------------------------------------------
--
-- Genearics Summary
--   C_PLAYBACK: Enable playback logic. Disable to simplify circuit
--   C_RECORD: Enable record logic. Disable to simplify circuit
--   C_PCM_DATA_WIDTH:
--      AC97 specifies a 20-bit data word. HOwever, many codecs don't
--      support the full resolution (The LM4549 only supports 18). This
--      value indicates the number of data bits that will be sent/received
--      from the CODEC. Zeros will be inserted for least-significant digits.
--
-- Signal Summary
--
--   AC97_Bit_Clk:
--      Input clock generated by the AC97 Codec
--   AC97_Sync:
--      Frame synchronization signal. Generated by ac97_timing module.
--   AC97_SData_Out:
--      Serial data out. Transitions on the rising edge of bit_clk. Is
--      sampled by the CODEC on the falling edge
--   AC97_SData_In:
--      Serial data in. Transitions on the rising edge of bit_clk. Is
--      sampled by the this module on the falling edge.
--   AC97_SData_In:
--   CODEC_RDY:
--      This signal is generated by each frame from the AC97
--      Codec. It arrives each frame as the first bit of Slot 1. 
-------------------------------------------------------------------------------
entity ac97_core is
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

    DEBUG : out std_logic_vector(0 to 15);
    
    -- 
    CODEC_RDY : out std_logic

    );

end entity ac97_core;

library unisim;
use unisim.all;

architecture IMP of ac97_core is
  
  component ac97_timing is
      port (
        Bit_Clk   : in  std_logic;
        Reset     : in  std_logic;
        Sync      : out std_logic;
        Bit_Num   : out natural range 0 to 19;
        Slot_Num  : out natural range 0 to 12;
        Slot_End  : out std_logic;
        Frame_End : out std_logic
      );

    end component ac97_timing;
  
  signal last_frame_cycle : std_logic;
  signal sync_i : std_logic;
  signal slot_end    : std_logic;
  signal slot_No : natural range 0 to 12;
  --signal bit_No : natural range 0 to 19;

  -- register IF signals
  type reg_if_states is (IDLE, WAIT_FOR_NEW_FRAME, SEND_REQUEST_FRAME,
                         RESPONSE_SLOT0, RESPONSE_SLOT1, RESPONSE_SLOT2,
                         END_STATE);
  signal reg_if_state : reg_if_states := IDLE;
  signal register_addr : std_logic_vector(0 to 6) := (others => '0');
  signal register_data : std_logic_vector(0 to 15) := (others => '0');
  signal register_write_cmd : std_logic := '0';

  signal ac97_reg_error_i, ac97_reg_busy_i : std_logic := '0';
  
  signal valid_Frame           : std_logic;
  signal valid_Control_Addr    : std_logic;

  -- Slot 0 in signals
  signal record_pcm_left_valid : std_logic;
  signal record_pcm_right_valid : std_logic;
  --signal return_status_address_valid : std_logic;
  --signal return_status_data_valid : std_logic;

  signal accept_pcm_left : std_logic;
  signal accept_pcm_right : std_logic;

  signal new_data_out : std_logic_vector(19 downto 0) := (others => '0');
  signal data_out     : std_logic_vector(19 downto 0) := (others => '0');
  signal data_in      : std_logic_vector(19 downto 0);

  signal slot0 : std_logic_vector(15 downto 0);
  signal slot1 : std_logic_vector(19 downto 0);
  signal slot2 : std_logic_vector(19 downto 0);
  signal slot3 : std_logic_vector(19 downto 0) := (others => '0');
  signal slot4 : std_logic_vector(19 downto 0) := (others => '0');

  signal codec_rdy_i : std_logic := '0';

  signal PCM_Record_Left_i:  std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
  signal PCM_Record_Right_i: std_logic_vector(0 to C_PCM_DATA_WIDTH-1);

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- AC97 Timing Module & Interface signals
  -----------------------------------------------------------------------------
  ac97_timing_I_1 : ac97_timing
      port map (

        Bit_Clk => AC97_Bit_Clk,
        Reset   => Reset,
        Sync      => sync_i,
        Bit_Num  => open,
        Slot_Num  => slot_No,
        Slot_End  => slot_end,
        Frame_End => last_frame_cycle
      );
  AC97_Sync <= sync_i;

  -----------------------------------------------------------------------------
  -- AC97 Register Interface
  -----------------------------------------------------------------------------
    
  -- Register state machine
  register_if_PROCESS : process (AC97_Bit_Clk) is
  begin
    if RESET = '1' then
      reg_if_state <= IDLE;
      ac97_reg_busy_i <= '0';
      ac97_reg_error_i <= '0';
      AC97_Reg_Read_Data_Valid <= '0';

    elsif AC97_Bit_Clk'event and AC97_Bit_Clk = '1' then

      case reg_if_state is

        -- Wait for a register transfer strobe to occur.
        when IDLE => 

          if (AC97_Reg_Read_Strobe = '1' or AC97_Reg_Write_Strobe = '1')
            and codec_rdy_i = '1' then

            reg_if_state <= WAIT_FOR_NEW_FRAME;
            ac97_reg_busy_i <= '1';
            ac97_reg_error_i <= '0';
            AC97_Reg_Read_Data_Valid <= '0';
            register_addr <= AC97_Reg_Addr;
            if AC97_Reg_Write_Strobe = '1' then
              register_data <= AC97_Reg_Write_Data;
              register_write_cmd <= '1';
            else
              register_write_cmd <= '0';
            end if;
          end if;

          -- Wait for the end of the current frame. During the last cycle of
          -- this state (last_frame_cycle = 1), all the signals are
          -- latched into slot 0 and a valid request is on its way out.
        when WAIT_FOR_NEW_FRAME =>
          if last_frame_cycle = '1' then
            reg_if_state <= SEND_REQUEST_FRAME;
          end if;

          -- Wait for the request to be completely sent to the codec.
        when SEND_REQUEST_FRAME =>
          if last_frame_cycle = '1' then
            reg_if_state <= RESPONSE_SLOT0;
          end if;
          
          -- Wait for the response in slot 0 and make sure the
          -- appropriate response bits are set
        when RESPONSE_SLOT0 =>
          if slot_No = 0 and slot_end = '1' then
            if register_write_cmd = '0' then
              if (data_in(14) /= '1' or data_in(13) /= '1') then
                -- Bit 14 of Slot 0 indicates a valid slot 1 data
                -- (echo the requested address). If this is not a
                -- '1' then there is was an error. Bit 13 of Slot 0
                -- indicates a valid data response. If the transaction
                -- was a read and it is not true, an error.
                ac97_reg_error_i <= '1';
                reg_if_state <= END_STATE;
              else
                reg_if_state <= RESPONSE_SLOT1;
              end if;
            else
              -- Nothing else to do for writes
              reg_if_state <= END_STATE;
            end if;
          end if;

          -- Check the data in slot 1 and make sure it matches
          -- the address sent
        when RESPONSE_SLOT1 =>
          if slot_No = 1 and slot_end = '1' then
            if data_in(18 downto 12) /= register_addr then
              ac97_reg_error_i <= '1';
              reg_if_state <= END_STATE;
            else 
              -- we need to get the data for read commands
              reg_if_state <= RESPONSE_SLOT2;
            end if;
          end if;

        when RESPONSE_SLOT2 =>
          if slot_No = 2 and slot_end = '1' then
            AC97_Reg_Read_Data <= data_in(19 downto 4);
            AC97_Reg_Read_Data_Valid <= '1';
            reg_if_state <= END_STATE;
          end if;
          
        when END_STATE =>
          ac97_reg_busy_i <= '0';
          reg_if_state <= IDLE;

        when others => NULL;

      end case;
    end if;
  end process register_if_PROCESS;
  AC97_Reg_Busy <= ac97_reg_busy_i;
  AC97_Reg_Error <= ac97_reg_error_i;

  with reg_if_state select 
    debug(0 to 2) <= "000" when IDLE,
                       "001" when  WAIT_FOR_NEW_FRAME,
                       "010" when  SEND_REQUEST_FRAME,
                       "011" when  RESPONSE_SLOT0,
                       "100" when  RESPONSE_SLOT1,
                       "101" when  RESPONSE_SLOT2,
                       "110" when  END_STATE,
                       "000" when others;
  debug(3 to 15) <= (others => '0');
    
  -- This signal indicates that we are sending a request command
  -- and that the address send to the codec is valid
  valid_Control_Addr <= '1' when reg_if_state = WAIT_FOR_NEW_FRAME
                        else '0';


  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Output Section
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- Setup slot0 data at start of frame
  --
  -- Slot 0 is the TAG slot. The bits of this slot are defined as
  -- follows:
  -- bit 15: Valid frame
  -- bit 14: valid control address (slot 1)
  -- bit 13: valid control data (slot 2)
  -- bit 12: valid PCM playback data Left (slot 3)
  -- bit 11: valid PCM playback data Right (slot 4)
  -- bot 10-2: ignored - fill with zeros
  -- bit 1-0: 2-bit codec ID (assigned to '00' for primary)
  --
  -- The slot 0 signals are created directly from the inputs
  -- of the module rather than using the "registered" versions
  -- (i.e. ac97_reg_write instead of ac97_reag_write_i). The
  -- slot0 signal is latched on the clock edge following
  -- the frame signal into the shift register signal "data_out".
  -- 
  -----------------------------------------------------------------------------

  -- temporary
  
  valid_Frame <= valid_Control_Addr or
                 pcm_playback_left_valid or
                 pcm_playback_right_valid;

  slot0(15)         <= valid_Frame;
  slot0(14)         <= valid_Control_Addr;
  slot0(13)         <= register_write_cmd;  -- valid data only during write
  slot0(12)         <= PCM_Playback_Left_Valid;
  slot0(11)         <= PCM_Playback_Right_Valid;
  slot0(10 downto 2) <= "000000000";
  slot0(1 downto 0) <= "00";
  
  -----------------------------------------------------------------------------
  -- Slot 1
  --
  -- Slot 1 is the Command Address:
  -- Bit 19: Read/Write (1=read,0=write)
  -- Bit 18-12: Control register index/address
  -- Bit 11:0 reserved (stuff with 0)
  -----------------------------------------------------------------------------
  slot1(19)           <= not register_write_cmd;
  slot1(18 downto 12) <= register_addr;
  slot1(11 downto 0) <= (others => '0');

  -----------------------------------------------------------------------------
  -- Slot 2
  --
  -- Slot 2 is the Command Data Port:
  -- Bit 19-4: Control register write data 
  -- Bit 3-0: reserved (stuff with 0)
  -----------------------------------------------------------------------------
  slot2(19 downto 4) <= register_data;
  slot2( 3 downto 0) <= (others => '0');

  -----------------------------------------------------------------------------
  -- Setup slot3 data (PCM play left)
  -----------------------------------------------------------------------------
  process (PCM_Playback_Left) is
  begin
    slot3((20 - C_PCM_DATA_WIDTH-1) downto 0) <= (others => '0');
    slot3(19 downto (20 - C_PCM_DATA_WIDTH)) <= PCM_Playback_Left;
  end process;

  -----------------------------------------------------------------------------
  -- Setup slot4 data (PCM play right)
  -----------------------------------------------------------------------------
  process (PCM_Playback_Right) is
  begin
    slot4((20 - C_PCM_DATA_WIDTH-1) downto 0) <= (others => '0');
    slot4(19 downto (20 - C_PCM_DATA_WIDTH)) <= PCM_Playback_Right;
  end process;

  -----------------------------------------------------------------------------
  -- Output data multiplexer for AC97_SData_Out signal
  --
  -- Choose the appropriate data to send out the shift register
  -- (new_data_out)
  -----------------------------------------------------------------------------
  process (last_frame_cycle, slot_end, slot_No, slot0,
           slot1, slot2, slot3, slot4) is
  begin  -- process
    new_data_out <= (others => '0');
    if (last_frame_cycle = '1') then
      new_data_out(19 downto 4) <= slot0;
    elsif (slot_end = '1') then
      case slot_No is
        when 0 => new_data_out(slot1'range) <= slot1;
        when 1 => new_data_out(slot2'range) <= slot2;
        when 2 => new_data_out <= slot3;
        when 3 => new_data_out <= slot4;
        when others => null;
      end case;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- AC97 data out shift register
  -----------------------------------------------------------------------------
  Data_Out_Handle : process (AC97_Bit_Clk) is
  begin  -- process Data_Out_Handle
    if reset = '1' then
      data_out <= (others => '0');
    elsif AC97_Bit_Clk'event and AC97_Bit_Clk = '1' then  -- rising clock edge
      if (last_frame_cycle = '1') or (slot_end = '1') then
        data_out <= New_Data_Out;
      else
        data_out(19 downto 0) <= data_out(18 downto 0) & '0';
      end if;
    end if;
  end process Data_Out_Handle;
  AC97_SData_Out <= data_out(19);

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Input Section
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- AC97 data in shift register
  -----------------------------------------------------------------------------
  Shifting_Data_Coming_Back : process (AC97_Bit_Clk) is
  begin  -- process Shifting_Data_Coming_Back
    if AC97_Bit_Clk'event and AC97_Bit_Clk = '0' then  -- falling clock edge
      data_in(19 downto 0) <= data_in(18 downto 0) & AC97_SData_In;
    end if;
  end process Shifting_Data_Coming_Back;

  -----------------------------------------------------------------------------
  -- Get slot 0 data (TAG - which slots are valid)
  -----------------------------------------------------------------------------
  process (AC97_Bit_Clk) is
  begin
    if AC97_Bit_Clk'event and AC97_Bit_Clk = '1' then  -- rising clock edge
      if (slot_no = 0 and slot_end = '1') then
        codec_rdy_i           <= data_in(15);
        -- data_in(14) and data(13) are used directly in the reg_if
        -- state machine
        --return_status_address_valid <= data_in(14);
        -- return_status_data_valid <= data_in(13);
        record_pcm_left_valid <= data_in(12);
        record_pcm_right_valid <= data_in(11);
      end if;
    end if;
  end process;

  PCM_Record_Left_Valid <= record_pcm_left_valid and last_frame_cycle;
  PCM_Record_Right_Valid <= record_pcm_right_valid and last_frame_cycle;
                           
  codec_rdy <= codec_rdy_i;

  -----------------------------------------------------------------------------
  -- Get slot 1 PCM request bit
  -----------------------------------------------------------------------------
  process (AC97_Bit_Clk) is
  begin
    if AC97_Bit_Clk'event and AC97_Bit_Clk = '1' then
      if (slot_end = '1' and slot_No = 1 ) then
        accept_pcm_left <= not data_in(11);
        accept_pcm_right <= not data_in(10);
      end if;
    end if;
  end process;

  PCM_Playback_Left_Accept <= accept_pcm_left and last_frame_cycle;
  PCM_Playback_Right_Accept <= accept_pcm_right and last_frame_cycle;
  
  -----------------------------------------------------------------------------
  -- Get slot 3 and 4 data
  -----------------------------------------------------------------------------
  Get_Record_Data : process (AC97_Bit_Clk) is
    -- synthesis translate_off
    variable my_line : LINE;
    -- synthesis translate_on
  begin  -- process Get_Record_Data
    if AC97_Bit_Clk'event and AC97_Bit_Clk = '1' then  -- rising clock edge
      if (slot_end = '1' and slot_No = 3 ) then
        PCM_Record_Left_i   <= data_in(19 downto (20 - C_PCM_DATA_WIDTH));
        -- synthesis translate_off
        write(my_line, string'("AC97 Core: Received Left Value "));
        write(my_line, bit_vector'( To_bitvector(PCM_Record_Left_i)  ));
        writeline(output, my_line);
        -- synthesis translate_on
      elsif (slot_end = '1' and slot_No = 4 ) then
        PCM_Record_Right_i   <= data_in(19 downto (20 - C_PCM_DATA_WIDTH));
        -- synthesis translate_off
        write(my_line, string'("AC97 Core: Received Right Value "));
        write(my_line, bit_vector'( To_bitvector(PCM_Record_Right_i)  ));
        writeline(output, my_line);
        -- synthesis translate_on
      end if;
    end if;
  end process Get_Record_Data;
  PCM_Record_Left <= PCM_Record_Left_i;
  PCM_Record_Right <= PCM_Record_Right_i;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------

end architecture IMP;

