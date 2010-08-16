-------------------------------------------------------------------------------
-- Filename:        ac97_timing.vhd
--
-- Description:     Provides the primary timing signals for the AC97 protocol.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
--   This module is approximately 14 slices
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
-- 
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity ac97_timing is
  port (
    Bit_Clk   : in  std_logic;
    Reset     : in  std_logic;
    Sync      : out std_logic;
    Bit_Num   : out natural range 0 to 19;
    Slot_Num  : out natural range 0 to 12;
    Slot_End  : out std_logic;
    Frame_End : out std_logic
    );

end entity ac97_timing;

library unisim;
use unisim.all;

architecture IMP of ac97_timing is

   signal slotnum_i : natural range 0 to 12 := 0;
   signal bitnum_i  : natural range 0 to 19 := 0;
   signal sync_i : std_logic := '0';
   signal frame_end_i : std_logic := '0';

   signal slot_end_i  : std_logic;
   signal init_sync : std_logic;
   signal reset_sync :std_logic;
   
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  --
  -- This module will generate the timing signals for the AC97 core. This
  -- module will sequence through the timing of a complete AC97 frame. All
  -- timing signals are syncronized to the input Bit_Clk. The Bit_Clk is driven
  -- externally (from the AC97 Codec) at a frequency of 12.288 Mhz.
  --
  -- The AC97 frame is 256 clock cycles and is organized as follows:
  --
  -- 16 cycles for Slot 0
  -- 20 cycles each for slots 1-12
  --
  -- The total frame time is 16 + 12*20 = 256 cycles. With a Bit_Clk frequency
  -- of 12.288 MHz, the frame frequency is 48,000 and the frame period is
  -- 20.83 us.
  --
  -- The signals created in this module are:
  --
  -- Sync:        Provides the AC97 Sync signal for slot 0
  -- Frame_End:   Signals the last cycle of the AC97 frame.
  -- Slot_Num:    Indicates the current slot number
  -- Slot_End:    Indicates the end of the current slot
  -- Bit_Num:     Indicates current bit of current slot
  --
  -- All signals transition on the rising clock edge of Bit_Clk
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Sync
  --
  -- A low to high transition on Sync signals to the AC97 codec that a
  -- new frame is about to begin. This signal is first asserted during the
  -- *last* cycle of the frame. The signal transitions on the rising
  -- edge of bit_clk and is sampled by the CODEC on the rising edge of
  -- the next clock (it will sample the signal one cycle later or during
  -- the first cycle of the next frame).
  --
  -- Sync is asserted for 16 bit clks.
  --
  -----------------------------------------------------------------------------

  -- Slot end occurs at bit 15 for slot 0 and cycle 19 for the others
  slot_end_i <= '1' when ((slotnum_i = 0 and bitnum_i = 15) or
                          bitnum_i = 19)
                else '0';
  Slot_End <= slot_end_i;

  -- The sync signal needs to be asserted during the last cycle of the
  -- frame (slot 12, bit 19). This signal is asserted one cycle
  -- earlier so the sync signal can be registered.
  init_sync <= '1' when (slotnum_i = 12 and bitnum_i = 18)
               else '0';
  -- The last cycle of the sync signal occurs during bit 14 of slot 0.
  -- This signal is asserted during this cycle to insure sync is
  -- cleared during bit 15 of slot 0
  reset_sync <= '1' when slotnum_i = 0 and bitnum_i = 14
               else '0';
  
  process (Bit_Clk) is
  begin
    if Reset = '1' then
      sync_i <= '0';
    elsif Bit_Clk'event and Bit_Clk = '1' then  -- rising clock edge
      if sync_i = '0' and init_sync = '1' then
        sync_i <= '1';
      elsif sync_i = '1' and reset_sync = '1' then
        sync_i <= '0';
      end if;
    end if;
  end process;
  Sync <= sync_i;

  -----------------------------------------------------------------------------
  -- New_frame
  --
  -- New_frame is asserted for one clock cycle during the *last* clock cycles
  -- of the current frame. New_frame is asserted during the first
  -- cycle that sync is asserted. 
  --
  -----------------------------------------------------------------------------
  process (Bit_Clk) is
  begin
    if Reset = '1' then
      frame_end_i <= '0';
    elsif Bit_Clk'event and Bit_Clk = '1' then  -- rising clock edge
      if frame_end_i = '0' and init_sync = '1' then
        frame_end_i <= '1';
      else
        frame_end_i <= '0';
      end if;
    end if;
  end process;
  Frame_End <= frame_end_i;
  
  -----------------------------------------------------------------------------
  -- Provide a counter for the slot number and current bit number.
  -----------------------------------------------------------------------------
  process (Bit_Clk) is
  begin
    if Reset = '1' then
      bitnum_i <= 0;
      slotnum_i <= 0;
    elsif Bit_Clk'event and Bit_Clk = '1' then  -- rising clock edge
      if slot_end_i = '1' then
        bitnum_i <= 0;
        if slotnum_i = 12 then
          slotnum_i <= 0;
        else
          slotnum_i <= slotnum_i + 1;
        end if;
      else
        bitnum_i <= bitnum_i + 1;
      end if;
    end if;
  end process;
  Slot_Num <= slotnum_i;
  Bit_Num <= bitnum_i;
  
  
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------

end architecture IMP;

