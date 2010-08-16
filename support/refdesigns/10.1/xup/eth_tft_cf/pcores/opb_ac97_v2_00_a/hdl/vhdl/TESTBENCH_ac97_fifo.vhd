-------------------------------------------------------------------------------
-- $Id: TESTBENCH_ac97_fifo.vhd,v 1.1 2005/02/18 15:30:21 wirthlin Exp $
-------------------------------------------------------------------------------
-- TESTBENCH_ac97_fifo.vhd
-------------------------------------------------------------------------------
--
--                  ****************************
--                  ** Copyright Xilinx, Inc. **
--                  ** All rights reserved.   **
--                  ****************************
--
-------------------------------------------------------------------------------
-- Filename:        TESTBENCH_ac97_fifo.vhd
--
-- Description:     Simple testbench for ac97_fifo
-- 
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
-- Revision:        $Revision: 1.1 $
-- Date:            $Date: 2005/02/18 15:30:21 $
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

entity TESTBENCH_ac97_fifo is
end TESTBENCH_ac97_fifo;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;
use opb_ac97_v2_00_a.testbench_ac97_package.all;

architecture behavioral of TESTBENCH_ac97_fifo is
  
  component ac97_fifo is
  generic (
    C_AWIDTH	: integer	:= 32;
    C_DWIDTH	: integer	:= 32;
    C_PLAYBACK        : integer                   := 1;
    C_RECORD          : integer                   := 0;
    C_INTR_LEVEL : integer  := 1;
    C_USE_BRAM : integer  := 1
    );
  port (
    -- IP Interface
    Bus2IP_Clk   : in  std_logic;
    Bus2IP_Reset : in  std_logic;
    Bus2IP_Addr  : in  std_logic_vector(0 to 31);
    Bus2IP_Data  : in  std_logic_vector(0 to 31);
    Bus2IP_BE	 : in  std_logic_vector(0 to C_DWIDTH/8-1);
    Bus2IP_RdCE  : in  std_logic;
    Bus2IP_WrCE  : in  std_logic;
    IP2Bus_Data  : out std_logic_vector(0 to 31);
    Interrupt : out std_logic;
    
    -- CODEC signals
    Bit_Clk   : in  std_logic;
    Sync      : out std_logic;
    SData_Out : out std_logic;
    SData_In  : in  std_logic;
    AC97Reset_n : out std_logic

    );

  end component;

  component ac97_model is
  port (
    AC97Reset_n   : in  std_logic;         
    Bit_Clk   : out  std_logic;
    Sync      : in std_logic;
    SData_Out : in std_logic;
    SData_In  : out  std_logic
    );
  end component;

  -- IP Interface
  signal Bus2IP_Addr  : std_logic_vector(0 to 31);
  signal Bus2IP_Clk   : std_logic;
  signal Bus2IP_CS    : std_logic;
  signal Bus2IP_Data  : std_logic_vector(0 to 31);
  signal Bus2IP_BE  : std_logic_vector(0 to 3);
  signal Bus2IP_RdCE  : std_logic;
  signal Bus2IP_Reset : std_logic;
  signal Bus2IP_WrCE  : std_logic;
  signal IP2Bus_Data  : std_logic_vector(0 to 31);
  signal Interrupt : std_logic;    
  signal Bit_Clk   : std_logic;
  signal Sync      : std_logic;
  signal SData_Out : std_logic;
  signal SData_In  : std_logic;
  signal AC97Reset_n  : std_logic;

  signal test_no : integer;
  signal IP_READ : std_logic_vector(0 to 31);
  signal sample : integer := 0;
  
begin  -- behavioral

  uut_1 : ac97_model
  port map (
    AC97Reset_n => ac97reset_n,
    Bit_Clk => Bit_Clk,
    Sync => Sync,
    SData_Out => SData_Out,
    SData_In => SData_In
    );

  uut : ac97_fifo
  generic map (
    C_INTR_LEVEL => 1,
    C_PLAYBACK => 1,
    C_RECORD => 1
    )
  port map (

    Bus2IP_Clk => Bus2IP_Clk,
    Bus2IP_Reset => Bus2IP_Reset,
    Bus2IP_Addr => Bus2IP_Addr,
    Bus2IP_Data => Bus2IP_Data,
    Bus2IP_BE => Bus2IP_BE,    
    Bus2IP_RdCE => Bus2IP_RdCE,
    Bus2IP_WrCE => Bus2IP_WrCE,
    IP2Bus_Data => IP2Bus_Data,
    Interrupt => Interrupt,
    
    -- CODEC signals
    Bit_Clk => Bit_Clk,
    Sync => Sync,
    SData_Out => SData_Out,
    SData_In => SData_In,
    AC97Reset_n => AC97Reset_n

    );

  clkgen_2: process
    begin
      Bus2IP_Clk<= '0';
      wait for 5 ns;
      Bus2IP_Clk<= '1';
      wait for 5 ns;
  end process;       
      
  -- simulate a reset
  opb_rst_gen: process
    begin
      Bus2IP_Reset <= '1';
      wait for 20 ns;
      Bus2IP_Reset <= '0'; 
      wait;
  end process opb_rst_gen;

  -- IP bus
  IP_proc: process
  begin
    test_no <= 0;

    Bus2IP_RdCE <= '0';
    Bus2IP_WrCE <= '0';
    Bus2IP_CS <= '0';
    Bus2IP_ADDR <= (others => '0');
    Bus2IP_DATA <= (others => '0');
    IP_READ <= (others => '0');

    -- skip some time slots before performing a bus cycle 
    for i in 100 downto 0 loop
      wait until Bus2IP_Clk'event and BUS2IP_Clk='1';
    end loop;

    -- Test 7. Reset CODEC
    test_no <= 7;
    write_ip(Bus2IP_Clk, FIFO_CTRL_OFFSET, X"00000010", Bus2IP_CS,
             Bus2IP_Addr,
            Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, FIFO_CTRL_OFFSET, X"00000000", Bus2IP_CS,
             Bus2IP_Addr,
            Bus2IP_Data, Bus2IP_WrCE);

    -- Test 1. Wait until codec ready is found (ready status)
    test_no <= 1;
    while IP_READ(26) /= '1' loop
      read_ip(Bus2IP_Clk, IP2Bus_Data, STATUS_OFFSET, Bus2IP_CS, Bus2IP_Addr,
              Bus2IP_RdCE, ip_read);
      for i in 50 downto 0 loop
        wait until Bus2IP_Clk'event and BUS2IP_Clk='1';
      end loop;
    end loop;
    
    -- Test #2: Clear FIFO status & read status again
    test_no <= 2;
    write_ip(Bus2IP_Clk, FIFO_CTRL_OFFSET, FIFO_CLEAR_MASK, Bus2IP_CS,
             Bus2IP_Addr,
            Bus2IP_Data, Bus2IP_WrCE);
    read_ip(Bus2IP_Clk, IP2Bus_Data, STATUS_OFFSET, Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);

    -- Test #6: Write data into playback fifo
    for i in 64 downto 0 loop
      wait until Bus2IP_Clk'event and BUS2IP_Clk='1';
    end loop;
    test_no <= 6;
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"AAAA_5555", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"5555_AAAA", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"AAAA_5555", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"5555_AAAA", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"AAAA_5555", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"5555_AAAA", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"AAAA_5555", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"5555_AAAA", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
             Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);

    -- Test #3: Read AC 97 register
    wait until sync'event and sync='1';
    test_no <= 3;

    -- Write to AC97_CTRL_ADDR (perform a AC97 "read")
    -- Address = "41" (lower 7 bits)
    -- Read = 1 "0b1xxx xxxx"
    write_ip(Bus2IP_Clk, REG_ADDR_OFFSET, X"0000_00C1", Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_Data, Bus2IP_WrCE);

    -- read from the status register until transfer is complete
    read_ip(Bus2IP_Clk, IP2Bus_Data, STATUS_OFFSET, Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);
    while ip_read(27) /= '0' loop
      read_ip(Bus2IP_Clk, IP2Bus_Data, STATUS_OFFSET, Bus2IP_CS, Bus2IP_Addr,
              Bus2IP_RdCE, ip_read);
    end loop;
    
    -- Now read the value of the data register returned
    read_ip(Bus2IP_Clk, IP2Bus_Data, REG_DATA_OFFSET, Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);
    
    -- Test #4: Write AC 97 register
    for i in 128 downto 0 loop
      wait until Bus2IP_Clk'event and BUS2IP_Clk='1';
    end loop;
    test_no <= 4;

    write_ip(Bus2IP_Clk, REG_DATA_WRITE_OFFSET, X"0000_8001",
             Bus2IP_CS, Bus2IP_Addr,
             Bus2IP_Data, Bus2IP_WrCE);

    -- Write to AC97_CTRL_ADDR (perform a AC97 "write")
    -- Address = "41" (lower 7 bits)
    -- Read = 0 "0b1xxx xxxx"
    write_ip(Bus2IP_Clk, REG_ADDR_OFFSET, X"0000_0041", Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_Data, Bus2IP_WrCE);
    read_ip(Bus2IP_Clk, IP2Bus_Data, STATUS_OFFSET, Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);
    while ip_read(27) /= '0' loop
      read_ip(Bus2IP_Clk, IP2Bus_Data, STATUS_OFFSET, Bus2IP_CS, Bus2IP_Addr,
              Bus2IP_RdCE, ip_read);
    end loop;
    
    
    -- Test #5: Read Playback data
    for i in 64 downto 0 loop
      wait until Bus2IP_Clk'event and BUS2IP_Clk='1';
    end loop;
    test_no <= 5;
    read_ip(Bus2IP_Clk, IP2Bus_Data, IN_FIFO_OFFSET,Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);
    read_ip(Bus2IP_Clk, IP2Bus_Data, IN_FIFO_OFFSET,Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);
    read_ip(Bus2IP_Clk, IP2Bus_Data, IN_FIFO_OFFSET,Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);
    read_ip(Bus2IP_Clk, IP2Bus_Data, IN_FIFO_OFFSET,Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);
    

    -- Test #8 - Interrupt
    test_no <= 8;

    -- Clear FIFO & read status
    write_ip(Bus2IP_Clk, FIFO_CTRL_OFFSET, FIFO_CLEAR_MASK, Bus2IP_CS,
             Bus2IP_Addr,
            Bus2IP_Data, Bus2IP_WrCE);
    read_ip(Bus2IP_Clk, IP2Bus_Data, STATUS_OFFSET, Bus2IP_CS, Bus2IP_Addr,
            Bus2IP_RdCE, ip_read);

    -- Fill FIFO
    for i in 512 downto 0 loop
      write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
               Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    end loop;
    
    -- Enable interrupts
    write_ip(Bus2IP_Clk, FIFO_CTRL_OFFSET, ENABLE_PLAY_INT_MASK, Bus2IP_CS,
             Bus2IP_Addr,
            Bus2IP_Data, Bus2IP_WrCE);

    -- Wait until an interrupt occurs
    wait until Interrupt'event and Interrupt = '1';
      
    -- Wait for a few more samples
    for i in 3 downto 0 loop
      wait until sync'event and sync='1';
    end loop;

    -- Put some more data into the Fifo and make sure the interrupt goes away
    for i in 8 downto 0 loop
      write_ip(Bus2IP_Clk, OUT_FIFO_OFFSET, X"8001_8001", Bus2IP_CS,
               Bus2IP_Addr, Bus2IP_Data, Bus2IP_WrCE);
    end loop;

    wait;
    
  end process;


end behavioral;
