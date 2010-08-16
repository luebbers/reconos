-------------------------------------------------------------------------------
-- $Id: srl_fifo.vhd,v 1.1 2005/02/18 15:30:22 wirthlin Exp $
-------------------------------------------------------------------------------
-- srl_fifo.vhd
-------------------------------------------------------------------------------
--
--                  ****************************
--                  ** Copyright Xilinx, Inc. **
--                  ** All rights reserved.   **
--                  ****************************
--
-------------------------------------------------------------------------------
-- Filename:        srl_fifo.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              srl_fifo.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.1 $
-- Date:            $Date: 2005/02/18 15:30:22 $
--
-- History:
--   goran  2001-06-12    First Version
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

entity SRL_FIFO is
  generic (
    C_DATA_BITS : integer := 8;
    C_DEPTH     : integer := 16
    );
  port (
    Clk         : in  std_logic;
    Reset       : in  std_logic;
    Clear_FIFO  : in  std_logic;
    FIFO_Write  : in  std_logic;
    Data_In     : in  std_logic_vector(0 to C_DATA_BITS-1);
    FIFO_Read   : in  std_logic;
    Data_Out    : out std_logic_vector(0 to C_DATA_BITS-1);
    FIFO_Full   : out std_logic;
    Data_Exists : out std_logic;
    FIFO_Level  : out std_logic_vector(0 to 3);
    Half_Full   : out std_logic;
    Half_Empty  : out std_logic
    );

end entity SRL_FIFO;

library UNISIM;
use UNISIM.all;

architecture IMP of SRL_FIFO is

  component SRL16E is
    -- pragma translate_off
    generic (
      INIT : bit_vector := X"0000"
      );
    -- pragma translate_on    
    port (
      CE  : in  std_logic;
      D   : in  std_logic;
      Clk : in  std_logic;
      A0  : in  std_logic;
      A1  : in  std_logic;
      A2  : in  std_logic;
      A3  : in  std_logic;
      Q   : out std_logic);
  end component SRL16E;

  component LUT4
    generic(
      -- pragma translate_off
      Xon  : boolean;
      -- pragma translate_on    
      INIT : bit_vector := X"0000"
      );
    port (
      O  : out std_logic;
      I0 : in  std_logic;
      I1 : in  std_logic;
      I2 : in  std_logic;
      I3 : in  std_logic);
  end component;

  component MULT_AND
    port (
      I0 : in  std_logic;
      I1 : in  std_logic;
      LO : out std_logic);
  end component;

  component MUXCY_L
    port (
      DI : in  std_logic;
      CI : in  std_logic;
      S  : in  std_logic;
      LO : out std_logic);
  end component;

  component XORCY
    port (
      LI : in  std_logic;
      CI : in  std_logic;
      O  : out std_logic);
  end component;

  component FDRE is
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      D  : in  std_logic;
      R  : in  std_logic);
  end component FDRE;

  signal Addr         : std_logic_vector(0 to 3);
  signal buffer_Full  : std_logic;
  signal buffer_Empty : std_logic;

  signal next_Data_Exists : std_logic;
  signal data_Exists_I    : std_logic;

  signal valid_Write : std_logic;

  signal hsum_A  : std_logic_vector(0 to 3);
  signal sum_A   : std_logic_vector(0 to 3);
  signal addr_cy : std_logic_vector(0 to 4);

  signal reset_int : std_logic;
  
begin  -- architecture IMP

  FIFO_Level <= Addr;
  
  reset_int <= Clear_FIFO or Reset;
  
  buffer_Full <= '1' when (Addr = "1111") else '0';
  FIFO_Full   <= buffer_Full;

  Half_Full  <= Addr(3);

  Half_Empty <= not Addr(3);

  buffer_Empty <= '1' when (Addr = "0000") else '0';

  next_Data_Exists <= (data_Exists_I and not buffer_Empty) or
                      (buffer_Empty and FIFO_Write) or
                      (data_Exists_I and not FIFO_Read);

  Data_Exists_DFF : process (Clk) is
  begin  -- process Data_Exists_DFF
    if Clk'event and Clk = '1' then  -- rising clock edge
      if (reset_int = '1') then
        data_Exists_I <= '0';
      else  
        data_Exists_I <= next_Data_Exists;
      end if;
    end if;
  end process Data_Exists_DFF;

  Data_Exists <= data_Exists_I;

  valid_Write <= FIFO_Write and (FIFO_Read or not buffer_Full);

  addr_cy(0) <= valid_Write;

  Addr_Counters : for I in 0 to 3 generate

    hsum_A(I) <= (FIFO_Read xor addr(I)) and (FIFO_Write or not buffer_Empty);

    -- Don't need the last muxcy, addr_cy(4) is not used anywhere
    Used_MuxCY : if I < 3 generate
      MUXCY_L_I : MUXCY_L
        port map (
          DI => addr(I),                -- [in  std_logic]
          CI => addr_cy(I),             -- [in  std_logic]
          S  => hsum_A(I),              -- [in  std_logic]
          LO => addr_cy(I+1));          -- [out std_logic]
    end generate Used_MuxCY;

    XORCY_I : XORCY
      port map (
        LI => hsum_A(I),                -- [in  std_logic]
        CI => addr_cy(I),               -- [in  std_logic]
        O  => sum_A(I));                -- [out std_logic]

    FDRE_I : FDRE
      port map (
        Q  => addr(I),                  -- [out std_logic]
        C  => Clk,                      -- [in  std_logic]
        CE => data_Exists_I,            -- [in  std_logic]
        D  => sum_A(I),                 -- [in  std_logic]
        R  => reset_int);               -- [in std_logic]

  end generate Addr_Counters;

  FIFO_RAM : for I in 0 to C_DATA_BITS-1 generate
    SRL16E_I : SRL16E
      -- pragma translate_off
      generic map (
        INIT => x"0000")
      -- pragma translate_on
      port map (
        CE  => valid_Write,             -- [in  std_logic]
        D   => Data_In(I),              -- [in  std_logic]
        Clk => Clk,                     -- [in  std_logic]
        A0  => Addr(0),                 -- [in  std_logic]
        A1  => Addr(1),                 -- [in  std_logic]
        A2  => Addr(2),                 -- [in  std_logic]
        A3  => Addr(3),                 -- [in  std_logic]
        Q   => Data_Out(I));            -- [out std_logic]
  end generate FIFO_RAM;
end architecture IMP;
