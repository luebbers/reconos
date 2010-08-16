-------------------------------------------------------------------------------
-- $Id: TESTBENCH_ac97_package.vhd,v 1.1 2005/02/17 20:29:34 crh Exp $
-------------------------------------------------------------------------------
-- TESTBENCH_ac97_package.vhd
-------------------------------------------------------------------------------
--
--                  ****************************
--                  ** Copyright Xilinx, Inc. **
--                  ** All rights reserved.   **
--                  ****************************
--
-------------------------------------------------------------------------------
-- Filename:        TESTBENCH_ac97_package.vhd
--
-- Description:     Testbench utitlities for AC97
-- 
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
-- Revision:        $Revision: 1.1 $
-- Date:            $Date: 2005/02/17 20:29:34 $
--
-- History:
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;


package testbench_ac97_package is
  procedure write_opb (signal OPB_Clk : in std_logic;
                      signal xferAck : in std_logic;
                      constant address : in std_logic_vector(0 to 31);
                      constant data : in std_logic_vector(0 to 31);
                      signal OPB_select : out std_logic;
                      signal OPB_RNW : out std_logic;
                      signal OPB_ABus : out std_logic_vector(0 to 31);
                      signal OPB_DBus : out std_logic_vector(0 to 31)
                       );
  procedure read_opb (signal OPB_Clk : in std_logic;
                      signal xferAck : in std_logic;
                      constant address : in std_logic_vector(0 to 31);
                      signal OPB_select : out std_logic;
                       signal OPB_RNW : out std_logic;
                       signal OPB_ABus : out std_logic_vector(0 to 31);
                       signal OPB_DBus : out std_logic_vector(0 to 31)
                       );
  procedure send_frame (signal clk : in std_logic;
                        variable slot0 : in std_logic_vector(15 downto 0);
                        variable slot1 : in std_logic_vector(19 downto 0);
                        variable slot2 : in std_logic_vector(19 downto 0);
                        variable slot3 : in std_logic_vector(19 downto 0);
                        variable slot4 : in std_logic_vector(19 downto 0);
                        variable slot5 : in std_logic_vector(19 downto 0);
                        variable slot6 : in std_logic_vector(19 downto 0);
                        variable slot7 : in std_logic_vector(19 downto 0);
                        variable slot8 : in std_logic_vector(19 downto 0);
                        variable slot9 : in std_logic_vector(19 downto 0);
                        variable slot10 : in std_logic_vector(19 downto 0);
                        variable slot11 : in std_logic_vector(19 downto 0);
                        variable slot12 : in std_logic_vector(19 downto 0);
                        signal SData_In : out std_logic);
  procedure send_basic_frame (signal clk : in std_logic;
                        variable slot0 : in std_logic_vector(15 downto 0);
                        variable slot1 : in std_logic_vector(19 downto 0);
                        variable slot2 : in std_logic_vector(19 downto 0);
                        variable slot3 : in std_logic_vector(19 downto 0);
                        variable slot4 : in std_logic_vector(19 downto 0);
                        signal SData_In : out std_logic);
  procedure read_ip (signal Bus2IP_Clk : in std_logic;
                     signal IP2bus_Data : in std_logic_vector(0 to 31);
                     constant address : in std_logic_vector(0 to 31);
                     signal Bus2IP_CS : out std_logic;
                     signal Bus2IP_Addr : out std_logic_vector(0 to 31);
                     signal Bus2IP_RdCE : out std_logic;
                     signal IP_READ : out std_logic_vector(0 to 31)
                     );
  procedure write_ip (signal Bus2IP_Clk : in std_logic;
                      constant address : in std_logic_vector(0 to 31);
                      constant data : in std_logic_vector(0 to 31);
                      signal Bus2IP_CS : out std_logic;
                      signal Bus2IP_Addr : out std_logic_vector(0 to 31);
                      signal Bus2IP_Data : out std_logic_vector(0 to 31);
                      signal Bus2IP_WrCE : out std_logic
                     );
  procedure delay(signal sig : in std_logic; constant cycles : in integer);
  
  constant BIT_CLK_HALF_PERIOD : time := 40.69 ns;
  constant FIFO_CTRL_OFFSET : std_logic_vector(0 to 31) := X"00000004";
  constant STATUS_OFFSET : std_logic_vector(0 to 31) := X"00000004";
  constant IN_FIFO_OFFSET : std_logic_vector(0 to 31) := X"00000000";
  constant OUT_FIFO_OFFSET : std_logic_vector(0 to 31) := X"00000000";
  constant REG_ADDR_OFFSET : std_logic_vector(0 to 31) := X"0000000C";
  constant REG_DATA_OFFSET : std_logic_vector(0 to 31) := X"00000008";
  constant REG_DATA_WRITE_OFFSET : std_logic_vector(0 to 31) := X"00000008";

  constant FIFO_CLEAR_MASK : std_logic_vector(0 to 31) := X"00000003";
  constant ENABLE_PLAY_INT_MASK : std_logic_vector(0 to 31) := X"00000004";
  
end testbench_ac97_package;

package body testbench_ac97_package is

  procedure delay(signal sig : in std_logic; constant cycles : in integer) is
  begin
    for i in cycles-1 downto 0 loop
      wait until sig'event and sig='1';
    end loop;
  end delay;

  procedure write_opb(signal OPB_Clk : in std_logic;
                      signal xferAck : in std_logic;
                      constant address : in std_logic_vector(0 to 31);
                      constant data : in std_logic_vector(0 to 31);
                      signal OPB_select : out std_logic;
                      signal OPB_RNW : out std_logic;
                      signal OPB_ABus : out std_logic_vector(0 to 31);
                      signal OPB_DBus : out std_logic_vector(0 to 31)
                       ) is
  begin
    wait until opb_clk'event and opb_clk='0';
    OPB_select <= '1';
    OPB_ABus <= address;
    OPB_DBus <= data;
    OPB_RNW <= '0';
    wait until opb_clk'event and opb_clk='1' and xferAck='1';
    OPB_select <= '0';
    OPB_ABus <= X"0000_0000";
    OPB_DBus <= X"0000_0000";
    for i in 15 downto 0 loop
      wait until opb_clk'event and opb_clk='0';
    end loop;
  end write_opb;

  procedure read_opb (signal OPB_Clk : in std_logic;
                      signal xferAck : in std_logic;
                      constant address : in std_logic_vector(0 to 31);
                      signal OPB_select : out std_logic;
                       signal OPB_RNW : out std_logic;
                       signal OPB_ABus : out std_logic_vector(0 to 31);
                       signal OPB_DBus : out std_logic_vector(0 to 31)
                       ) is
  begin
    wait until opb_clk'event and opb_clk='0';
    OPB_select <= '1';
    OPB_ABus <= address;
    OPB_DBus <= X"0000_0000";
    OPB_RNW <= '1';
    wait until opb_clk'event and opb_clk='1' and xferAck='1';
    OPB_select <= '0';
    OPB_ABus <= X"0000_0000";
    OPB_RNW <= '0';
    for i in 15 downto 0 loop
      wait until opb_clk'event and opb_clk='0';
    end loop;
  end read_opb;

  procedure write_ip (signal Bus2IP_Clk : in std_logic;
                      constant address : in std_logic_vector(0 to 31);
                      constant data : in std_logic_vector(0 to 31);
                      signal Bus2IP_CS : out std_logic;
                      signal Bus2IP_Addr : out std_logic_vector(0 to 31);
                      signal Bus2IP_Data : out std_logic_vector(0 to 31);
                      signal Bus2IP_WrCE : out std_logic
                     ) is
  begin

    wait until Bus2IP_Clk'event and Bus2IP_Clk='1';

    Bus2IP_Addr <= address;
    Bus2IP_Data <= data;
    Bus2IP_CS <= '1';
    Bus2IP_WrCE <= '1';

    --wait until Bus2IP_Clk'event and Bus2IP_Clk='1' and IP2Bus_Ack='1';
    wait until Bus2IP_Clk'event and Bus2IP_Clk='1';

    Bus2IP_Addr <= (others => '0');
    Bus2IP_CS <= '0';
    Bus2IP_Data <= (others => '0');
    Bus2IP_WrCE <= '0';

    for i in 15 downto 0 loop
      wait until Bus2IP_Clk'event and Bus2IP_Clk='1';
    end loop;
    
  end write_ip;

  procedure read_ip (signal Bus2IP_Clk : in std_logic;
                     signal IP2bus_Data : in std_logic_vector(0 to 31);
                     constant address : in std_logic_vector(0 to 31);
                     signal Bus2IP_CS : out std_logic;
                     signal Bus2IP_Addr : out std_logic_vector(0 to 31);
                     signal Bus2IP_RdCE : out std_logic;
                     signal IP_READ : out std_logic_vector(0 to 31)
                     ) is
  begin

    wait until Bus2IP_Clk'event and Bus2IP_Clk='1';

    Bus2IP_Addr <= address;
    Bus2IP_CS <= '1';
    Bus2IP_RdCE <= '1';

    --wait until Bus2IP_Clk'event and Bus2IP_Clk='1' and IP2Bus_Ack='1';
    wait until Bus2IP_Clk'event and Bus2IP_Clk='1';
    IP_READ <= IP2Bus_Data;

    Bus2IP_Addr <= (others => '0');
    Bus2IP_CS <= '0';
    Bus2IP_RdCE <= '0';

    for i in 15 downto 0 loop
      wait until Bus2IP_Clk'event and Bus2IP_Clk='1';
    end loop;
    
  end read_ip;

  procedure send_frame (signal clk : in std_logic;
                        variable slot0 : in std_logic_vector(15 downto 0);
                        variable slot1 : in std_logic_vector(19 downto 0);
                        variable slot2 : in std_logic_vector(19 downto 0);
                        variable slot3 : in std_logic_vector(19 downto 0);
                        variable slot4 : in std_logic_vector(19 downto 0);
                        variable slot5 : in std_logic_vector(19 downto 0);
                        variable slot6 : in std_logic_vector(19 downto 0);
                        variable slot7 : in std_logic_vector(19 downto 0);
                        variable slot8 : in std_logic_vector(19 downto 0);
                        variable slot9 : in std_logic_vector(19 downto 0);
                        variable slot10 : in std_logic_vector(19 downto 0);
                        variable slot11 : in std_logic_vector(19 downto 0);
                        variable slot12 : in std_logic_vector(19 downto 0);
                        signal SData_In : out std_logic) is
    variable shift_16 : std_logic_vector(15 downto 0);
    variable shift_20 : std_logic_vector(19 downto 0);
  begin
      -- Slot 0
      shift_16 := slot0;
      slot0_loop: for i in 15 downto 0 loop
        sdata_in <= shift_16(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 1
      shift_20 := slot1;
      slot1_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 2
      shift_20 := slot2;
      slot2_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 3
      shift_20 := slot3;
      slot3_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 4
      shift_20 := slot4;
      slot4_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 5
      shift_20 := slot5;
      slot5_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 6
      shift_20 := slot6;
      slot6_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 7
      shift_20 := slot7;
      slot7_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 8
      shift_20 := slot8;
      slot8_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 9
      shift_20 := slot9;
      slot9_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 10
      shift_20 := slot10;
      slot10_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 11
      shift_20 := slot11;
      slot11_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
      -- Slot 12
      shift_20 := slot12;
      slot12_loop: for i in 19 downto 0 loop
        sdata_in <= shift_20(i);
        wait until clk'event and clk='1';
      end loop;
  end send_frame;

  procedure send_basic_frame (signal clk : in std_logic;
                        variable slot0 : in std_logic_vector(15 downto 0);
                        variable slot1 : in std_logic_vector(19 downto 0);
                        variable slot2 : in std_logic_vector(19 downto 0);
                        variable slot3 : in std_logic_vector(19 downto 0);
                        variable slot4 : in std_logic_vector(19 downto 0);
                        signal SData_In : out std_logic) is
    variable slot5 : std_logic_vector(19 downto 0) := X"00000";
    variable slot6 : std_logic_vector(19 downto 0) := X"00000";
    variable slot7 : std_logic_vector(19 downto 0) := X"00000";
    variable slot8 : std_logic_vector(19 downto 0) := X"00000";
    variable slot9 : std_logic_vector(19 downto 0) := X"00000";
    variable slot10 : std_logic_vector(19 downto 0) := X"00000";
    variable slot11 : std_logic_vector(19 downto 0) := X"00000";
    variable slot12 : std_logic_vector(19 downto 0) := X"00000";
  begin
    send_frame(clk, slot0, slot1, slot2, slot3, slot4,
               slot5, slot6, slot7, slot8, slot9, slot10, slot11,
               slot12,sdata_in);
  end send_basic_frame;

end testbench_ac97_package;

