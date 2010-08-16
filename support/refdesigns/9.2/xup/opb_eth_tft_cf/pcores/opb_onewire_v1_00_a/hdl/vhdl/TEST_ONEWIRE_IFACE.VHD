-------------------------------------------------------------------------------
-- Title      : Test bench for the 1-wire interface
-- Project    : 
-------------------------------------------------------------------------------
-- File       : TEST_ONEWIRE_IFACE.VHD
-- Author     : Davy Huang  <daihuang@xilinx.com>
-- Company    : Xilinx, Inc.
-- Created    : 2001-04-18
-- Last update: 2001-04-18
-- Platform   : ModelSim XE 5.3d
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2001 Xilinx, Inc.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001-04-18  1.0      davy	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity onewire_iface_tb is
  generic (
        CheckCRC : boolean := true;
        ADD_PULLUP : boolean := true;  
        CLK_DIV  : integer range 0 to 12 := 12;
        AssDly   : time    := 100 ps); 
end onewire_iface_tb;

architecture arch of onewire_iface_tb is 

    component onewire_iface
    generic (
            CheckCRC : boolean;
            ADD_PULLUP : boolean;
            CLK_DIV  : integer range 0 to 12);
      port (
            sys_clk     : in  std_logic;    -- system clock (50Mhz)
            sys_reset   : in  std_logic;    -- active high syn. reset 
            dq          : inout std_logic;  -- connect to the 1-wire bus
            data        : out std_logic_vector(7 downto 0); -- data output
            data_valid  : out std_logic;    -- data output valid (20us strobe)
            crc_ok      : out std_logic;    -- crc ok signal (active high)
            sn_data     : out std_logic_vector(47 downto 0));  -- parallel out
    end component;

    signal clk        :  std_logic;
    signal reset      :  std_logic;
    signal crc_ok     :  std_logic;
    signal dq         :  std_logic;
    signal data       :  std_logic_vector(7 downto 0);
    signal data_valid : std_logic;
    signal sn_data    :  std_logic_vector(47 downto 0);
    
begin

    uut: onewire_iface 
    generic map (
        CheckCRC   => CheckCRC,
        ADD_PULLUP => ADD_PULLUP,
        CLK_DIV    => CLK_DIV)
    port map(
        sys_clk      => clk,
        sys_reset    => reset,
        crc_ok       => crc_ok,
        data         => data, 
        data_valid   => data_valid,
        sn_data      => sn_data,
        dq           => dq);


    clkgen: process
      begin
       Clk <= '0';
       wait for 10 ns;
       Clk <= '1';
       wait for 10 ns;
     end process clkgen;
    
    tb : process
      begin
        dq  <= 'Z';
        reset <= '1';
        wait for 1 us;
        reset <= '0';
        wait for 560 us;  
        dq  <= '0'; -- presence pulse of 240 us
        wait for 240 us;
        dq  <= 'Z'; 
        wait for 926 us;
        dq  <= 'Z'; -- 1-wire device begin to send out data (all ones)
                    -- The caculated CRC will be 0x14
        wait for 4659 us;
        dq  <= '0'; -- 1-wire device sends the last byte of data (CRC=0x14)
        wait for 80 us;
        dq  <= '0';
        wait for 80 us;
        dq  <= '1';
        wait for 80 us;
        dq  <= '0';
        wait for 80 us;
        dq  <= '1';
        wait for 80 us;
        dq  <= '0';
        wait for 80 us;
        dq  <= '0';
        wait for 80 us;
        dq  <= '0';
        wait for 80 us;
        dq  <= 'Z';           -- CRC will match
        wait; -- wait forever
     end process tb;

end arch;
