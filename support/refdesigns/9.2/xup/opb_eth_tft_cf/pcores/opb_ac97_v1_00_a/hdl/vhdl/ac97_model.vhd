-------------------------------------------------------------------------------
-- ac97_model.vhd
-------------------------------------------------------------------------------
--
-- Mike Wirthlin
--
-------------------------------------------------------------------------------
-- Filename:        ac97_model.vhd
--
-- Description:
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use std.TextIO.all;

entity ac97_model is
  generic (
    BIT_CLK_STARTUP_TIME : time := 1 us
    );
  port (
    AC97Reset_n : in std_logic;
    Bit_Clk   : out  std_logic;
    Sync      : in std_logic;
    SData_Out : in std_logic;
    SData_In  : out  std_logic
    );
end entity ac97_model;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;
use opb_ac97_v2_00_a.testbench_ac97_package.all;

architecture model of ac97_model is

  signal reset_delay : std_logic := '1';
  signal initial_reset : std_logic := '0';
  
  signal bit_clk_i, bit_clk_freq : std_logic;

  signal sync_d, end_of_frame, end_of_slot : std_logic;

  signal frame_count : integer := 1;
  signal valid_frame,codec_rdy : std_logic := '0';

  signal shift_reg_in, shift_reg_out : std_logic_vector(19 downto 0) := (others => '0');
  
  signal left_in_data, right_in_data : std_logic_vector(15 downto 0);

  signal register_control_valid, register_data_valid : std_logic;
  signal register_write, register_read : std_logic := '0';
  signal register_address : std_logic_vector(6 downto 0) := (others => '0');
  
  signal slot0_in : std_logic_vector(15 downto 0) := (others => '0');
  signal slot1_in : std_logic_vector(19 downto 0) := (others => '0');
  signal slot2_in : std_logic_vector(19 downto 0) := (others => '0');
  signal slot3_in : std_logic_vector(19 downto 0) := (others => '0');
  signal slot4_in : std_logic_vector(19 downto 0) := (others => '0');

  signal slot0_out : std_logic_vector(15 downto 0) := (others => '0');
  signal slot1_out : std_logic_vector(19 downto 0):= (others => '0');
  signal slot2_out : std_logic_vector(19 downto 0):= (others => '0');
  signal slot3_out : std_logic_vector(19 downto 0):= (others => '0');
  signal slot4_out : std_logic_vector(19 downto 0) := (others => '0');
  signal slot_counter : integer;
  signal bit_counter : integer;
    
  -- 
  type register_type is array(0 to 63) of std_logic_vector(15 downto 0);
  signal ac97_registers : register_type := (
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000"
      );

  type audio_type is array(0 to 15) of std_logic_vector(15 downto 0);
  signal record_values : audio_type := (
      X"1234", X"2345", X"3456", X"4567", X"5678", X"6789", X"789a", X"89ab",
      X"1234", X"2345", X"3456", X"4567", X"5678", X"6789", X"789a", X"89ab"
      );
  signal record_value : unsigned(19 downto 0) := X"00010";
  signal record_sample_counter : integer := 0;
  signal temp_record_sample_count : integer := 0;
  signal temp_play_sample_count : integer := 0;
  signal valid_record_data : std_logic := '0';
  signal request_play_data : std_logic := '0';
  constant sample_skip : integer := 3;  -- skip every 3rd sample
    
begin

  -----------------------------------------------------------------------------
  -- Clock
  -----------------------------------------------------------------------------
  
  -- simulate a 12.8? MHz ac97 clk
  ac97_clk_freq_PROCESS: process
  begin 
    Bit_Clk_freq <= '0'; 
    wait for 40.69 ns;
    Bit_Clk_freq <= '1'; 
    wait for 40.69 ns;
  end process ac97_clk_freq_PROCESS;

  process (ac97reset_n)
  begin 
    if ac97reset_n = '0' and ac97reset_n'event then
      initial_reset <= '1';
    end if;
  end process;
  
  
  -- Delay state machine to simulate a delay on the bit clock
  reset_delay <= transport AC97Reset_n after BIT_CLK_STARTUP_TIME;

  -- Gated bit clock signal
  Bit_Clk_i <= Bit_Clk_freq when reset_delay = '1' and ac97reset_n = '1'
               and initial_reset = '1'
               else '0';
  bit_clk <= bit_clk_i;

  
  -----------------------------------------------------------------------------
  -- Receiving shift register
  -----------------------------------------------------------------------------
   process (bit_clk_i)
   begin
     if (bit_clk_i = '0' and bit_clk_i'event) then
       shift_reg_out <= shift_reg_out(18 downto 0) & sdata_out;
     end if;
   end process;

   process (bit_clk_i)
   begin
     if (bit_clk_i = '0' and bit_clk_i'event) then
       if (bit_counter = 0) then
         if (slot_counter = 1) then
           slot0_out <= shift_reg_out(15 downto 0);
         elsif (slot_counter = 2) then 
           slot1_out <= shift_reg_out;
         elsif (slot_counter = 3) then 
           slot2_out <= shift_reg_out;
         elsif (slot_counter = 4) then 
           slot3_out <= shift_reg_out;
         elsif (slot_counter = 5) then
           slot4_out <= shift_reg_out;
         end if;
       end if;
     end if;
   end process;
  register_control_valid <= slot0_out(14) and slot0_out(15);
  register_data_valid <= slot0_out(13) and slot0_out(15);
  register_address <= slot1_out(18 downto 12);
  register_write <= register_control_valid and (not slot1_out(19));
  register_read <= register_control_valid and slot1_out(19);
                    
  -----------------------------------------------------------------------------
  -- Register return data interface
  -----------------------------------------------------------------------------
  process (bit_clk_i)
    variable my_line : LINE;
  begin
    if bit_clk_i = '1' and bit_clk_i'event and end_of_slot = '1'
       and slot_counter = 5 then
          if register_read = '1' then
            slot2_in <= X"A55A0";         -- send sample data
            slot0_in(13) <= '1';
            write(my_line, string'("CODEC: Reading from address "));
            write(my_line, bit_vector'( To_bitvector( register_address)  ));
            writeline(output, my_line);
          else
            slot2_in <= (others => '0');
            slot0_in(13) <= '0';
          end if;
     end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Register write
  -----------------------------------------------------------------------------
  process (bit_clk_i)
    variable my_line : LINE;
  begin
    if bit_clk_i = '1' and bit_clk_i'event and end_of_slot = '1'
       and slot_counter = 5 then
          if register_write = '1' then
            write(my_line, string'("CODEC: Writing value "));
            write(my_line, bit_vector'( To_bitvector( slot2_out(19 downto 4))));
            write(my_line, string'(" to address "));
            write(my_line, bit_vector'( To_bitvector( register_address)  ));
            writeline(output, my_line);
          end if;
     end if;
  end process;

  -----------------------------------------------------------------------------
  -- Slot in
  -----------------------------------------------------------------------------
  slot0_in(15) <= codec_rdy;
  slot0_in(14) <= register_control_valid;  -- mimic register command
  -- slot_in(13) set by register return state machine
  slot0_in(12) <= valid_record_data;                  -- valid PCM
  slot0_in(11) <= valid_record_data;                  -- valid PCM
  slot0_in(10 downto 0) <= (others => '0');
  
  slot1_in <= '0' & register_address &
              (not request_play_data) & (not request_play_data) & "0000000000";
  
  -----------------------------------------------------------------------------
  -- Play Data
  -----------------------------------------------------------------------------
  process (bit_clk_i)
    variable my_line : LINE;
  begin
    if ac97reset_n = '0' then
      request_play_data <= '0';
      temp_play_sample_count <= 0;
    elsif bit_clk_i = '1' and bit_clk_i'event and end_of_slot = '1'
       and slot_counter = 6 then
      temp_play_sample_count <= temp_play_sample_count +  1;
      if temp_play_sample_count = sample_skip then
        temp_play_sample_count <= 0;
        request_play_data <= '0';
      else
        request_play_data <= '1';
      end if;
    end if;
  end process;

  process (bit_clk_i)
    variable my_line : LINE;
  begin
    if bit_clk_i = '1' and bit_clk_i'event and end_of_slot = '1'
       and slot_counter = 5 then
      if request_play_data = '1' then
        write(my_line, string'("CODEC: Playback Left="));
        write(my_line, bit_vector'( To_bitvector( slot3_out )  ));
        write(my_line, string'(" Playback Right="));
        write(my_line, bit_vector'( To_bitvector( slot4_out )  ));
        writeline(output, my_line);
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Record Data
  -----------------------------------------------------------------------------
  process (bit_clk_i)
    variable my_line : LINE;
  begin
    if ac97reset_n = '0' then
      slot3_in <= (others => '0');
      slot4_in <= (others => '0');
      valid_record_data <= '0';
    elsif bit_clk_i = '1' and bit_clk_i'event and end_of_slot = '1'
       and slot_counter = 5 then
      temp_record_sample_count <= temp_record_sample_count +  1;
      if temp_record_sample_count = sample_skip then
        temp_record_sample_count <= 0;
        slot3_in <= X"00000";
        slot4_in <= X"00000";
        valid_record_data <= '0';
      else
        slot3_in <= CONV_STD_LOGIC_VECTOR(record_value,20);
        slot4_in <= CONV_STD_LOGIC_VECTOR(record_value,20);
        record_value <= record_value + 16;
        valid_record_data <= '1';
      end if;
    end if;
  end process;

  
  -----------------------------------------------------------------------------
  -- Sending shift register
  -----------------------------------------------------------------------------
  process (bit_clk_i)
  begin
    if ac97reset_n = '0' then
      shift_reg_in <= (others => '0');
    elsif (bit_clk_i = '1' and bit_clk_i'event) then
      if end_of_slot = '1' then
        case slot_counter is
          when 12 =>                    -- slot 0
            shift_reg_in <= slot0_in & "0000";
          when 0 =>                     -- slot 1
            shift_reg_in <= slot1_in;
          when 1 =>
            shift_reg_in <= slot2_in;
          when 2 =>
            shift_reg_in <= slot3_in;
          when 3 =>
            shift_reg_in <= slot4_in;
          when others =>
            shift_reg_in <= (others => '0');
        end case;
      else
        shift_reg_in <= shift_reg_in(18 downto 0) & '0';
      end if;
    end if;
  end process;
  SData_In <= shift_reg_in(19);
  
  -----------------------------------------------------------------------------
  -- Codec Ready
  -----------------------------------------------------------------------------
  process(bit_clk_i)
  begin
    if (AC97Reset_n = '0') then
      codec_rdy <= '0';
    elsif (bit_clk_i = '1' and bit_clk_i'event) then
      if codec_rdy = '0' and end_of_frame = '1' and valid_frame = '1' then
        codec_rdy <= '1';
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Valid frame checker
  -----------------------------------------------------------------------------
  process(bit_clk_i)
  begin
    if (AC97Reset_n = '0') then
      valid_frame <= '0';
      frame_count <= 0;
    elsif (bit_clk_i = '1' and bit_clk_i'event) then
      if end_of_frame = '1' then
        if (frame_count = 255) then
          valid_frame <= '1';
        else
          valid_frame <= '0';
        end if;
        frame_count <= 0;
      else
        frame_count <= frame_count + 1;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- End of frame set by sync
  -----------------------------------------------------------------------------
  process(bit_clk_i)
  begin
    if (bit_clk_i = '1' and bit_clk_i'event) then
      sync_d <= sync;
    end if;
  end process;
  end_of_frame <= sync and (not sync_d);

  -----------------------------------------------------------------------------
  -- slot_counter & bit_counter state machine
  -----------------------------------------------------------------------------
  end_of_slot <= '1' when ((slot_counter = 0 and bit_counter = 15) or
                           bit_counter = 19)
                 else '0';
  
  process (bit_clk_i)
  begin
    if (AC97Reset_n = '0') then
      bit_counter <= 0;
      slot_counter <= 0;
    elsif (bit_clk_i = '1' and bit_clk_i'event) then
      -- wait for sync to initialize sequence
      if (end_of_frame = '1') then
        slot_counter <= 0;
        bit_counter <= 0;
      else
        if end_of_slot = '1' then
          bit_counter <= 0;
          if slot_counter = 12 then
            slot_counter <= 0;
          else 
            slot_counter <= slot_counter + 1;
          end if;
        else
          bit_counter <= bit_counter +1;
        end if;
      end if;
    end if;
  end process;


end architecture model;
