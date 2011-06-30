
-------------------------------------------------------------------------------
--                                                                           --
--  Module      : BRAM_S72_S144.vhd        Last Update:                      --
--                                                                           --
--  Project	: Parameterizable LocalLink FIFO			     --
--                                                                           --
--  Description : BRAM Macro with Dual Port, two data widths (72 and 128)    --
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

entity BRAM_S72_S144 is
    port (ADDRA  : in std_logic_vector (9 downto 0);
        ADDRB  : in std_logic_vector (8 downto 0);         
        DIA    : in std_logic_vector (63 downto 0);
        DIPA	: in std_logic_vector (7 downto 0);
        DIB    : in std_logic_vector (127 downto 0);
        DIPB	: in std_logic_vector (15 downto 0);
        WEA    : in std_logic;
        WEB    : in std_logic;         
        CLKA   : in std_logic;
        CLKB   : in std_logic;
        SSRA	: in std_logic;
        SSRB	: in std_logic;         
        ENA    : in std_logic;
        ENB    : in std_logic;
        DOA    : out std_logic_vector (63 downto 0);
        DOPA	: out std_logic_vector (7 downto 0);
        DOB    : out std_logic_vector (127 downto 0);
        DOPB 	: out std_logic_vector(15 downto 0));
end entity BRAM_S72_S144;


architecture BRAM_S72_S144_arch of BRAM_S72_S144 is

component BRAM_S36_S72
    port (ADDRA  : in std_logic_vector (9 downto 0);
        ADDRB  : in std_logic_vector (8 downto 0);         
        DIA    : in std_logic_vector (31 downto 0);
        DIPA	: in std_logic_vector (3 downto 0);
        DIB    : in std_logic_vector (63 downto 0);
        DIPB	: in std_logic_vector (7 downto 0);
        WEA    : in std_logic;
        WEB    : in std_logic;         
        CLKA   : in std_logic;
        CLKB   : in std_logic;
        SSRA	: in std_logic;
        SSRB	: in std_logic;         
        ENA    : in std_logic;
        ENB    : in std_logic;
        DOA    : out std_logic_vector (31 downto 0);
        DOPA	: out std_logic_vector (3 downto 0);
        DOB    : out std_logic_vector (63 downto 0);
        DOPB 	: out std_logic_vector(7 downto 0));
end component;


    signal doa1 : std_logic_vector (31 downto 0);
    signal dob1 : std_logic_vector (63 downto 0);

    signal doa2 : std_logic_vector (31 downto 0);
    signal dob2 : std_logic_vector (63 downto 0);
    
    signal dia1 : std_logic_vector (31 downto 0);
    signal dib1 : std_logic_vector (63 downto 0);

    signal dia2 : std_logic_vector (31 downto 0);
    signal dib2 : std_logic_vector (63 downto 0);
    
    signal dipa1: std_logic_vector (3 downto 0);
    signal dipa2: std_logic_vector (3 downto 0);
    signal dopa1: std_logic_vector (3 downto 0);
    signal dopa2: std_logic_vector (3 downto 0);
     
    signal dipb1: std_logic_vector (7 downto 0);
    signal dipb2: std_logic_vector (7 downto 0);
    signal dopb1: std_logic_vector (7 downto 0);
    signal dopb2: std_logic_vector (7 downto 0);
   
begin
    dia1(31 downto 0) <= DIA(31 downto 0);
    dia2(31 downto 0) <= DIA(63 downto 32);
    
    dipa1(3 downto 0) <= DIPA(3 downto 0);
    dipa2(3 downto 0) <= DIPA(7 downto 4);

    DOA(31 downto 0) <= doa1;
    DOA(63 downto 32) <= doa2;
    
    DOPA(3 downto 0) <= dopa1;
    DOPA(7 downto 4) <= dopa2;

    dib1(31 downto 0) <= DIB(31 downto 0);
    dib2(31 downto 0) <= DIB(63 downto 32);
    dib1(63 downto 32) <= DIB(95 downto 64);
    dib2(63 downto 32) <= DIB(127 downto 96);
      
    dipb1(3 downto 0) <= DIPB(3 downto 0);
    dipb2(3 downto 0) <= DIPB(7 downto 4);
    dipb1(7 downto 4) <= DIPB(11 downto 8);
    dipb2(7 downto 4) <= DIPB(15 downto 12);
       
    DOPB(3 downto 0) <= dopb1(3 downto 0);
    DOPB(7 downto 4) <= dopb2(3 downto 0);
    DOPB(11 downto 8) <= dopb1(7 downto 4);
    DOPB(15 downto 12) <= dopb2(7 downto 4);
                                  
    DOB(31 downto 0) <= dob1(31 downto 0);
    DOB(63 downto 32) <= dob2(31 downto 0);
    DOB(95 downto 64) <= dob1(63 downto 32);
    DOB(127 downto 96) <= dob2(63 downto 32);
    
       
    bram1: BRAM_S36_S72
        port map (
            ADDRA => addra(9 downto 0),
            ADDRB => addrb(8 downto 0),
            DIA => dia1,
            DIPA => dipa1,
            DIB => dib1,
            DIPB => dipb1,
            WEA => wea,
            WEB => web,
            CLKA => clka,
            CLKB => clkb,
            SSRA => ssra,
            SSRB => ssrb,
            ENA => ena,
            ENB => enb,
            DOA => doa1,
            DOPA => dopa1,
            DOB => dob1,
            DOPB => dopb1);

    bram2: BRAM_S36_S72
        port map (
            ADDRA => addra(9 downto 0),
            ADDRB => addrb(8 downto 0),
            DIA => dia2,
            DIPA => dipa2,
            DIB => dib2,
            DIPB => dipb2,
            WEA => wea,
            WEB => web,
            CLKA => clka,
            CLKB => clkb,
            SSRA => ssra,
            SSRB => ssrb,
            ENA => ena,
            ENB => enb,
            DOA => doa2,
            DOPA => dopa2,
            DOB => dob2,
            DOPB => dopb2);

end BRAM_S72_S144_arch;
