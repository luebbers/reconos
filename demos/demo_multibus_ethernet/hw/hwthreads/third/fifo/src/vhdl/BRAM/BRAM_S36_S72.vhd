
---------------------------------------------------------------------------
--                                                                       --
--  Module      : BRAM_S36_S72.vhd        Last Update:                   --
--                                                                       --
--  Project	: Parameterizable LocalLink FIFO			 --
--                                                                       --
--  Description : BRAM Macro with Dual Port, two data widths (32 and     --
--		  72) made for LL_FIFO.				 	 --
--                                                                       --
--  Designer    : Wen Ying Wei, Davy Huang                               --
--                                                                       --
--  Company     : Xilinx, Inc.                                           --
--                                                                       --
--  Disclaimer  : THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY    --
--                WHATSOEVER and XILinX SPECifICALLY DISCLAIMS ANY       --
--                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS For     --
--                A PARTICULAR PURPOSE, or AGAinST inFRinGEMENT.         --
--                THEY ARE ONLY inTENDED TO BE USED BY XILinX            --
--                CUSTOMERS, and WITHin XILinX DEVICES.                  --
--                                                                       --
--                Copyright (c) 2003 Xilinx, Inc.                        --
--                All rights reserved                                    --
--                                                                       --
---------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity BRAM_S36_S72 is
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
end entity BRAM_S36_S72;


architecture BRAM_S36_S72_arch of BRAM_S36_S72 is

    component RAMB16_S18_S36
        port (
            ADDRA: in std_logic_vector(9 downto 0);
            ADDRB: in std_logic_vector(8 downto 0);
            DIA:   in std_logic_vector(15 downto 0);
            DIPA:  in std_logic_vector(1 downto 0);
            DIB:   in std_logic_vector(31 downto 0);
            DIPB:  in std_logic_vector(3 downto 0);
            WEA:   in std_logic;
            WEB:   in std_logic;
            CLKA:  in std_logic;
            CLKB:  in std_logic;
            SSRA:  in std_logic;
            SSRB:  in std_logic;
            ENA:   in std_logic;
            ENB:   in std_logic;
            DOA:   OUT std_logic_vector(15 downto 0);
            DOPA:  OUT std_logic_vector(1 downto 0);
            DOB:   OUT std_logic_vector(31 downto 0);
            DOPB:  OUT std_logic_vector(3 downto 0));
    END component;

    signal doa1 : std_logic_vector (15 downto 0);
    signal dob1 : std_logic_vector (31 downto 0);

    signal doa2 : std_logic_vector (15 downto 0);
    signal dob2 : std_logic_vector (31 downto 0);
    
    signal dia1 : std_logic_vector (15 downto 0);
    signal dib1 : std_logic_vector (31 downto 0);

    signal dia2 : std_logic_vector (15 downto 0);
    signal dib2 : std_logic_vector (31 downto 0);
    
    signal dipa1: std_logic_vector (1 downto 0);
    signal dipa2: std_logic_vector (1 downto 0);
    signal dopa1: std_logic_vector (1 downto 0);
    signal dopa2: std_logic_vector (1 downto 0);
     
    signal dipb1: std_logic_vector (3 downto 0);
    signal dipb2: std_logic_vector (3 downto 0);
    signal dopb1: std_logic_vector (3 downto 0);
    signal dopb2: std_logic_vector (3 downto 0);
    
begin
    dia1(15 downto 0) <= DIA(15 downto 0);
    dia2(15 downto 0) <= DIA(31 downto 16);
    
    dib1(15 downto 0) <= DIB(15 downto 0);
    dib2(15 downto 0) <= DIB(31 downto 16);
    dib1(31 downto 16) <= DIB(47 downto 32);
    dib2(31 downto 16) <= DIB(63 downto 48);
    
    dipa1(1 downto 0) <= DIPA(1 downto 0);
    dipa2(1 downto 0) <= DIPA(3 downto 2);
    
    dipb1(1 downto 0) <= DIPB(1 downto 0);
    dipb2(1 downto 0) <= DIPB(3 downto 2);
    dipb1(3 downto 2) <= DIPB(5 downto 4);
    dipb2(3 downto 2) <= DIPB(7 downto 6);
    
    DOA(15 downto 0) <= doa1;
    DOA(31 downto 16) <= doa2;
    
    DOPA(1 downto 0) <= dopa1;
    DOPA(3 downto 2) <= dopa2;
    
    DOPB(1 downto 0) <= dopb1(1 downto 0);
    DOPB(3 downto 2) <= dopb2(1 downto 0);
    DOPB(5 downto 4) <= dopb1(3 downto 2);
    DOPB(7 downto 6) <= dopb2(3 downto 2);
                                  
    DOB(15 downto 0) <= dob1(15 downto 0);
    DOB(31 downto 16) <= dob2(15 downto 0);
    DOB(47 downto 32) <= dob1(31 downto 16);
    DOB(63 downto 48) <= dob2(31 downto 16);
    
       
    bram1: RAMB16_S18_S36
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

    bram2: RAMB16_S18_S36
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

end BRAM_S36_S72_arch;
