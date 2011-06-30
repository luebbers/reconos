---------------------------------------------------------------------
--
--    File Name:  TESTER_pkg.vhd
--      Project:  LL FIFO
--      Version:  1.2
--         Date:  2005-06-29
--
--      Company:  Xilinx, Inc.
-- Contributors:  Wen Ying Wei, Davy Huang
--
--   Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
--                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
--                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
--                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
--                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
--                APPLICATION OR STANDARD, XILINX IS MAKING NO
--                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
--                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
--                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
--                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
--                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
--                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
--                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
--                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
--                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
--                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
--                PURPOSE.
--                
--                (c) Copyright 2005 Xilinx, Inc.
--                All rights reserved.
--
---------------------------------------------------------------------
--
-- Tester Package
-- Author: Davy Huang
--
-- Description: 
-- This package file is created for mixed language simulation
-- using Aurora tester for LL FIFO.
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


package TESTER_pkg is

   component OUTPUT_TESTER IS
   GENERIC (
      -- Parameter Declarations ********************************************
      GLOBALDLY                      :  integer := 1;    
      LL_DAT_BIT_WIDTH               :  integer := 16;    
      LL_REM_BIT_WIDTH               :  integer := 1;
      FIFO_DEPTH                     :  integer := 256);
   PORT (
      CLK                     : IN std_logic;   
      RST                     : IN std_logic;   
      RX_D                    : IN std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
      RX_REM                  : IN std_logic_vector(0 TO LL_REM_BIT_WIDTH - 1);   
      RX_SOF_N                : IN std_logic;   
      RX_EOF_N                : IN std_logic;   
      RX_SRC_RDY_N            : IN std_logic;   
      UFC_RX_DATA             : IN std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
      UFC_RX_REM              : IN std_logic_vector(0 TO LL_REM_BIT_WIDTH - 1);   
      UFC_RX_SOF_N            : IN std_logic;   
      UFC_RX_EOF_N            : IN std_logic;   
      UFC_RX_SRC_RDY_N        : IN std_logic;   
      RX_SOF_N_REF            : IN std_logic;   
      RX_EOF_N_REF            : IN std_logic;   
      RX_REM_REF              : IN std_logic_vector(0 TO LL_REM_BIT_WIDTH - 1);   
      RX_DATA_REF             : IN std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
      RX_SRC_RDY_N_REF        : IN std_logic;   
      UFC_RX_DATA_REF         : IN std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
      UFC_RX_REM_REF          : IN std_logic_vector(0 TO LL_REM_BIT_WIDTH - 1);   
      UFC_RX_SOF_N_REF        : IN std_logic;   
      UFC_RX_EOF_N_REF        : IN std_logic;   
      UFC_RX_SRC_RDY_N_REF    : IN std_logic;   
      WORKING                 : OUT std_logic;   
      COMPARING               : OUT std_logic; 
      OVERFLOW                : OUT std_logic; 
      RESULT_GOOD             : OUT std_logic;   
      RESULT_GOOD_PDU         : OUT std_logic;   
      RESULT_GOOD_UFC         : OUT std_logic);   
  END COMPONENT;
  
   component OUTPUT_TESTER_8_BIT IS
   GENERIC (
      -- Parameter Declarations ********************************************
      GLOBALDLY                      :  integer := 1;    
      LL_DAT_BIT_WIDTH               :  integer := 8;    
      LL_REM_BIT_WIDTH               :  integer := 0;
      FIFO_DEPTH                     :  integer := 256);
   PORT (
      CLK                     : IN std_logic;   
      RST                     : IN std_logic;   
      RX_D                    : IN std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
      RX_REM                  : IN std_logic;   
      RX_SOF_N                : IN std_logic;   
      RX_EOF_N                : IN std_logic;   
      RX_SRC_RDY_N            : IN std_logic;   
      UFC_RX_DATA             : IN std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
      UFC_RX_REM              : IN std_logic;   
      UFC_RX_SOF_N            : IN std_logic;   
      UFC_RX_EOF_N            : IN std_logic;   
      UFC_RX_SRC_RDY_N        : IN std_logic;   
      RX_SOF_N_REF            : IN std_logic;   
      RX_EOF_N_REF            : IN std_logic;   
      RX_REM_REF              : IN std_logic;   
      RX_DATA_REF             : IN std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
      RX_SRC_RDY_N_REF        : IN std_logic;   
      UFC_RX_DATA_REF         : IN std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
      UFC_RX_REM_REF          : IN std_logic;   
      UFC_RX_SOF_N_REF        : IN std_logic;   
      UFC_RX_EOF_N_REF        : IN std_logic;   
      UFC_RX_SRC_RDY_N_REF    : IN std_logic;   
      WORKING                 : OUT std_logic;   
      COMPARING               : OUT std_logic;
      OVERFLOW                : OUT std_logic; 
      RESULT_GOOD             : OUT std_logic;   
      RESULT_GOOD_PDU         : OUT std_logic;   
      RESULT_GOOD_UFC         : OUT std_logic);   
  END COMPONENT;

  COMPONENT FILEREAD_TESTER IS
     GENERIC (
        -- Parameter Declarations ********************************************
        GLOBALDLY                      :  integer := 1;    
        TV_WIDTH                       :  integer := 8;    
        CV_WIDTH                       :  integer := 4;
        LL_DAT_BIT_WIDTH               :  integer := 16;    
        LL_REM_BIT_WIDTH               :  integer := 1;
        REM_VECTOR_WIDTH               :  integer := 3);
     PORT (
        CLK                     : IN std_logic;   
        TV                      : IN std_logic_vector(0 TO TV_WIDTH - 1);   
        TX_SOF_N                : OUT std_logic;   
        TX_EOF_N                : OUT std_logic;   
        TX_D                    : OUT std_logic_vector(0 TO LL_DAT_BIT_WIDTH - 1);   
        TX_REM                  : OUT std_logic_vector(0 TO LL_REM_BIT_WIDTH - 1);   
        TX_SRC_RDY_N            : OUT std_logic;   
        NFC_NB                  : OUT std_logic_vector(0 TO 3);   
        NFC_REQ_N               : OUT std_logic;   
        UFC_TX_REQ_N            : OUT std_logic;   
        UFC_TX_MS               : OUT std_logic_vector(0 TO 3);   
        CTRL                    : OUT std_logic_vector(0 TO CV_WIDTH -1));   
  END COMPONENT;


end TESTER_pkg;

------------------------------------------------------------------------
-- History:
--   DH        8/22/03 -- Initial design 
------------------------------------------------------------------------
-- $Revision: 1.2 $
-- $Date: 2004/12/27 18:12:18 $

