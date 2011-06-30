
-------------------------------------------------------------------------------
--                                                                           --
--  Module      : BRAM_S8_S72.vhd        Last Update:                        --
--                                                                           --
--  Project	: Parameterizable LocalLink FIFO			     --
--                                                                           --
--  Description : BRAM Macro with Dual Port, two data widths (8 and 64)      --
--		  made for LL_FIFO.					     --
--                                                                           --
--  Designer    : Wen Ying Wei, Davy Huang                                   --
--                                                                           --
--  Company     : Xilinx, Inc.                                               --
--                                                                           --
--  Disclaimer  : THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY        --
--                WHATSOEVER and XILinX SPECifICALLY DISCLAIMS ANY           --
--                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS For         --
--                A PARTICULAR PURPOSE, or AGAinST inFRinGEMENT.             --
--                THEY ARE ONLY inTENDED TO BE USED BY XILinX                --
--                CUSTOMERS, and WITHin XILinX DEVICES.                      --
--                                                                           --
--                Copyright (c) 2003 Xilinx, Inc.                            --
--                All rights reserved                                        --
--                                                                           --
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity BRAM_S8_S72 is
    port (ADDRA  : in STD_LOGIC_VECTOR (11 downto 0);
         ADDRB  : in STD_LOGIC_VECTOR (8 downto 0);         
         DIA    : in STD_LOGIC_VECTOR (7 downto 0);
         DIB    : in STD_LOGIC_VECTOR (63 downto 0);
         DIPB	: in STD_LOGIC_VECTOR (7 downto 0);
         WEA    : in STD_LOGIC;
         WEB    : in STD_LOGIC;         
         CLKA   : in STD_LOGIC;
         CLKB   : in STD_LOGIC;
         SSRA	: in std_logic;
         SSRB	: in std_logic;         
         ENA    : in STD_LOGIC;
         ENB    : in STD_LOGIC;
         DOA    : out STD_LOGIC_VECTOR (7 downto 0);
         DOB    : out STD_LOGIC_VECTOR (63 downto 0);
         DOPB 	: out std_logic_vector(7 downto 0));
end entity BRAM_S8_S72;


architecture BRAM_S8_S72_arch of BRAM_S8_S72 is

    component RAMB16_S4_S36
        port (
        ADDRA: IN std_logic_vector(11 downto 0);
        ADDRB: IN std_logic_vector(8 downto 0);
        DIA:   IN std_logic_vector(3 downto 0);
        DIB:   IN std_logic_vector(31 downto 0);
        DIPB:  IN std_logic_vector(3 downto 0);
        WEA:   IN std_logic;
        WEB:   IN std_logic;
        CLKA:  IN std_logic;
        CLKB:  IN std_logic;
        SSRA:  IN std_logic;
        SSRB:  IN std_logic;
        ENA:   IN std_logic;
        ENB:   IN std_logic;
        DOA:   OUT std_logic_vector(3 downto 0);
        DOB:   OUT std_logic_vector(31 downto 0);
        DOPB:  OUT std_logic_vector(3 downto 0));
    END component;

    signal doa1 : std_logic_vector (3 downto 0);
    signal dob1 : std_logic_vector (31 downto 0);

    signal doa2 : std_logic_vector (3 downto 0);
    signal dob2 : std_logic_vector (31 downto 0);
    
    signal dia1 : std_logic_vector (3 downto 0);
    signal dib1 : std_logic_vector (31 downto 0);

    signal dia2 : std_logic_vector (3 downto 0);
    signal dib2 : std_logic_vector (31 downto 0);
   
begin

    dia2 <= DIA(3 downto 0);
    dia1 <= DIA(7 downto 4);
     
    dib2(3 downto 0) <= DIB(3 downto 0);
    dib1(3 downto 0) <= DIB(7 downto 4);
    dib2(7 downto 4) <= DIB(11 downto 8);
    dib1(7 downto 4) <= DIB(15 downto 12);
    
    dib2(11 downto 8) <= DIB(19 downto 16);
    dib1(11 downto 8) <= DIB(23 downto 20);
    dib2(15 downto 12) <= DIB(27 downto 24);
    dib1(15 downto 12) <= DIB(31 downto 28);
  
    dib2(19 downto 16) <= DIB(35 downto 32);
    dib1(19 downto 16) <= DIB(39 downto 36);
    dib2(23 downto 20) <= DIB(43 downto 40);
    dib1(23 downto 20) <= DIB(47 downto 44);
    
    dib2(27 downto 24) <= DIB(51 downto 48);
    dib1(27 downto 24) <= DIB(55 downto 52);
    dib2(31 downto 28) <= DIB(59 downto 56);
    dib1(31 downto 28) <= DIB(63 downto 60);
     
    DOA(3 downto 0) <= doa2;
    DOA(7 downto 4) <= doa1;
                                
    DOB(3 downto 0) <= dob2(3 downto 0);
    DOB(7 downto 4) <= dob1(3 downto 0);
    DOB(11 downto 8) <= dob2(7 downto 4);
    DOB(15 downto 12) <= dob1(7 downto 4);
    
    DOB(19 downto 16) <= dob2(11 downto 8);
    DOB(23 downto 20) <= dob1(11 downto 8);
    DOB(27 downto 24) <= dob2(15 downto 12);
    DOB(31 downto 28) <= dob1(15 downto 12);
    
    DOB(35 downto 32) <= dob2(19 downto 16);
    DOB(39 downto 36) <= dob1(19 downto 16);
    DOB(43 downto 40) <= dob2(23 downto 20);
    DOB(47 downto 44) <= dob1(23 downto 20);
    
    DOB(51 downto 48) <= dob2(27 downto 24);
    DOB(55 downto 52) <= dob1(27 downto 24);
    DOB(59 downto 56) <= dob2(31 downto 28);
    DOB(63 downto 60) <= dob1(31 downto 28);
        
    bram1: RAMB16_S4_S36
        port map (
            ADDRA => addra(11 downto 0),
            ADDRB => addrb(8 downto 0),
            DIA => dia1,
            DIB => dib1,
            DIPB => dipb(3 downto 0),
            WEA => wea,
            WEB => web,
            CLKA => clka,
            CLKB => clkb,
            SSRA => ssra,
            SSRB => ssrb,
            ENA => ena,
            ENB => enb,
            DOA => doa1,
            DOB => dob1,
            DOPB => dopb(3 downto 0));

    bram2: RAMB16_S4_S36
        port map (
            ADDRA => addra(11 downto 0),
            ADDRB => addrb(8 downto 0),
            DIA => dia2,
            DIB => dib2,
            DIPB => dipb(7 downto 4),
            WEA => wea,
            WEB => web,
            CLKA => clka,
            CLKB => clkb,
            SSRA => ssra,
            SSRB => ssrb,
            ENA => ena,
            ENB => enb,
            DOA => doa2,
            DOB => dob2,
            DOPB => dopb(7 downto 4));

end BRAM_S8_S72_arch;
