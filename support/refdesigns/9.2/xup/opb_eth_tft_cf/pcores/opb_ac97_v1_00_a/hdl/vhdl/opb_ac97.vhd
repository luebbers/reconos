-------------------------------------------------------------------------------
-- $Id: opb_ac97.vhd,v 1.1 2005/02/17 20:29:35 crh Exp $
-------------------------------------------------------------------------------
-- opb_ac97.vhd
-------------------------------------------------------------------------------
--
--                  ****************************
--                  ** Copyright Xilinx, Inc. **
--                  ** All rights reserved.   **
--                  ****************************
--
-------------------------------------------------------------------------------
-- Filename:        opb_ac97
--
-- Description:     Provides an OPB interface to the ac97 fifo controller 
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              ac97_fifo
--                ac97_core
--                   ac97_timing
--                srl_fifo
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
-- Revision:        $$
-- Date:            $$
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
use ieee.numeric_std.all;

entity opb_ac97 is
  generic (
    C_OPB_AWIDTH      : integer                   := 32;
    C_OPB_DWIDTH      : integer                   := 32;
    C_BASEADDR        : std_logic_vector(0 to 31) := X"FFFF_8000";
    C_HIGHADDR        : std_logic_vector          := X"FFFF_80FF";
    C_PLAYBACK        : integer                   := 1;
    C_RECORD          : integer                   := 1;
--    C_GPOUT_DWIDTH    : integer                   := 1;
    -- value of 0,1,2,3,4
    -- 0 = No Interrupt
    -- 1 = empty
    -- 2 = halfempty
    -- 3 = halffull 
    -- 4 = full     
    C_INTR_LEVEL : integer  := 1;
    C_USE_BRAM   : integer  := 1
    );
  port (
    OPB_ABus     : in  std_logic_vector(0 to C_OPB_AWIDTH-1);
    OPB_BE       : in  std_logic_vector(0 to C_OPB_DWIDTH/8-1);
    OPB_Clk      : in  std_logic;
    OPB_DBus     : in  std_logic_vector(0 to C_OPB_DWIDTH-1);
    OPB_RNW      : in  std_logic;
    OPB_Rst      : in  std_logic;
    OPB_select   : in  std_logic;
    OPB_seqAddr  : in  std_logic;

    Sln_DBus     : out std_logic_vector(0 to C_OPB_DWIDTH-1);
    Sln_errAck   : out std_logic;
    Sln_retry    : out std_logic;
    Sln_toutSup  : out std_logic;
    Sln_xferAck  : out std_logic;

    -- GPIO signals (Beep, reset, etc.)
--    AC97_GPOUT   : out std_logic_vector(0 to C_GPOUT_DWIDTH-1);

    -- Interrupt signals
    Interrupt : out std_logic;

    -- CODEC signals
    Bit_Clk   : in  std_logic;
    Sync      : out std_logic;
    SData_Out : out std_logic;
    SData_In  : in  std_logic;
    AC97Reset_n : out std_logic
    );
  
  
  attribute MIN_SIZE : string;
  attribute MIN_SIZE of C_BASEADDR : constant is "0x100";

  attribute SIGIS : string;
  attribute SIGIS of OPB_Clk : signal is "Clk";
  attribute SIGIS of OPB_Rst : signal is "Rst";

end entity opb_ac97;

-- library proc_common_v1_00_b;
-- use proc_common_v1_00_b.proc_common_pkg.all;

-- library ipif_common_v1_00_c;
-- use ipif_common_v1_00_c.ipif_pkg.all;

-- library opb_ipif_v3_00_a;
-- use opb_ipif_v3_00_a.all;

library Common_v1_00_a;
use Common_v1_00_a.pselect;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;

library unisim;
use unisim.all;

architecture IMP of opb_ac97 is

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
      Bus2IP_Clk      : in  std_logic;
      Bus2IP_Reset    : in  std_logic;
      Bus2IP_Addr     : in  std_logic_vector(0 to C_AWIDTH-1);
      Bus2IP_Data     : in  std_logic_vector(0 to C_AWIDTH-1);
      Bus2IP_BE	    : in  std_logic_vector(0 to C_DWIDTH/8-1);
      Bus2IP_RdCE	    : in  std_logic;
      Bus2IP_WrCE	    : in  std_logic;
      IP2Bus_Data     : out std_logic_vector(0 to C_DWIDTH-1);

      Interrupt: out std_logic;
      
      -- CODEC signals
      Bit_Clk   : in  std_logic;
      Sync      : out std_logic;
      SData_Out : out std_logic;
      SData_In  : in  std_logic;
      AC97Reset_n : out std_logic
    
    );
  end component ac97_fifo;

  component FDR is
    port (Q : out std_logic;
          C : in  std_logic;
          D : in  std_logic;
          R : in  std_logic);
  end component FDR;

  component FDRE is
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      D  : in  std_logic;
      R  : in  std_logic);
  end component FDRE;

  component pselect is
    generic (
      C_AB  : integer;
      C_AW  : integer;
      C_BAR : std_logic_vector);
    port (
      A      : in  std_logic_vector(0 to C_AW-1);
      AValid : in  std_logic;
      ps     : out std_logic);
  end component pselect;

  function Addr_Bits (x, y : std_logic_vector(0 to C_OPB_AWIDTH-1)) return integer is
    variable addr_nor : std_logic_vector(0 to C_OPB_AWIDTH-1);
  begin
    addr_nor := x xor y;
    for i in 0 to C_OPB_AWIDTH-1 loop
      if addr_nor(i) = '1' then return i;
      end if;
    end loop;
    return(C_OPB_AWIDTH);
  end function Addr_Bits;

  constant C_AB : integer := Addr_Bits(C_HIGHADDR, C_BASEADDR);

  signal ac97_CS : std_logic;
  signal ac97_CS_1 : std_logic;         -- Active as long as AC97_CS is active
  signal ac97_CS_2 : std_logic;         -- Active only 1 clock cycle during an
  signal ac97_CS_3 : std_logic;         -- Active only 1 clock cycle during an
  signal xfer_Ack     : std_logic;
  signal opb_RNW_1 : std_logic;
  signal opb_rdce : std_logic;
  signal opb_wrce : std_logic;

  signal iSln_DBus : std_logic_vector(0 to 31);

  signal interrupt_i : std_logic;
  
begin        

  Interrupt <= interrupt_i;
  
  -- Do the OPB address decoding
  pselect_I : pselect
    generic map (
      C_AB  => C_AB,                    -- [integer]
      C_AW  => C_OPB_AWIDTH,            -- [integer]
      C_BAR => C_BASEADDR)              -- [std_logic_vector]
    port map (
      A      => OPB_ABus,               -- [in  std_logic_vector(0 to C_AW-1)]
      AValid => OPB_select,             -- [in  std_logic]
      ps     => ac97_CS);               -- [out std_logic]

  ac97_CS_1_DFF : FDR
    port map (
      Q => ac97_CS_1,                   -- [out std_logic]
      C => OPB_Clk,                         -- [in  std_logic]
      D => ac97_CS,                     -- [in  std_logic]
      R => xfer_Ack);                   -- [in std_logic]

  ac97_CS_2_DFF: process (OPB_Clk, OPB_Rst) is
  begin  -- process uart_CS_2_DFF
    if OPB_Rst = '1' then                 -- asynchronous reset (active high)
      ac97_CS_2 <= '0';
      ac97_CS_3 <= '0';
      opb_RNW_1 <= '0';
    elsif OPB_Clk'event and OPB_Clk = '1' then  -- rising clock edge
      ac97_CS_2 <= ac97_CS_1 and not ac97_CS_2 and not ac97_CS_3;
      ac97_CS_3 <= ac97_CS_2;
      opb_RNW_1 <= OPB_RNW;
    end if;
  end process ac97_CS_2_DFF;

  opb_rdce <= ac97_CS_2 and OPB_RNW_1;
  opb_wrce <= ac97_CS_2 and (not OPB_RNW_1);

  XFER_Control : process (OPB_Clk, OPB_Rst) is
  begin  -- process XFER_Control
    if OPB_Rst = '1' then                 -- asynchronous reset (active high)
      xfer_Ack    <= '0';
    elsif OPB_Clk'event and OPB_Clk = '1' then  -- rising clock edge
      xfer_Ack <= ac97_CS_2;
    end if;
  end process XFER_Control;
  
  Sln_errAck   <= '0';
  Sln_retry   <= '0';
  Sln_toutSup   <= '0';
  sln_xferAck <= xfer_Ack;

  OPB_rdDBus_DFF : for I in iSln_DBus'range generate
    OPB_rdBus_FDRE : FDRE
      port map (
        Q  => Sln_DBus(I),              -- [out std_logic]
        C  => OPB_Clk,                  -- [in  std_logic]
        CE => ac97_CS_2,                -- [in  std_logic]
        D  => iSln_Dbus(I),            -- [in  std_logic]
        R  => xfer_Ack);                -- [in std_logic]
  end generate OPB_rdDBus_DFF;
               
  AC97_FIFO_I : ac97_fifo
    generic map (
      C_PLAYBACK => C_PLAYBACK,
      C_RECORD => C_RECORD,
      C_INTR_LEVEL => C_INTR_LEVEL,
      C_USE_BRAM => C_USE_BRAM
    )
    port map (
      -- IP Interface
      Bus2IP_Clk => OPB_Clk,
      Bus2IP_Reset => OPB_Rst,
      Bus2IP_Addr => OPB_ABus,
      Bus2IP_Data => OPB_Dbus,
      Bus2IP_BE => OPB_BE,
      Bus2IP_RdCE => opb_rdce,
      Bus2IP_WrCE => opb_wrce,
      IP2Bus_Data => iSln_DBus,
      Interrupt => interrupt_i,
      
      -- CODEC signals
      Bit_Clk   => Bit_Clk,
      Sync      => Sync,
      SData_Out => SData_Out,
      SData_In  => SData_In,
      AC97Reset_n => AC97Reset_n
      
    );

  
end architecture IMP;
