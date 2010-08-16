-------------------------------------------------------------------------------
-- Title      : An interface to use the 1-Wire Master
-- Project    : 
-------------------------------------------------------------------------------
-- File       : onewire_iface.vhd
-- Author     : Davy Huang <Dai.Huang@Xilinx.com>
-- Company    : Xilinx, Inc.
-- Created    : 2001/02/01
-- Last Update: 2001-04-18
-- Copyright  : (c) Xilinx Inc, 2001
-------------------------------------------------------------------------------
-- Uses       : 1-Wire Master (onewire_master.vhd), Clock Divider (clk_div.vhd)
-------------------------------------------------------------------------------
-- Used by    : Any user system connecting to a 1-Wire device
-------------------------------------------------------------------------------
-- Description: An interface to show how to use the 1-Wire Master
--
--              It will output the data from the DS2401 byte by byte
--              while data_valid is asserted. Totally 8 bytes of data will
--              show up on the data bus in sequence of:
--                Family code (x01 for DS2401) : 1 byte
--                Serial number (e.g. xABCDEF) : 6 bytes
--                CRC value (based on polynomial=X^8 + X^5 + X^4 + 1) : 1 byte
--              So, user will get total 8 strobes of data_valid after the
--              reset.
--                
--              It connects to the DS2401 through only one wire (dq),
--              which is a bidirectional data path with internal pullup
--              resistor (about 13K Ohm, which is higher than the specification
--              of 5K Ohm on the DS2401 datasheet) or an external pull-up
--              resistor.
--
--              It uses a clock divider to generate a slow clock (1MHz) for
--              the 1-Wire Master module from the system clock. Use a generic
--              (CLK_DIV) to specify the divider ratio for different input
--              clock rate.
--
--              It generates a crc_ok signal which indicates all the data have
--              been received/output and crc checking is OK if the generic
--              (CheckCRC) is turned on.
--              
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001/02/01  1.0      Davy    Create the initial design
-- 2001/02/14  1.1      Davy    Use SRL16 instead of Johnson Counter to
--                              generate clock.
-- 2001/03/06  1.1      Davy    Clean comments
-- 2001/03/15  1.2      Davy    Add parallel output
-- 2001/04/12  1.2      Davy    Add generic ADD_PULLUP
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- synthesis translate_off
-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on
-- synthesis translate_on

entity onewire_iface is
    generic (
           CLK_DIV  : integer range 0 to 15 := 12;
                                           -- Clock Divider for 50MHz system
                                           -- clock input
           ADD_PULLUP : boolean := true;   -- add an pullup on the 1-Wire bus
           CheckCRC : boolean := true);    -- turn on/off CRC Generator
    port (
           sys_clk     : in  std_logic;    -- system clock (50Mhz)
           
           sys_reset   : in  std_logic;    -- active high syn. reset 
                                         
           dq          : inout std_logic;  -- connect to the 1-wire bus
                     
           data        : out std_logic_vector(7 downto 0); -- data output
           
           data_valid  : out std_logic;    -- data output valid (20us strobe)
           
           crc_ok      : out std_logic;    -- crc ok signal (active high)
           
           sn_data     : out std_logic_vector(47 downto 0)
                                           -- parallel output (valid when
                                           -- crc_ok is active)
              );
end onewire_iface;

architecture rtl of onewire_iface is

   component onewire_master
      generic (CheckCRC : boolean);
      port (
             clk_1MHz  : in  std_logic;    
             reset     : in  std_logic;    
             dq        : inout std_logic;
             data      : out std_logic_vector(7 downto 0);
             data_valid: out std_logic;
             crcok     : out std_logic;
             sn_data   : out std_logic_vector(47 downto 0)
                );
    end component;

    component PULLUP   -- pull up resistor component
       port (O : out std_logic);
    end component;
    
    component clk_divider
      generic (CLK_DIV : integer range 0 to 15);  -- Clock Divider
      port (
       reset   : in  std_logic;    -- asynchronous reset
       clk_in  : in  std_logic;    -- system clock 
       clk_out : out std_logic);   -- output a slow clock
    end component;
    
    -- signals for reset    
    signal reset_i : std_logic;

    -- signals for generating clock
    signal clk_1MHz    : std_logic;

    -- signals for crc output
    signal crcok    : std_logic;


begin


   -----------------------------------------------------------
   -- wiring
   -----------------------------------------------------------
    reset_i <= sys_reset;      
    
    crc_ok  <=  crcok;    

   -----------------------------------------------------------
   -- Generate a 1MHz clock for the onewire_master
   -- using the clock divider
   --
   -----------------------------------------------------------
   --   Table : Generic Settings in Clock Divider Based on
   --           Input Clock Rates 
   -----------------------------------------------------------
   -- Min Input        Max Input     Divider   CLK_DIV 
   -- Clock Freq.     Clock Freq.     Ratio     Value
   --  (MHz)             (MHz) 
   -----------------------------------------------------------
   --    3              5                4         0
   --    5              9                8         1
   --    9             14                12        2
   --   14             18                16        3
   --   18             22                20        4
   --   22             26                24        5
   --   26             30                28        6
   --   30             34                32        7
   --   34             38                36        8
   --   38             42                40        9
   --   42             46                44       10
   --   46             50                48       11
   --   50             54                52       12
   --   54             58                56       13
   --   58             62                60       14
   --   62             80                64       15
   -----------------------------------------------------------
    clkdivider: clk_divider
       generic map 
         ( CLK_DIV => CLK_DIV) -- use clock divisor of 12 for 50MHz 
       port map               -- system clock
         ( clk_in => sys_clk,
           reset  => reset_i,
           clk_out=> clk_1MHz);

   -----------------------------------------------------------
   -- interface to serial number master    
   -----------------------------------------------------------
    ow_master_i: onewire_master
       generic map
        (  CheckCRC => CheckCRC)
       port map
        (   clk_1MHz  => clk_1MHz,
            reset     => reset_i,
            dq        => dq,
            data      => data,
--          data      => open,   -- leave it open if do not use it            
            sn_data   => sn_data, 
--          sn_data   => open,   -- leave it open if do not use it
            data_valid=> data_valid,
            crcok     => crcok);

    -----------------------------------------------------------
    -- Pullup components
    -----------------------------------------------------------
    pullupgen: if ADD_PULLUP = true generate
       pullupSNDQ  : PULLUP port map (O => dq);
    end generate pullupgen;

    
end rtl;
