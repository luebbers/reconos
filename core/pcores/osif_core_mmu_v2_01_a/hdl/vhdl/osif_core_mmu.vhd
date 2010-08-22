library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library proc_common_v1_00_b;
--use proc_common_v1_00_b.proc_common_pkg.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

library osif_core_mmu_v2_01_a;
use osif_core_mmu_v2_01_a.all;

entity osif_core_mmu is
	generic
	(
		C_BASEADDR            :     std_logic_vector := X"FFFFFFFF";
		-- Bus protocol parameters
		C_AWIDTH              :     integer          := 32;
		C_DWIDTH              :     integer          := 32;
		C_PLB_AWIDTH          :     integer          := 32;
		C_PLB_DWIDTH          :     integer          := 64;
		C_NUM_CE              :     integer          := 2;
		C_BURST_AWIDTH        :     integer          := 13;  -- 1024 x 64 Bit = 8192 Bytes = 2^13 Bytes
		C_BURST_BASEADDR      :     std_logic_vector := X"00004000";  -- system memory base address for burst ram access
		C_THREAD_RESET_CYCLES :     natural          := 10;  -- number of cycles the thread reset is held
		C_FIFO_DWIDTH         :     integer          := 32;
		C_DCR_BASEADDR        :     std_logic_vector := "1111111111";
		C_DCR_HIGHADDR        :     std_logic_vector := "0000000000";
		C_DCR_AWIDTH          :     integer          := 10;
		C_DCR_DWIDTH          :     integer          := 32;
		C_DCR_ILA             :     integer          := 0;  -- 0: no debug ILA, 1: include debug chipscope ILA for DCR debugging
		
		C_TLB_TAG_WIDTH       : integer          := 20;
		C_TLB_DATA_WIDTH      : integer          := 21  
	);
	port
	(
		-- This is the complete osif_core interface (v2_01_1)
		-----------------------------------------------------------------------------------
		sys_clk               : in  std_logic;
		sys_reset             : in  std_logic;
		interrupt             : out std_logic;
		busy                  : out std_logic;
		blocking              : out std_logic;
		-- task interface
		task_clk              : out std_logic;
		task_reset            : out std_logic;
		osif_os2task_vec      : out std_logic_vector(0 to C_OSIF_OS2TASK_REC_WIDTH-1);
		osif_task2os_vec      : in  std_logic_vector(0 to C_OSIF_TASK2OS_REC_WIDTH-1);
		
		-- FIFO manager access signals
		-- left (read) FIFO
		o_fifomgr_read_remove : out std_logic;
		i_fifomgr_read_data   : in std_logic_vector(0 to C_FIFO_DWIDTH-1);
		i_fifomgr_read_wait   : in std_logic;
		-- right (write) FIFO
		o_fifomgr_write_add   : out std_logic;
		o_fifomgr_write_data  : out std_logic_vector(0 to C_FIFO_DWIDTH-1);
		i_fifomgr_write_wait  : in std_logic;
		
		-- memory access signals
		o_mem_singleData  : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
		i_mem_singleData  : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
		o_mem_localAddr   : out std_logic_vector(0 to C_AWIDTH-1);
		o_mem_targetAddr  : out std_logic_vector(0 to C_AWIDTH-1);
		o_mem_singleRdReq : out std_logic;
		o_mem_singleWrReq : out std_logic;
		o_mem_burstRdReq  : out std_logic;
		o_mem_burstWrReq  : out std_logic;
		o_mem_burstLen    : out std_logic_vector(0 to 4);
		
		i_mem_busy   : in std_logic;
		i_mem_rdDone : in std_logic;
		i_mem_wrDone : in std_logic;
		
		
		-- bus macro control
		o_bm_enable : out std_logic;
		
		-- tlb interface
		i_tlb_rdata    : in  std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
		o_tlb_wdata    : out std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
		o_tlb_tag      : out std_logic_vector(C_TLB_TAG_WIDTH - 1 downto 0);
		i_tlb_match    : in  std_logic;
		o_tlb_we       : out std_logic;
		i_tlb_busy     : in  std_logic;
		o_tlb_request  : out std_logic;
		
		-- dcr bus protocol ports
		o_dcrAck   : out std_logic;
		o_dcrDBus  : out std_logic_vector(0 to C_DCR_DWIDTH-1);
		i_dcrABus  : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
		i_dcrDBus  : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
		i_dcrRead  : in  std_logic;
		i_dcrWrite : in  std_logic;
		i_dcrICON  : in  std_logic_vector(35 downto 0)
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of osif_core_mmu is
	signal incoming_singleRdReq      : std_logic;
	signal incoming_singleWrReq      : std_logic;
	signal incoming_burstRdReq      : std_logic;
	signal incoming_burstWrReq      : std_logic;
	
	signal outgoing_busy          :std_logic;
	signal outgoing_mem_rdDone       : std_logic;
	signal outgoing_mem_wrDone       : std_logic;
	
	signal incoming_targetAddr : std_logic_vector(31 downto 0);
	signal incoming_mem_localAddr : std_logic_vector(31 downto 0);
	
	signal mmu_data : std_logic_vector(31 downto 0);
		
	signal mmu_setpgd : std_logic;
	signal mmu_repeat : std_logic;
	signal mmu_config_data : std_logic_vector(31 downto 0);
	
	signal mmu_state_fault            : std_logic;
	signal mmu_state_access_violation : std_logic;
		
	signal mmu_tlb_miss_count   : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
	signal mmu_tlb_hit_count    : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
	signal mmu_page_fault_count : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
	
	signal mmu_dcr_ack  : std_logic;
	signal core_dcr_ack  : std_logic;
	signal dcr_dbus : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
	
	-- tlb interface
	signal tlb_match       : std_logic;
	signal tlb_busy        : std_logic;
	signal tlb_we          : std_logic;
	--signal tlb_wdone       : std_logic;
	signal tlb_rdata       : std_logic_vector(19 downto 0);
	signal tlb_wdata       : std_logic_vector(19 downto 0);
	signal tlb_tag         : std_logic_vector(19 downto 0);
	
begin

	o_dcrAck <= core_dcr_ack or mmu_dcr_ack;

	--i_tlb : entity osif_core_v2_01_a.tlb
	--port map
	--(
	--	clk               => sys_clk,
	--	rst               => sys_reset,
		
	--	i_tag             => tlb_tag,
	--	i_data            => tlb_wdata,
	--	o_data            => tlb_rdata,
		
	--	i_we              => tlb_we,
	--	o_busy            => tlb_busy,
	--	o_wdone           => tlb_wdone,
	--	o_match           => tlb_match,
	--);
	
	i_mmu_dcr : entity osif_core_mmu_v2_01_a.mmu_dcr
	generic map
	(
		C_DCR_BASEADDR        => C_DCR_BASEADDR,
		C_DCR_HIGHADDR        => C_DCR_HIGHADDR,
		C_DCR_AWIDTH          => C_DCR_AWIDTH,
		C_DCR_DWIDTH          => C_DCR_DWIDTH
	)
	port map
	(
		clk                => sys_clk,
		rst                => sys_reset,
		
		-- mmu diagnosis registers
		i_tlb_miss_count   => mmu_tlb_miss_count,
		i_tlb_hit_count    => mmu_tlb_hit_count,
		i_page_fault_count => mmu_page_fault_count,
		
		-- dcr bus protocol ports
		o_dcrAck           => mmu_dcr_ack,
		o_dcrDBus          => o_dcrDBus,
		i_dcrABus          => i_dcrABus,
		i_dcrDBus          => dcr_dbus,
		i_dcrRead          => i_dcrRead,
		i_dcrWrite         => i_dcrWrite
	);

	i_mmu : entity osif_core_mmu_v2_01_a.mmu
	generic map
	(
		C_BASEADDR            => C_BASEADDR,
		C_AWIDTH              => C_AWIDTH,
		C_DWIDTH              => C_DWIDTH
	)
	
	port map
	(
		clk               => sys_clk,
		rst               => sys_reset,
		
		-- incoming memory interface
		i_swrq            => incoming_singleWrReq,
		i_srrq            => incoming_singleRdReq,
		i_bwrq            => incoming_burstWrReq,
		i_brrq            => incoming_burstRdReq,
		
		i_addr            => incoming_targetAddr,
		i_laddr           => incoming_mem_localAddr,
		o_data            => mmu_data,
		
		o_busy            => outgoing_busy,
		o_rdone           => outgoing_mem_rdDone,
		o_wdone           => outgoing_mem_wrDone,
		
		-- outgoing memory interface
		o_swrq            => o_mem_singleWrReq,
		o_srrq            => o_mem_singleRdReq,
		o_bwrq            => o_mem_burstWrReq,
		o_brrq            => o_mem_burstRdReq,
		            
		o_addr            => o_mem_targetAddr,
		o_laddr           => o_mem_localAddr,
		i_data            => i_mem_singleData,		
		
		i_busy            => i_mem_busy,
		i_rdone           => i_mem_rdDone,
		i_wdone           => i_mem_wrDone,
				
		-- configuration interface
		i_cfg             => mmu_config_data,
		i_setpgd          => mmu_setpgd,
		i_repeat          => mmu_repeat,
		
		-- interrupts
		o_state_fault            => mmu_state_fault,
		o_state_access_violation => mmu_state_access_violation,

		-- tlb interface
		i_tlb_match       => i_tlb_match,
		i_tlb_busy        => i_tlb_busy,
		--i_tlb_wdone       => i_tlb_wdone,
		o_tlb_we          => o_tlb_we,
		i_tlb_data        => i_tlb_rdata,
		o_tlb_data        => o_tlb_wdata,
		o_tlb_tag         => o_tlb_tag,
		o_tlb_request     => o_tlb_request,
	
		-- diagnosis	
		o_tlb_miss_count    => mmu_tlb_miss_count,
		o_tlb_hit_count     => mmu_tlb_hit_count,
		o_page_fault_count  => mmu_page_fault_count
	);
	
	i_osif_core: entity osif_core_mmu_v2_01_a.osif_core
	generic map
	(
		C_BASEADDR            => C_BASEADDR,
		C_AWIDTH              => C_AWIDTH,
		C_DWIDTH              => C_DWIDTH,
		C_PLB_AWIDTH          => C_PLB_AWIDTH,
		C_PLB_DWIDTH          => C_PLB_DWIDTH,
		C_NUM_CE              => C_NUM_CE,
		C_BURST_AWIDTH        => C_BURST_AWIDTH,
		C_BURST_BASEADDR      => C_BURST_BASEADDR,
		C_THREAD_RESET_CYCLES => C_THREAD_RESET_CYCLES,
		C_FIFO_DWIDTH         => C_FIFO_DWIDTH,
		C_DCR_BASEADDR        => C_DCR_BASEADDR,
		C_DCR_HIGHADDR        => C_DCR_HIGHADDR,
		C_DCR_AWIDTH          => C_DCR_AWIDTH,
		C_DCR_DWIDTH          => C_DCR_DWIDTH,
		C_DCR_ILA             => C_DCR_ILA
	)
	
	port map
	(
		sys_clk               => sys_clk,
		sys_reset             => sys_reset,
		interrupt             => interrupt,
		busy                  => busy,
		blocking              => blocking,
		-- task interface
		task_clk              => task_clk,
		task_reset            => task_reset,
		osif_os2task_vec      => osif_os2task_vec,
		osif_task2os_vec      => osif_task2os_vec,
		
		-- FIFO manager access signals
		-- left (read) FIFO
		o_fifomgr_read_remove => o_fifomgr_read_remove,
		i_fifomgr_read_data   => i_fifomgr_read_data,
		i_fifomgr_read_wait   => i_fifomgr_read_wait,
		-- right (write) FIFO
		o_fifomgr_write_add   => o_fifomgr_write_add,
		o_fifomgr_write_data  => o_fifomgr_write_data,
		i_fifomgr_write_wait  => i_fifomgr_write_wait,
		
		-- memory access signals
		o_mem_singleData  => o_mem_singleData,
		i_mem_singleData  => mmu_data,
		o_mem_localAddr   => incoming_mem_localAddr,
		o_mem_targetAddr  => incoming_targetAddr,
		o_mem_singleRdReq => incoming_singleRdReq,
		o_mem_singleWrReq => incoming_singleWrReq, --o_mem_singleWrReq,
		o_mem_burstRdReq  => incoming_burstRdReq, --o_mem_burstRdReq,
		o_mem_burstWrReq  => incoming_burstWrReq, --o_mem_burstWrReq,
		o_mem_burstLen    => o_mem_burstLen,
		
		i_mem_busy   => outgoing_busy,
		i_mem_rdDone => outgoing_mem_rdDone,
		i_mem_wrDone => outgoing_mem_wrDone,
		
		
		-- bus macro control
		o_bm_enable => o_bm_enable,
		
		-- mmu configuration
		o_mmu_setpgd           => mmu_setpgd,
		o_mmu_repeat           => mmu_repeat,
		o_mmu_config_data      => mmu_config_data, 
		i_mmu_state_fault            => mmu_state_fault,
		i_mmu_state_access_violation => mmu_state_access_violation,
		
		-- dcr bus protocol ports
		o_dcrAck   => core_dcr_ack,
		o_dcrDBus  => dcr_dbus,
		i_dcrABus  => i_dcrABus,
		i_dcrDBus  => i_dcrDBus,
		i_dcrRead  => i_dcrRead,
		i_dcrWrite => i_dcrWrite,
		i_dcrICON  => i_dcrICON
	);

end architecture;
