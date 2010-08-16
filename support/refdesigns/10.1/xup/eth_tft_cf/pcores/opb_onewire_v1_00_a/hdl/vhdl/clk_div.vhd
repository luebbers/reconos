-------------------------------------------------------------------------------
-- Title      : A Parameterisable Clock Divider
-- Project    : 
-------------------------------------------------------------------------------
-- File       : clk_div.vhd
-- Author     : Davy Huang <Dai.Huang@Xilinx.com>
-- Company    : Xilinx, Inc.
-- Created    : 2001/02/23
-- Last Update: 2001-04-18
-- Copyright  : (c) Xilinx Inc, 2001
-------------------------------------------------------------------------------
-- Uses       : SRL16
-------------------------------------------------------------------------------
-- Used by    : 
-------------------------------------------------------------------------------
-- Description: 
--              In this top level module, two SRL16 (16-Bit Shift Register
--              Look-Up-Table) are cascaded to generate a clocks of 1MHz from
--              a system clock with much faster frequency range (3~80MHz)
--              
--              By cascading more SRL16s, this clock divider can accept even
--              higher system frequency.
--
--              Each SRL16 only uses one LUT.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001/02/23  1.0      Davy    Create the initial design
-- 2001/03/06  1.0      Davy    Change the generic to integer because FPGA
--                              Express doesn't accept std_logic_vector type on
--                              Generic.
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

entity clk_divider is
    generic ( CLK_DIV : integer range 0 to 15 := 12); 
    port (
           reset   : in  std_logic;    -- asynchronous reset
           clk_in  : in  std_logic;    -- system clock 
           clk_out : out std_logic     -- output a slow clock
              );
end clk_divider;

architecture rtl of clk_divider is

    component SRL16
     -- synopsys translate_off
      generic (    
        INIT : bit_vector );
     -- synopsys translate_on
     port (D   : in STD_ULOGIC;
        CLK    : in STD_ULOGIC;
        A0     : in STD_ULOGIC;
        A1     : in STD_ULOGIC;
        A2     : in STD_ULOGIC;
        A3     : in STD_ULOGIC;
        Q      : out STD_ULOGIC); 
     end component;
    
    -- signals for the SRL16  
    signal d : std_logic;
    signal q1, q2 : std_logic;
    
    signal clk_gen : std_logic;
    signal addr : std_logic_vector (3 downto 0);

    signal tmp  : std_logic_vector (4 downto 0);
    
begin


   -----------------------------------------------------------
   -- wiring
   -----------------------------------------------------------

    tmp <= CONV_STD_LOGIC_VECTOR(CLK_DIV,5); -- generate the address
                                             -- from the generic
    addr <= tmp (3 downto 0);

    d <= not q2;

    clk_out <= clk_gen;

   -----------------------------------------------------------
   -- Generate the slow clock, using the rising edge of output
   -- Q from the SRL16 to switch clk_slow so as to generate the
   -- clock
   -----------------------------------------------------------   
    clkgen: process(clk_in, reset)
      begin
        if reset = '1' then
          clk_gen <= '1';
        elsif clk_in'event and clk_in = '1' then
          clk_gen <= q2;
        end if;
      end process clkgen;


   -----------------------------------------------------------
   -- 16-Bit Shift Register Look-Up-Table
   -- Use A0~A3 to define the length of the shift register so
   -- as to generate the slow clock. A0~A3 is specified by
   -- the generic (CLK_DIV)
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
   --    9              14               12        2
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
   srl1: SRL16
        -- synopsys translate_off
        generic map
          ( INIT => X"0000")
        -- synopsys translate_on
        port map
          (  CLK => clk_in,
               D => d,
               Q => q1,
              A0 => addr(0),  
              A1 => addr(1),  
              A2 => addr(2),  
              A3 => addr(3));

  srl2: SRL16
        -- synopsys translate_off
        generic map
          ( INIT => X"0000")
        -- synopsys translate_on
        port map
          (  CLK => clk_in,
               D => q1,
               Q => q2,
              A0 => addr(0),  
              A1 => addr(1),  
              A2 => addr(2),  
              A3 => addr(3));
        
end rtl;
