
-------------------------------------------------------------------------------
--                                                                           --
--  Module      : BRAM_S8_S144.vhd        Last Update:                       --
--                                                                           --
--  Project	: Parameterizable LocalLink FIFO			     --
--                                                                           --
--  Description : BRAM Macro with Dual Port, two data widths (8 and 128)     --
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

entity BRAM_S8_S144 is
    port (ADDRA  : in STD_LOGIC_VECTOR (12 downto 0);
         ADDRB  : in STD_LOGIC_VECTOR (8 downto 0);         
         DIA    : in STD_LOGIC_VECTOR (7 downto 0);
         DIB    : in STD_LOGIC_VECTOR (127 downto 0);
         DIPB	: in STD_LOGIC_VECTOR (15 downto 0);
         WEA    : in STD_LOGIC;
         WEB    : in STD_LOGIC;         
         CLKA   : in STD_LOGIC;
         CLKB   : in STD_LOGIC;
         SSRA	: in std_logic;
         SSRB	: in std_logic;         
         ENA    : in STD_LOGIC;
         ENB    : in STD_LOGIC;
         DOA    : out STD_LOGIC_VECTOR (7 downto 0);
         DOB    : out STD_LOGIC_VECTOR (127 downto 0);
         DOPB 	: out std_logic_vector(15 downto 0));
end entity BRAM_S8_S144;


architecture BRAM_S8_S144_arch of BRAM_S8_S144 is

    component RAMB16_S2_S36
        port (
            ADDRA: IN std_logic_vector(12 downto 0);
            ADDRB: IN std_logic_vector(8 downto 0);
            DIA:   IN std_logic_vector(1 downto 0);
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
            DOA:   OUT std_logic_vector(1 downto 0);
            DOB:   OUT std_logic_vector(31 downto 0);
            DOPB:  OUT std_logic_vector(3 downto 0));
   END component;

   signal doa1 : std_logic_vector (1 downto 0);
   signal dob1 : std_logic_vector (31 downto 0);

   signal doa2 : std_logic_vector (1 downto 0);
   signal dob2 : std_logic_vector (31 downto 0);
   
   signal doa3 : std_logic_vector (1 downto 0);
   signal dob3 : std_logic_vector (31 downto 0);

   signal doa4 : std_logic_vector (1 downto 0);
   signal dob4 : std_logic_vector (31 downto 0);
  
   signal dia1 : std_logic_vector (1 downto 0);
   signal dib1 : std_logic_vector (31 downto 0);

   signal dia2 : std_logic_vector (1 downto 0);
   signal dib2 : std_logic_vector (31 downto 0);
   
   signal dia3 : std_logic_vector (1 downto 0);
   signal dib3 : std_logic_vector (31 downto 0);

   signal dia4 : std_logic_vector (1 downto 0);
   signal dib4 : std_logic_vector (31 downto 0);
   
begin
   
    dib1(1 downto 0) <= DIB(1 downto 0);
    dib2(1 downto 0) <= DIB(3 downto 2);
    dib3(1 downto 0) <= DIB(5 downto 4);
    dib4(1 downto 0) <= DIB(7 downto 6);

    dib1(3 downto 2) <= DIB(9 downto 8);
    dib2(3 downto 2) <= DIB(11 downto 10);
    dib3(3 downto 2) <= DIB(13 downto 12);
    dib4(3 downto 2) <= DIB(15 downto 14);
     
    dib1(5 downto 4) <= DIB(17 downto 16);
    dib2(5 downto 4) <= DIB(19 downto 18);
    dib3(5 downto 4) <= DIB(21 downto 20);
    dib4(5 downto 4) <= DIB(23 downto 22);
    
    dib1(7 downto 6) <= DIB(25 downto 24);
    dib2(7 downto 6) <= DIB(27 downto 26);
    dib3(7 downto 6) <= DIB(29 downto 28);
    dib4(7 downto 6) <= DIB(31 downto 30);
    
    dib1(9 downto 8) <= DIB(33 downto 32);
    dib2(9 downto 8) <= DIB(35 downto 34);
    dib3(9 downto 8) <= DIB(37 downto 36);
    dib4(9 downto 8) <= DIB(39 downto 38);
    
    dib1(11 downto 10) <= DIB(41 downto 40);
    dib2(11 downto 10) <= DIB(43 downto 42);
    dib3(11 downto 10) <= DIB(45 downto 44);
    dib4(11 downto 10) <= DIB(47 downto 46);
    
    dib1(13 downto 12) <= DIB(49 downto 48);
    dib2(13 downto 12) <= DIB(51 downto 50);
    dib3(13 downto 12) <= DIB(53 downto 52);
    dib4(13 downto 12) <= DIB(55 downto 54);

    dib1(15 downto 14) <= DIB(57 downto 56);
    dib2(15 downto 14) <= DIB(59 downto 58);
    dib3(15 downto 14) <= DIB(61 downto 60);
    dib4(15 downto 14) <= DIB(63 downto 62);

    dib1(17 downto 16) <= DIB(65 downto 64);
    dib2(17 downto 16) <= DIB(67 downto 66);
    dib3(17 downto 16) <= DIB(69 downto 68);
    dib4(17 downto 16) <= DIB(71 downto 70);

    dib1(19 downto 18) <= DIB(73 downto 72);
    dib2(19 downto 18) <= DIB(75 downto 74);
    dib3(19 downto 18) <= DIB(77 downto 76);
    dib4(19 downto 18) <= DIB(79 downto 78);

    dib1(21 downto 20) <= DIB(81 downto 80);
    dib2(21 downto 20) <= DIB(83 downto 82);
    dib3(21 downto 20) <= DIB(85 downto 84);
    dib4(21 downto 20) <= DIB(87 downto 86);

    dib1(23 downto 22) <= DIB(89 downto 88);
    dib2(23 downto 22) <= DIB(91 downto 90);
    dib3(23 downto 22) <= DIB(93 downto 92);
    dib4(23 downto 22) <= DIB(95 downto 94);
    
    dib1(25 downto 24) <= DIB(97 downto 96);
    dib2(25 downto 24) <= DIB(99 downto 98);
    dib3(25 downto 24) <= DIB(101 downto 100);
    dib4(25 downto 24) <= DIB(103 downto 102);
    
    dib1(27 downto 26) <= DIB(105 downto 104);
    dib2(27 downto 26) <= DIB(107 downto 106);
    dib3(27 downto 26) <= DIB(109 downto 108);
    dib4(27 downto 26) <= DIB(111 downto 110);
    
    dib1(29 downto 28) <= DIB(113 downto 112);
    dib2(29 downto 28) <= DIB(115 downto 114);
    dib3(29 downto 28) <= DIB(117 downto 116);
    dib4(29 downto 28) <= DIB(119 downto 118);

    dib1(31 downto 30) <= DIB(121 downto 120);
    dib2(31 downto 30) <= DIB(123 downto 122);
    dib3(31 downto 30) <= DIB(125 downto 124);
    dib4(31 downto 30) <= DIB(127 downto 126);
-------------------------------------------                                  
    DOB(1 downto 0) <= dob1(1 downto 0);
    DOB(3 downto 2) <= dob2(1 downto 0);
    DOB(5 downto 4) <= dob3(1 downto 0);
    DOB(7 downto 6) <= dob4(1 downto 0);
    
    DOB(9 downto 8) <= dob1(3 downto 2);
    DOB(11 downto 10) <= dob2(3 downto 2);
    DOB(13 downto 12) <= dob3(3 downto 2);
    DOB(15 downto 14) <= dob4(3 downto 2);
    
    DOB(17 downto 16) <= dob1(5 downto 4);
    DOB(19 downto 18) <= dob2(5 downto 4);
    DOB(21 downto 20) <= dob3(5 downto 4);
    DOB(23 downto 22) <= dob4(5 downto 4);

    DOB(25 downto 24) <= dob1(7 downto 6);
    DOB(27 downto 26) <= dob2(7 downto 6);
    DOB(29 downto 28) <= dob3(7 downto 6);
    DOB(31 downto 30) <= dob4(7 downto 6);
    
    DOB(33 downto 32) <= dob1(9 downto 8);
    DOB(35 downto 34) <= dob2(9 downto 8);
    DOB(37 downto 36) <= dob3(9 downto 8);
    DOB(39 downto 38) <= dob4(9 downto 8);
    
    DOB(41 downto 40) <= dob1(11 downto 10);
    DOB(43 downto 42) <= dob2(11 downto 10);
    DOB(45 downto 44) <= dob3(11 downto 10);
    DOB(47 downto 46) <= dob4(11 downto 10);
    
    DOB(49 downto 48) <= dob1(13 downto 12);
    DOB(51 downto 50) <= dob2(13 downto 12);
    DOB(53 downto 52) <= dob3(13 downto 12);
    DOB(55 downto 54) <= dob4(13 downto 12);
    
    DOB(57 downto 56) <= dob1(15 downto 14);
    DOB(59 downto 58) <= dob2(15 downto 14);
    DOB(61 downto 60) <= dob3(15 downto 14);
    DOB(63 downto 62) <= dob4(15 downto 14);

    --------------------------------------------
    
    DOB(65 downto 64) <= dob1(17 downto 16);
    DOB(67 downto 66) <= dob2(17 downto 16);
    DOB(69 downto 68) <= dob3(17 downto 16);
    DOB(71 downto 70) <= dob4(17 downto 16);

    DOB(73 downto 72) <= dob1(19 downto 18);
    DOB(75 downto 74) <= dob2(19 downto 18);
    DOB(77 downto 76) <= dob3(19 downto 18);
    DOB(79 downto 78) <= dob4(19 downto 18);

    DOB(81 downto 80) <= dob1(21 downto 20);
    DOB(83 downto 82) <= dob2(21 downto 20);
    DOB(85 downto 84) <= dob3(21 downto 20);
    DOB(87 downto 86) <= dob4(21 downto 20);
    
    DOB(89 downto 88) <= dob1(23 downto 22);
    DOB(91 downto 90) <= dob2(23 downto 22);
    DOB(93 downto 92) <= dob3(23 downto 22);
    DOB(95 downto 94) <= dob4(23 downto 22);
      
    DOB(97 downto 96) <= dob1(25 downto 24);
    DOB(99 downto 98) <= dob2(25 downto 24);
    DOB(101 downto 100) <= dob3(25 downto 24);
    DOB(103 downto 102) <= dob4(25 downto 24);

    DOB(105 downto 104) <= dob1(27 downto 26);
    DOB(107 downto 106) <= dob2(27 downto 26);
    DOB(109 downto 108) <= dob3(27 downto 26);
    DOB(111 downto 110) <= dob4(27 downto 26);
    
    DOB(113 downto 112) <= dob1(29 downto 28);
    DOB(115 downto 114) <= dob2(29 downto 28);
    DOB(117 downto 116) <= dob3(29 downto 28);
    DOB(119 downto 118) <= dob4(29 downto 28);

    DOB(121 downto 120) <= dob1(31 downto 30);
    DOB(123 downto 122) <= dob2(31 downto 30);
    DOB(125 downto 124) <= dob3(31 downto 30);
    DOB(127 downto 126) <= dob4(31 downto 30);

    dia1 <= DIA(1 downto 0);
    dia2 <= DIA(3 downto 2);
    dia3 <= DIA(5 downto 4);
    dia4 <= DIA(7 downto 6);
     
    DOA(1 downto 0) <= doa1;
    DOA(3 downto 2) <= doa2;
    DOA(5 downto 4) <= doa3;
    DOA(7 downto 6) <= doa4;
                                       
    bram1: RAMB16_S2_S36
        port map (
            ADDRA => addra(12 downto 0),
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

    bram2: RAMB16_S2_S36
        port map (
            ADDRA => addra(12 downto 0),
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

    bram3: RAMB16_S2_S36
        port map (
            ADDRA => addra(12 downto 0),
            ADDRB => addrb(8 downto 0),
            DIA => dia3,
            DIB => dib3,
            DIPB => dipb(11 downto 8),
            WEA => wea,
            WEB => web,
            CLKA => clka,
            CLKB => clkb,
            SSRA => ssra,
            SSRB => ssrb,
            ENA => ena,
            ENB => enb,
            DOA => doa3,
            DOB => dob3,
            DOPB => dopb(11 downto 8));
            
    bram4: RAMB16_S2_S36
        port map (
            ADDRA => addra(12 downto 0),
            ADDRB => addrb(8 downto 0),
            DIA => dia4,
            DIB => dib4,
            DIPB => dipb(15 downto 12),
            WEA => wea,
            WEB => web,
            CLKA => clka,
            CLKB => clkb,
            SSRA => ssra,
            SSRB => ssrb,
            ENA => ena,
            ENB => enb,
            DOA => doa4,
            DOB => dob4,
            DOPB => dopb(15 downto 12));
end BRAM_S8_S144_arch;
