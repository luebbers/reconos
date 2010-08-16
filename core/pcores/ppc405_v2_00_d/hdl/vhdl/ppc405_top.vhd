--
-- \file ppc405_top.vhd
--
-- PowerPC wrapper to connect CPU to OSIF
--
-- \author     robert Meiche <rmeiche@gmx.de>
-- \date       22.09.2009
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- 
-- This file is part of ReconOS (http://www.reconos.de).
-- Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
-- All rights reserved.
-- 
-- ReconOS is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option)
-- any later version.
-- 
-- ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
-- 
-- You should have received a copy of the GNU General Public License along
-- with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ppc405_v2_00_c;
use ppc405_v2_00_c.all;

library dcr_v29_v1_00_a;
use dcr_v29_v1_00_a.all;

library cpu_osif_adapter_v1_04_a;
use cpu_osif_adapter_v1_04_a.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.ALL;

entity ppc405_top is
   generic (    
            C_EXT_RESET_HIGH   :     integer          := 1;
            CPU_USE_OTHER_CLK  :     integer          := 0;
            CPU_RESET_CYCLES   :     integer          := 8;
            CPU_MMU_ENABLE     :     integer          := 1;
            CPU_DCR_RESYNC     :     integer          := 0;
            C_BOOT_SECT_DATA   : std_logic_vector := X"4bffd004" 
        );

        port (
          clk             : in   std_logic;  --clock from OSIF
          cpu_clk         : in std_logic;    -- Other clock from extern. Configurable via generic
          reset           : in  std_logic;
          --signals to osif
          i_osif_flat : in std_logic_vector;
          o_osif_flat : out std_logic_vector;
          --debug signals
          debug_idle_state       : out std_logic;
          debug_busy_state       : out std_logic;
          debug_reconos_ready    : out std_logic;
          --signal to/from bram_logic
          boot_sect_ready        : in std_logic;
          set_boot_sect          : out std_logic;
          boot_sect_data         : out std_logic_vector(31 downto 0);
          --CPU PLB ports
          PLBCLK         : in std_logic;
          C405PLBICUABUS : out std_logic_vector(0 to 31);
          C405PLBICUBE : out std_logic_vector(0 to 7);
          C405PLBICURNW : out std_logic;
          C405PLBICUABORT : out std_logic;
          C405PLBICUBUSLOCK : out std_logic;
          C405PLBICUU0ATTR : out std_logic;
          C405PLBICUGUARDED : out std_logic;
          C405PLBICULOCKERR : out std_logic;
          C405PLBICUMSIZE : out std_logic_vector(0 to 1);
          C405PLBICUORDERED : out std_logic;
          C405PLBICUPRIORITY : out std_logic_vector(0 to 1);
          C405PLBICURDBURST : out std_logic;
          C405PLBICUREQUEST : out std_logic;
          C405PLBICUSIZE : out std_logic_vector(0 to 3);
          C405PLBICUTYPE : out std_logic_vector(0 to 2);
          C405PLBICUWRBURST : out std_logic;
          C405PLBICUWRDBUS : out std_logic_vector(0 to 63);
          C405PLBICUCACHEABLE : out std_logic;
          PLBC405ICUADDRACK : in std_logic;
          PLBC405ICUBUSY : in std_logic;
          PLBC405ICUERR : in std_logic;
          PLBC405ICURDBTERM : in std_logic;
          PLBC405ICURDDACK : in std_logic;
          PLBC405ICURDDBUS : in std_logic_vector(0 to 63);
          PLBC405ICURDWDADDR : in std_logic_vector(0 to 3);
          PLBC405ICUREARBITRATE : in std_logic;
          PLBC405ICUWRBTERM : in std_logic;
          PLBC405ICUWRDACK : in std_logic;
          PLBC405ICUSSIZE : in std_logic_vector(0 to 1);
          PLBC405ICUSERR : in std_logic;
          PLBC405ICUSBUSYS : in std_logic;
          C405PLBDCUABUS : out std_logic_vector(0 to 31);
          C405PLBDCUBE : out std_logic_vector(0 to 7);
          C405PLBDCURNW : out std_logic;
          C405PLBDCUSIZE2     : out std_logic;
          C405PLBDCUABORT : out std_logic;
          C405PLBDCUBUSLOCK : out std_logic;
          C405PLBDCUU0ATTR : out std_logic;
          C405PLBDCUGUARDED : out std_logic;
          C405PLBDCULOCKERR : out std_logic;
          C405PLBDCUMSIZE : out std_logic_vector(0 to 1);
          C405PLBDCUORDERED : out std_logic;
          C405PLBDCUPRIORITY : out std_logic_vector(0 to 1);
          C405PLBDCURDBURST : out std_logic;
          C405PLBDCUREQUEST : out std_logic;
          C405PLBDCUSIZE : out std_logic_vector(0 to 3);
          C405PLBDCUTYPE : out std_logic_vector(0 to 2);
          C405PLBDCUWRBURST : out std_logic;
          C405PLBDCUWRDBUS : out std_logic_vector(0 to 63);
          C405PLBDCUCACHEABLE : out std_logic;
          C405PLBDCUWRITETHRU : out std_logic;
          PLBC405DCUADDRACK : in std_logic;
          PLBC405DCUBUSY : in std_logic;
          PLBC405DCUERR : in std_logic;
          PLBC405DCURDBTERM : in std_logic;
          PLBC405DCURDDACK : in std_logic;
          PLBC405DCURDDBUS : in std_logic_vector(0 to 63);
          PLBC405DCURDWDADDR : in std_logic_vector(0 to 3);
          PLBC405DCUREARBITRATE : in std_logic;
          PLBC405DCUWRBTERM : in std_logic;
          PLBC405DCUWRDACK : in std_logic;
          PLBC405DCUSSIZE : in std_logic_vector(0 to 1);
          PLBC405DCUSERR : in std_logic;
          PLBC405DCUSBUSYS : in std_logic;
          --OCM
          BRAMDSOCMCLK : in std_logic;
          BRAMDSOCMRDDBUS : in std_logic_vector(0 to 31);
          DSARCVALUE : in std_logic_vector(0 to 7);
          DSCNTLVALUE : in std_logic_vector(0 to 7);
          DSOCMBRAMABUS : out std_logic_vector(8 to 29);
          DSOCMBRAMBYTEWRITE : out std_logic_vector(0 to 3);
          DSOCMBRAMEN : out std_logic;
          DSOCMBRAMWRDBUS : out std_logic_vector(0 to 31);
          DSOCMBUSY : out std_logic;
          BRAMISOCMCLK : in std_logic;
          BRAMISOCMRDDBUS : in std_logic_vector(0 to 63);
          ISARCVALUE : in std_logic_vector(0 to 7);
          ISCNTLVALUE : in std_logic_vector(0 to 7);
          ISOCMBRAMEN : out std_logic;
          ISOCMBRAMEVENWRITEEN : out std_logic;
          ISOCMBRAMODDWRITEEN : out std_logic;
          ISOCMBRAMRDABUS : out std_logic_vector(8 to 28);
          ISOCMBRAMWRABUS : out std_logic_vector(8 to 28);
          ISOCMBRAMWRDBUS : out std_logic_vector(0 to 31);
          --CPU JTAG Interface
          C405JTGCAPTUREDR  : out std_logic;
          C405JTGEXTEST     : out std_logic;
          C405JTGPGMOUT     : out std_logic;
          C405JTGSHIFTDR    : out std_logic;
          C405JTGTDO        : out std_logic;
          C405JTGTDOEN      : out std_logic;
          C405JTGUPDATEDR   : out std_logic;
          MCBJTAGEN         : in  std_logic;
          JTGC405BNDSCANTDO : in  std_logic;
          JTGC405TCK        : in  std_logic;
          JTGC405TDI        : in  std_logic;
          JTGC405TMS        : in  std_logic;
          JTGC405TRSTNEG    : in  std_logic
        );
   
end ppc405_top;

architecture structural of ppc405_top is
   
   --constants for DCR
   constant C_DCR_AWIDTH : integer := 10;
   constant C_DCR_DWIDTH : integer := 32;
   --constants for OSIF_ADAPTER
   constant COMMANDREG_WIDTH : integer := 5; 
   constant DATAREG_WIDTH    : integer := 32;
   constant DONEREG_WIDTH    : integer := 1;
   constant CPU_DWIDTH       : integer := 32;
   --BOOTCODE for CPU_Start
   --constant C_BOOT_SECT_DATA : std_logic_vector := X"4bffd004";--X"4bffd004";--X"4bfffff0";X"48000000";
   
  --signals --------------------------------------------------------------------
  ---CPU_DCR -> CPU_HWT_DCR
  signal CPU_C405DCRABUS : std_logic_vector(0 to C_DCR_AWIDTH-1); 
  signal CPU_C405DCRDBUSOUT: std_logic_vector(0 to C_DCR_DWIDTH-1);
  signal CPU_DCRC405DBUSIN : std_logic_vector(0 to C_DCR_DWIDTH-1);
  signal CPU_C405DCRREAD : std_logic;
  signal CPU_C405DCRWRITE : std_logic;
  signal CPU_DCRC405ACK : std_logic;
  ---OSIF_ADPTER -> CPU_HWT_DCR
  signal o_dcrDBus      : std_logic_vector(0 to C_DCR_DWIDTH-1);
  signal i_dcrABus      : std_logic_vector(0 to C_DCR_AWIDTH-1);
  signal i_dcrDBus      : std_logic_vector(0 to C_DCR_DWIDTH-1);
  ---Connect Ack, Read, Write to DCR
  signal o_dcrAck_vec       : std_logic_vector(0 to 0);
  signal i_dcrRead_vec      : std_logic_vector(0 to 0);
  signal i_dcrWrite_vec     : std_logic_vector(0 to 0);
  ---OSIF_ADAPTER -> PPC
  signal cpu_reset  : std_logic;
  --OSIF_FLAT / Reset / busylocal
  signal o_osif_flat_i : std_logic_vector(0 to C_OSIF_TASK2OS_REC_WIDTH-1);
  signal i_osif_flat_i : std_logic_vector(0 to C_OSIF_OS2TASK_REC_WIDTH-1);
  signal o_osif : osif_task2os_t;
  signal i_osif : osif_os2task_t;
  signal busy_local : std_logic;     
  signal i_reset : std_logic;
  --clk signal for PowerPC
  signal ppc_clk : std_logic;
  --CPU signals which are not used
  signal CPMC405CPUCLKEN, CPMC405JTAGCLKEN, CPMC405TIMERCLKEN, CPMC405TIMERTICK, MCBCPUCLKEN, MCBTIMEREN, MCPPCRST : std_logic;
  signal CPMC405CORECLKINACTIVE, RSTC405RESETCHIP, RSTC405RESETSYS : std_logic;
  signal C405CPMCORESLEEPREQ,C405CPMMSRCE,C405CPMMSREE,C405CPMTIMERIRQ,C405CPMTIMERRESETREQ,C405XXXMACHINECHECK : std_logic;
  signal EICC405CRITINPUTIRQ, EICC405EXTINPUTIRQ : std_logic;
  signal C405DBGMSRWE, C405DBGSTOPACK, C405DBGWBCOMPLETE, C405DBGWBFULL, DBGC405DEBUGHALT, DBGC405EXTBUSHOLDACK, DBGC405UNCONDDEBUGEVENT : std_logic;
  signal C405DBGWBIAR : std_logic_vector(0 to 29);
  --other sigs
  signal net_vcc0 : std_logic;
  
begin

--other sigs
net_vcc0 <= '1';   
--Processess for the GENERICS ---------------------------------------------------

      --C_EXT_RESET_HIGH
      RSTPROCESS: process(reset)
       begin
           if C_EXT_RESET_HIGH = 1 then
              i_reset <= reset;
           else
              i_reset <= not reset;
           end if;
       end process;

      --CPU_USE_OTHER_CLK : 
      --if 1 then use port cpu_clk otherwise use threadclk_port clk
      CPU_CLK_PROCESS: process(clk, cpu_clk)
      begin
         if CPU_USE_OTHER_CLK = 1 then
            ppc_clk <= cpu_clk;
         else
            ppc_clk <= clk;
         end if;
      end process;
      
--Process and assignments for OSIF ----------------------------------------------
  
  -- (un)flatten osif records
   o_osif_flat_i <= to_std_logic_vector(o_osif);
   -- overlay busy with local busy signal
   --i_osif <= to_osif_os2task_t(i_osif_flat_i);
   i_osif <= to_osif_os2task_t(i_osif_flat_i or (X"0000000000" & busy_local & "000000"));
   
      
       register_osif_ports_proc: process(clk)
        begin
            if rising_edge(clk) then
                o_osif_flat <= o_osif_flat_i;
                i_osif_flat_i <= i_osif_flat;
            end if;
        end process;

        -- infer latch for local busy signal
        -- needed for asynchronous communication between thread and OSIF
        busy_local_gen : process(i_reset, o_osif.request, i_osif.ack)
        begin
            if i_reset = '1' then
                busy_local <= '0';
            elsif o_osif.request = '1' then
                busy_local <= '1';
            elsif i_osif.ack = '1' then
                busy_local <= '0';
            end if;
        end process;
   
--------- COMPONENTS ------------------------------------------------------------        
  cpu_osif_adapter_i : entity cpu_osif_adapter_v1_04_a.cpu_osif_adapter
        generic map (
            C_BASEADDR => B"0000011000",
            C_HIGHADDR => B"0000011111",
            C_DCR_AWIDTH => C_DCR_AWIDTH,
            C_DCR_DWIDTH => C_DCR_DWIDTH,
            COMMANDREG_WIDTH => COMMANDREG_WIDTH,
            DATAREG_WIDTH => DATAREG_WIDTH,
            DONEREG_WIDTH => DONEREG_WIDTH,
            CPU_RESET_CYCLES => CPU_RESET_CYCLES,
            CPU_DWIDTH => CPU_DWIDTH,
            C_BOOT_SECT_DATA => C_BOOT_SECT_DATA
        )
        port map (
                clk            => clk, 
                reset          => i_reset,
                --dcr signals for Main CPU
                o_dcrAck       => o_dcrAck_vec(0),
                o_dcrDBus      => o_dcrDBus,
                i_dcrABus      => i_dcrABus,
                i_dcrDBus      => i_dcrDBus,
                i_dcrRead      => i_dcrRead_vec(0),
                i_dcrWrite     => i_dcrWrite_vec(0),
                --signals to osif
                i_osif         => i_osif,
                o_osif         => o_osif,
                cpu_reset      => cpu_reset,
                --debug signals
                debug_idle_state    => debug_idle_state,
                debug_busy_state    => debug_busy_state,
                debug_reconos_ready => debug_reconos_ready,
                --signal to/from bram_logic
                boot_sect_ready     => boot_sect_ready,
                set_boot_sect       => set_boot_sect,
                boot_sect_data      => boot_sect_data
        );
  
  CPU_HWT_DCR_BUS : entity dcr_v29_v1_00_a.dcr_v29
    generic map (
      C_DCR_NUM_SLAVES => 1,
      C_DCR_AWIDTH => C_DCR_AWIDTH,
      C_DCR_DWIDTH => C_DCR_DWIDTH,
      C_USE_LUT_OR => 1
    )
    port map (
      M_dcrABus => CPU_C405DCRABUS,
      M_dcrDBus => CPU_C405DCRDBUSOUT,
      M_dcrRead => CPU_C405DCRREAD,
      M_dcrWrite => CPU_C405DCRWRITE,
      DCR_M_DBus => CPU_DCRC405DBUSIN,
      DCR_Ack => CPU_DCRC405ACK,
      DCR_ABus => i_dcrABus,
      DCR_Sl_DBus => i_dcrDBus,
      DCR_Read => i_dcrRead_vec,
      DCR_Write => i_dcrWrite_vec,
      Sl_dcrDBus => o_dcrDBus,
      Sl_dcrAck => o_dcrAck_vec
    ); 
   
 CPU_HWT : entity ppc405_v2_00_c.ppc405_top
    generic map (
      C_ISOCM_DCR_BASEADDR => B"0000010000",
      C_ISOCM_DCR_HIGHADDR => B"0000010011",
      C_DSOCM_DCR_BASEADDR => B"0000100000",
      C_DSOCM_DCR_HIGHADDR => B"0000100011",
      C_DISABLE_OPERAND_FORWARDING => 1,
      C_DETERMINISTIC_MULT => 0,
      C_MMU_ENABLE => CPU_MMU_ENABLE,
      C_DCR_RESYNC => CPU_DCR_RESYNC
    )
    port map (
      CPMC405CLOCK => ppc_clk,
      DCRCLK => clk,
      C405RSTCHIPRESETREQ => open,
      C405RSTCORERESETREQ => open,
      C405RSTSYSRESETREQ => open,
      RSTC405RESETCHIP => '0',--RSTC405RESETCHIP,
      RSTC405RESETCORE => cpu_reset,
      RSTC405RESETSYS => '0',--RSTC405RESETSYS,
      --PLB signals
      PLBCLK => PLBCLK,
      C405PLBICUABUS => C405PLBICUABUS,
      C405PLBICUBE => C405PLBICUBE,
      C405PLBICURNW => C405PLBICURNW,
      C405PLBICUABORT => C405PLBICUABORT,
      C405PLBICUBUSLOCK => C405PLBICUBUSLOCK,
      C405PLBICUU0ATTR => C405PLBICUU0ATTR,
      C405PLBICUGUARDED => C405PLBICUGUARDED,
      C405PLBICULOCKERR => C405PLBICULOCKERR,
      C405PLBICUMSIZE => C405PLBICUMSIZE,
      C405PLBICUORDERED => C405PLBICUORDERED,
      C405PLBICUPRIORITY => C405PLBICUPRIORITY,
      C405PLBICURDBURST => C405PLBICURDBURST,
      C405PLBICUREQUEST => C405PLBICUREQUEST,
      C405PLBICUSIZE => C405PLBICUSIZE,
      C405PLBICUTYPE => C405PLBICUTYPE,
      C405PLBICUWRBURST => C405PLBICUWRBURST,
      C405PLBICUWRDBUS => C405PLBICUWRDBUS,
      C405PLBICUCACHEABLE => C405PLBICUCACHEABLE,
      PLBC405ICUADDRACK => PLBC405ICUADDRACK,
      PLBC405ICUBUSY => PLBC405ICUBUSY,
      PLBC405ICUERR => PLBC405ICUERR,
      PLBC405ICURDBTERM => PLBC405ICURDBTERM,
      PLBC405ICURDDACK => PLBC405ICURDDACK,
      PLBC405ICURDDBUS => PLBC405ICURDDBUS,
      PLBC405ICURDWDADDR => PLBC405ICURDWDADDR,
      PLBC405ICUREARBITRATE => PLBC405ICUREARBITRATE,
      PLBC405ICUWRBTERM => PLBC405ICUWRBTERM,
      PLBC405ICUWRDACK => PLBC405ICUWRDACK,
      PLBC405ICUSSIZE => PLBC405ICUSSIZE,
      PLBC405ICUSERR => PLBC405ICUSERR,
      PLBC405ICUSBUSYS => PLBC405ICUSBUSYS,
      C405PLBDCUABUS => C405PLBDCUABUS,
      C405PLBDCUBE => C405PLBDCUBE,
      C405PLBDCURNW => C405PLBDCURNW,
      C405PLBDCUABORT => C405PLBDCUABORT,
      C405PLBDCUBUSLOCK => C405PLBDCUBUSLOCK,
      C405PLBDCUU0ATTR => C405PLBDCUU0ATTR,
      C405PLBDCUGUARDED => C405PLBDCUGUARDED,
      C405PLBDCULOCKERR => C405PLBDCULOCKERR,
      C405PLBDCUMSIZE => C405PLBDCUMSIZE,
      C405PLBDCUORDERED => C405PLBDCUORDERED,
      C405PLBDCUPRIORITY => C405PLBDCUPRIORITY,
      C405PLBDCURDBURST => C405PLBDCURDBURST,
      C405PLBDCUREQUEST => C405PLBDCUREQUEST,
      C405PLBDCUSIZE => C405PLBDCUSIZE,
      C405PLBDCUTYPE => C405PLBDCUTYPE,
      C405PLBDCUWRBURST => C405PLBDCUWRBURST,
      C405PLBDCUWRDBUS => C405PLBDCUWRDBUS,
      C405PLBDCUCACHEABLE => C405PLBDCUCACHEABLE,
      C405PLBDCUWRITETHRU => C405PLBDCUWRITETHRU,
      PLBC405DCUADDRACK => PLBC405DCUADDRACK,
      PLBC405DCUBUSY => PLBC405DCUBUSY,
      PLBC405DCUERR => PLBC405DCUERR,
      PLBC405DCURDBTERM => PLBC405DCURDBTERM,
      PLBC405DCURDDACK => PLBC405DCURDDACK,
      PLBC405DCURDDBUS => PLBC405DCURDDBUS,
      PLBC405DCURDWDADDR => PLBC405DCURDWDADDR,
      PLBC405DCUREARBITRATE => PLBC405DCUREARBITRATE,
      PLBC405DCUWRBTERM => PLBC405DCUWRBTERM,
      PLBC405DCUWRDACK => PLBC405DCUWRDACK,
      PLBC405DCUSSIZE => PLBC405DCUSSIZE,
      PLBC405DCUSERR => PLBC405DCUSERR,
      PLBC405DCUSBUSYS => PLBC405DCUSBUSYS,
      --ocm signals
      BRAMDSOCMCLK => BRAMDSOCMCLK,
      BRAMDSOCMRDDBUS => BRAMDSOCMRDDBUS,
      DSARCVALUE => DSARCVALUE,
      DSCNTLVALUE => DSCNTLVALUE,
      DSOCMBRAMABUS => DSOCMBRAMABUS,
      DSOCMBRAMBYTEWRITE => DSOCMBRAMBYTEWRITE,
      DSOCMBRAMEN => DSOCMBRAMEN,
      DSOCMBRAMWRDBUS => DSOCMBRAMWRDBUS,
      DSOCMBUSY => DSOCMBUSY,
      BRAMISOCMCLK => BRAMISOCMCLK,
      BRAMISOCMRDDBUS => BRAMISOCMRDDBUS,
      ISARCVALUE => ISARCVALUE,
      ISCNTLVALUE => ISCNTLVALUE,
      ISOCMBRAMEN => ISOCMBRAMEN,
      ISOCMBRAMEVENWRITEEN => ISOCMBRAMEVENWRITEEN,
      ISOCMBRAMODDWRITEEN => ISOCMBRAMODDWRITEEN,
      ISOCMBRAMRDABUS => ISOCMBRAMRDABUS,
      ISOCMBRAMWRABUS => ISOCMBRAMWRABUS,
      ISOCMBRAMWRDBUS => ISOCMBRAMWRDBUS,
      --DCR signals
      C405DCRABUS => CPU_C405DCRABUS,
      C405DCRDBUSOUT => CPU_C405DCRDBUSOUT,
      C405DCRREAD => CPU_C405DCRREAD,
      C405DCRWRITE => CPU_C405DCRWRITE,
      DCRC405ACK => CPU_DCRC405ACK,
      DCRC405DBUSIN => CPU_DCRC405DBUSIN,
      -- JTAG Interface
      C405JTGCAPTUREDR           => C405JTGCAPTUREDR,              -- O
      C405JTGEXTEST              => C405JTGEXTEST,                 -- O
      C405JTGPGMOUT              => C405JTGPGMOUT,                 -- O
      C405JTGSHIFTDR             => C405JTGSHIFTDR,                -- O
      C405JTGTDO                 => C405JTGTDO,                    -- O
      C405JTGTDOEN               => C405JTGTDOEN,                  -- O
      C405JTGUPDATEDR            => C405JTGUPDATEDR,               -- O
      MCBJTAGEN                  => net_vcc0,--MCBJTAGEN,                     -- I 
      JTGC405BNDSCANTDO          => JTGC405BNDSCANTDO,             -- I
      JTGC405TCK                 => JTGC405TCK,                    -- I
      JTGC405TDI                 => JTGC405TDI,                    -- I
      JTGC405TMS                 => JTGC405TMS,                    -- I
      JTGC405TRSTNEG             => JTGC405TRSTNEG,
      --Ports which are not used -----------------------------------------------
      CPMC405CORECLKINACTIVE     => '0',--CPMC405CORECLKINACTIVE,        -- I 
      CPMC405CPUCLKEN            => net_vcc0, --CPMC405CPUCLKEN,               -- I 
      CPMC405JTAGCLKEN           => net_vcc0, --CPMC405JTAGCLKEN,              -- I 
      CPMC405TIMERCLKEN          => net_vcc0, --CPMC405TIMERCLKEN,             -- I 
      CPMC405TIMERTICK           => net_vcc0, --CPMC405TIMERTICK,              -- I
      MCBCPUCLKEN                => net_vcc0, --MCBCPUCLKEN,                   -- I 
      MCBTIMEREN                 => net_vcc0, --MCBTIMEREN,                    -- I 
      MCPPCRST                   => net_vcc0, --MCPPCRST,
      C405CPMCORESLEEPREQ        => C405CPMCORESLEEPREQ,           -- O
      C405CPMMSRCE               => C405CPMMSRCE,                  -- O 
      C405CPMMSREE               => C405CPMMSREE,                  -- O 
      C405CPMTIMERIRQ            => C405CPMTIMERIRQ,               -- O 
      C405CPMTIMERRESETREQ       => C405CPMTIMERRESETREQ,          -- O 
      C405XXXMACHINECHECK        => C405XXXMACHINECHECK,           -- O
      -- Interrupt Controller Interface
      EICC405CRITINPUTIRQ        => '0',--EICC405CRITINPUTIRQ,           -- I
      EICC405EXTINPUTIRQ         => '0',--EICC405EXTINPUTIRQ,            -- I
      -- Debug Interface
      C405DBGMSRWE              => C405DBGMSRWE,                  -- O 
      C405DBGSTOPACK             => C405DBGSTOPACK,                -- O 
      C405DBGWBCOMPLETE          => C405DBGWBCOMPLETE,             -- O
      C405DBGWBFULL              => C405DBGWBFULL,                 -- O
      C405DBGWBIAR               => C405DBGWBIAR,                  -- O [0:29]
      DBGC405DEBUGHALT           => '0',--DBGC405DEBUGHALT,              -- I
      DBGC405EXTBUSHOLDACK       => '0',--DBGC405EXTBUSHOLDACK,          -- I
      DBGC405UNCONDDEBUGEVENT    => '0',--DBGC405UNCONDDEBUGEVENT,
      -- Trace Interface
      C405TRCCYCLE               => open ,                  -- O
      C405TRCEVENEXECUTIONSTATUS => open,    -- O [0:1]
      C405TRCODDEXECUTIONSTATUS  => open,     -- O [0:1]
      C405TRCTRACESTATUS         => open,            -- O [0:3]
      C405TRCTRIGGEREVENTOUT     => open,        -- O
      C405TRCTRIGGEREVENTTYPE    => open,       -- O [0:10]
      TRCC405TRACEDISABLE        => '0',           -- I
      TRCC405TRIGGEREVENTIN      => '0'          -- I
    );
   

end structural;
