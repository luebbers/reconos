module GenMHS where

import Data.List
import GenVHDL(channelNameMasterMPD, channelNameSlaveMPD)

-- Definitions for Names (all strings)
type NodeName = String
type ConnectionName = String
type ChannelName = String

-- Definition for NodeConnection Type
data NodeConnection =
   NodeConnection NodeName ChannelName ConnectionName NodeName ChannelName
   |TwoWayNodeConnection NodeName ChannelName ConnectionName NodeName ChannelName
	deriving(Show,Eq,Ord)

-- Definition for NodeDefinition Type
data NodeDefinition=
   NodeDef NodeName NodeType
	deriving(Show,Eq)

-- Definition for NodeType
data NodeType =
	SW_node
	| HW_node
	deriving(Show,Eq)

-- Definition for an Architecture "program"
data ArchDefinition = 
  ArchDef [NodeDefinition] [NodeConnection]
	deriving(Show,Eq)

-- *****************************************************
-- Function used to generate MHS and MSS files
-- *****************************************************
gen_arch ad fname =
  let ad' = elaborate_connections ad
      mhs_name = fname++".mhs"
      mss_name = fname++".mss"
    in
	  do {
			writeFile mhs_name (mhs_template ad');
			writeFile mss_name (mss_template ad')
		}

-- *********************************************************
-- Function used to check an ArchDef to see if all of it's
-- nodes are declared
-- *********************************************************
check_arch xx =
  let xx' = elaborate_connections xx in
    check_arch_helper xx'

check_arch_helper (ArchDef ns cs) =
  let ns' = (map get_names ns)
      n_cs = (extract_node_names [] cs) in
     check_def ns' n_cs

 where get_names (NodeDef n _ ) = n

check_def nodes [] = True
check_def nodes (c:cs) =
 case (find (f c) nodes) of
    (Nothing) -> error ("Connection node "++c++" not found in node list")
    (Just x) -> check_def nodes cs
  where f c x = if (c == x) then True else False 


-- *****************************************************
-- Function used to get all node names out of the connections
-- *****************************************************
extract_node_names acc [] = nub acc
extract_node_names acc ((NodeConnection n1 _ _ n2 _):cs) =
  let acc' = n1:n2:acc in
     (extract_node_names acc' cs)

-- *****************************************************
-- Function used to Elaborate all 2-ways into 1-ways
-- *****************************************************
elaborate_connections (ArchDef ds cs) =
  let cs' = elab_connections [] cs in
    (ArchDef ds cs')

elab_connections acc [] = reverse acc
elab_connections acc (c:cs) =
 let a = case c of
          xx@(NodeConnection _ _ _ _ _) -> [xx]
          (TwoWayNodeConnection n1 c1 cc n2 c2) -> (NodeConnection n1 c1 (gen_one_way cc n1 n2) n2 c2):[(NodeConnection n2 c2 (gen_one_way cc n2 n1) n1 c1)]
    in
     elab_connections (a++acc) cs

gen_one_way cc s d = cc++"_"++s++"_to_"++d

-- *****************************************************
-- Function used to count the # of SW nodes in an
-- arch. definition
-- *****************************************************
number_of_sw_nodes (ArchDef ds cs) = num_sw ds

num_sw [] = 0 
num_sw ((NodeDef _ SW_node):as) = 1 + (num_sw as) 
num_sw ((NodeDef _ HW_node):as) = 0 + (num_sw as) 

get_sw_nodes (ArchDef ds cs) = get_sw [] ds

get_sw acc [] = acc
get_sw acc (xx@(NodeDef n SW_node):as) = get_sw (xx:acc) as
get_sw acc ((NodeDef _ HW_node):as) = get_sw acc as 

-- *****************************************************
-- Function used to find all node connections associated
-- with a given node def
-- *****************************************************
find_master_connections acc ll@(NodeDef n t) [] = acc
find_master_connections acc ll@(NodeDef n t) (xx@(NodeConnection name channel conn _ _):cs) = 
 let acc' =  if (n == name) then (xx:acc) else acc
    in (find_master_connections acc' ll cs) 

find_slave_connections acc ll@(NodeDef n t) [] = acc
find_slave_connections acc ll@(NodeDef n t) (xx@(NodeConnection _ _ conn name channel):cs) = 
 let acc' =  if (n == name) then (xx:acc) else acc
    in (find_slave_connections acc' ll cs)

-- *****************************************************
-- Function used to generate an set of FSMs
-- *****************************************************
gen_nodes [] procNum f cs = []
gen_nodes (n:ns) procNum f cs =
 (f n procNum cs)++(gen_nodes ns (procNum+1) f cs)

-- *****************************************************
-- Function used to generate an FSM instantiation in MHS
-- *****************************************************
gen_node xx@(NodeDef n SW_node) procNum cs =
  let ms = sort $ find_master_connections [] xx cs
      ss = sort $ find_slave_connections [] xx cs
   in
	unlines [
		"# ******************************************************************************",
		"BEGIN microblaze",
		" PARAMETER INSTANCE = microblaze_"++n,
		" PARAMETER HW_VER = 7.10.d",
		" PARAMETER C_DEBUG_ENABLED = 1",
		" PARAMETER C_FSL_LINKS = "++(show (length ms)),
		" PARAMETER C_FAMILY = virtex5",
		" PARAMETER C_INSTANCE = microblaze_"++n,
		" BUS_INTERFACE DPLB = mb_plb",
		" BUS_INTERFACE IPLB = mb_plb",
		" BUS_INTERFACE DLMB = dlmb_"++n,
		" BUS_INTERFACE ILMB = ilmb_"++n,
		" BUS_INTERFACE DEBUG = "++(debug_sig_name n),
		" PORT MB_RESET = mb_reset",
		gen_slave_fsl_busses 0 ss,
		gen_master_fsl_busses 0 ms,
		"END",
		"",
		"BEGIN lmb_v10",
		" PARAMETER INSTANCE = ilmb_"++n,
		" PARAMETER HW_VER = 1.00.a",
		" PORT LMB_Clk = sys_clk_s",
		" PORT SYS_Rst = sys_bus_reset",
		"END",
		"",
		"BEGIN lmb_v10",
		" PARAMETER INSTANCE = dlmb_"++n,
		" PARAMETER HW_VER = 1.00.a",
		" PORT LMB_Clk = sys_clk_s",
		" PORT SYS_Rst = sys_bus_reset",
		"END",
		"",
		"BEGIN lmb_bram_if_cntlr",
		" PARAMETER INSTANCE = dlmb_cntlr_"++n,
		" PARAMETER HW_VER = 2.10.a",
		" PARAMETER C_BASEADDR = 0x00000000",
		" PARAMETER C_HIGHADDR = 0x00007fff",
		" BUS_INTERFACE SLMB = dlmb_"++n,
		" BUS_INTERFACE BRAM_PORT = dlmb_port_"++n,
		"END",
		"",
		"BEGIN lmb_bram_if_cntlr",
		" PARAMETER INSTANCE = ilmb_cntlr_"++n,
		" PARAMETER HW_VER = 2.10.a",
		" PARAMETER C_BASEADDR = 0x00000000",
		" PARAMETER C_HIGHADDR = 0x00007fff",
		" BUS_INTERFACE SLMB = ilmb_"++n,
		" BUS_INTERFACE BRAM_PORT = ilmb_port_"++n,
		"END",
		"",
		"BEGIN bram_block",
		" PARAMETER INSTANCE = lmb_bram_"++n,
		" PARAMETER HW_VER = 1.00.a",
		" BUS_INTERFACE PORTA = ilmb_port_"++n,
		" BUS_INTERFACE PORTB = dlmb_port_"++n,
		"END"]

gen_node xx@(NodeDef n HW_node) procNum cs =
  let ms = sort $ find_master_connections [] xx cs
      ss = sort $ find_slave_connections [] xx cs
   in
	unlines [
		"# ******************************************************************************",
		"BEGIN "++n,
		" PARAMETER INSTANCE = "++n++"_"++(show procNum),
 		" PORT reset_sig = sys_rst_s",
		" PORT clock_sig = sys_clk_s",
		" # **************************",
		" # Insert other ports here...",
		" # **************************",
		gen_slave_fsl_customs 0 ss,
		gen_master_fsl_customs 0 ms,
		"END"]

gen_mss_node xx@(NodeDef n SW_node) procNum cs =
	unlines [
		"# ******************************************************************************",
		"BEGIN OS",
		" PARAMETER OS_NAME = standalone",
		" PARAMETER OS_VER = 2.00.a",
		" PARAMETER PROC_INSTANCE = microblaze_"++n,
		" PARAMETER STDIN = RS232_Uart_1",
		" PARAMETER STDOUT = RS232_Uart_1",
		"END",
		"",
		"",
		"BEGIN PROCESSOR",
		" PARAMETER DRIVER_NAME = cpu",
		" PARAMETER DRIVER_VER = 1.11.b",
		" PARAMETER HW_INSTANCE = microblaze_"++n,
		" PARAMETER COMPILER = mb-gcc",
		" PARAMETER ARCHIVER = mb-ar",
		"END",
		"",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = bram",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = dlmb_cntlr_"++n,
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = bram",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = ilmb_cntlr_"++n,
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = generic",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = lmb_bram_"++n,
		"END"
		]


gen_mss_node xx@(NodeDef n HW_node) procNum cs =
	unlines [
		"# ******************************************************************************",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = generic",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = "++n++"_"++(show procNum),
		"END"]




gen_slave_fsl_customs count [] = ""
gen_slave_fsl_customs count ((NodeConnection _ _ connName _ p):cs) =
  unlines [
		  " BUS_INTERFACE "++(channelNameSlaveMPD p)++" = "++(fsl_name connName),
		  gen_slave_fsl_customs (count+1) cs
          ]

gen_master_fsl_customs count [] = ""
gen_master_fsl_customs count ((NodeConnection _ p connName _ _):cs) =
  unlines [
		  " BUS_INTERFACE "++ (channelNameMasterMPD p)++" = "++(fsl_name connName),
		  gen_master_fsl_customs (count+1) cs
          ]


gen_slave_fsl_busses count [] = ""
gen_slave_fsl_busses count ((NodeConnection _ _ connName _ _):cs) =
  unlines [
		  " BUS_INTERFACE SFSL"++(show count)++" = "++(fsl_name connName),
		  gen_slave_fsl_busses (count+1) cs
          ]

gen_master_fsl_busses count [] = ""
gen_master_fsl_busses count ((NodeConnection _ _ connName _ _):cs) =
  unlines [
		  " BUS_INTERFACE MFSL"++(show count)++" = "++(fsl_name connName),
		  gen_master_fsl_busses (count+1) cs
          ]

-- *****************************************************
-- Function used to generate a set of FSL defs in MHS
-- *****************************************************
get_all_fsl_names acc [] = nub $ acc
get_all_fsl_names acc ((NodeConnection _ _ c _ _):cs) = get_all_fsl_names (c:acc) cs

fsl_code name = 
  unlines [
	"BEGIN fsl_v20",
	" PARAMETER INSTANCE = "++(fsl_name name),
	" PARAMETER HW_VER = 2.11.a",
	" PARAMETER C_EXT_RESET_HIGH = 0",
	" PARAMETER C_ASYNC_CLKS = 1",
	" PARAMETER C_IMPL_STYLE = 1",
	" PARAMETER C_FSL_DEPTH = 512",
	" PORT SYS_Rst = sys_rst_s",
	" PORT FSL_Clk = sys_clk_s",
	" PORT FSL_M_Clk = sys_clk_s",
	" PORT FSL_S_Clk = sys_clk_s",
	"END"]

fsl_name n = "fsl_"++n

-- *****************************************************
-- Function used to generate the MHS template
-- *****************************************************
mhs_template xx@(ArchDef ds cs) = 
 let num_procs = number_of_sw_nodes xx
     sw_nodes = get_sw_nodes xx
   in
	unlines [
			mhs_header num_procs sw_nodes,
			" # ***************************************************************",
			" # FSM Nodes",
			" # ***************************************************************",
			gen_nodes ds 0 (gen_node) cs,
			" # ***************************************************************",
			" # FSL Channel Connections",
			" # ***************************************************************",
			concatMap (fsl_code) (get_all_fsl_names [] cs)
			]

-- *****************************************************
-- Function used to generate the MHS template
-- *****************************************************
mss_template xx@(ArchDef ds cs) = 
 let num_procs = number_of_sw_nodes xx
     sw_nodes = get_sw_nodes xx
   in
	unlines [
			mss_header num_procs sw_nodes,
			" # ***************************************************************",
			" # FSM Nodes",
			" # ***************************************************************",
			gen_nodes ds 0 (gen_mss_node) cs
			]

-- *****************************************************
-- MHS Generation Functions
-- *****************************************************
gen_connections cs = []

-- *****************************************************
-- Generates MDM debug interfaces for each processor
-- *****************************************************
debug_sig_name c = "mb_debug_"++c

gen_debug_interfaces count nodes max =  
	if (count == max)
      then
        ""
      else
       unlines [
				" BUS_INTERFACE MBDEBUG_"++(show count)++" = "++(debug_sig_name (get_node_name nodes count)),
				gen_debug_interfaces (count+1) nodes max
     			]

get_node_name nodes count =
  case (nodes!!count) of
     (NodeDef n _) -> n
    --          (_) -> error "Node is not of the correct type!"

-- *****************************************************
-- Generates MHS header with all ports, busses, etc.
-- *****************************************************
mhs_header num_procs sw_nodes =  
  unlines [
	"# ##############################################################################",
	"# Created by FSMLanguage Compiler",
	"# Compatbiel with Base System Builder Wizard for Xilinx EDK 10.1.03 Build EDK_K_SP3.6",
	"# Target Board:  Xilinx Virtex 5 ML507 Evaluation Platform Rev A",
	"# Family:    virtex5",
	"# Device:    xc5vfx70t",
	"# Package:   ff1136",
	"# Speed Grade:  -1",
	"# Processor: microblaze_0",
	"# System clock frequency: 125.00 MHz",
	"# On Chip Memory :  32 KB",
	"# Total Off Chip Memory : 257 MB",
	"# - SRAM =   1 MB",
	"# - DDR2_SDRAM = 256 MB",
	"# ##############################################################################",
	" PARAMETER VERSION = 2.1.0",
	"",
	"",
	" PORT fpga_0_RS232_Uart_1_RX_pin = fpga_0_RS232_Uart_1_RX, DIR = I",
	" PORT fpga_0_RS232_Uart_1_TX_pin = fpga_0_RS232_Uart_1_TX, DIR = O",
	" PORT fpga_0_LEDs_8Bit_GPIO_IO_pin = fpga_0_LEDs_8Bit_GPIO_IO, DIR = IO, VEC = [0:7]",
	" PORT fpga_0_SRAM_Mem_A_pin = fpga_0_SRAM_Mem_A, DIR = O, VEC = [7:30]",
	" PORT fpga_0_SRAM_Mem_DQ_pin = fpga_0_SRAM_Mem_DQ, DIR = IO, VEC = [0:31]",
	" PORT fpga_0_SRAM_Mem_BEN_pin = fpga_0_SRAM_Mem_BEN, DIR = O, VEC = [0:3]",
	" PORT fpga_0_SRAM_Mem_OEN_pin = fpga_0_SRAM_Mem_OEN, DIR = O",
	" PORT fpga_0_SRAM_Mem_CEN_pin = fpga_0_SRAM_Mem_CEN, DIR = O",
	" PORT fpga_0_SRAM_Mem_ADV_LDN_pin = fpga_0_SRAM_Mem_ADV_LDN, DIR = O",
	" PORT fpga_0_SRAM_Mem_WEN_pin = fpga_0_SRAM_Mem_WEN, DIR = O",
	" PORT fpga_0_DDR2_SDRAM_DDR2_ODT_pin = fpga_0_DDR2_SDRAM_DDR2_ODT, DIR = O, VEC = [1:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_Addr_pin = fpga_0_DDR2_SDRAM_DDR2_Addr, DIR = O, VEC = [12:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_BankAddr_pin = fpga_0_DDR2_SDRAM_DDR2_BankAddr, DIR = O, VEC = [1:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_CAS_n_pin = fpga_0_DDR2_SDRAM_DDR2_CAS_n, DIR = O",
	" PORT fpga_0_DDR2_SDRAM_DDR2_CE_pin = fpga_0_DDR2_SDRAM_DDR2_CE, DIR = O, VEC = [0:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_CS_n_pin = fpga_0_DDR2_SDRAM_DDR2_CS_n, DIR = O, VEC = [0:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_RAS_n_pin = fpga_0_DDR2_SDRAM_DDR2_RAS_n, DIR = O",
	" PORT fpga_0_DDR2_SDRAM_DDR2_WE_n_pin = fpga_0_DDR2_SDRAM_DDR2_WE_n, DIR = O",
	" PORT fpga_0_DDR2_SDRAM_DDR2_Clk_pin = fpga_0_DDR2_SDRAM_DDR2_Clk, DIR = O, VEC = [1:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_Clk_n_pin = fpga_0_DDR2_SDRAM_DDR2_Clk_n, DIR = O, VEC = [1:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_DM_pin = fpga_0_DDR2_SDRAM_DDR2_DM, DIR = O, VEC = [7:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_DQS = fpga_0_DDR2_SDRAM_DDR2_DQS, DIR = IO, VEC = [7:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_DQS_n = fpga_0_DDR2_SDRAM_DDR2_DQS_n, DIR = IO, VEC = [7:0]",
	" PORT fpga_0_DDR2_SDRAM_DDR2_DQ = fpga_0_DDR2_SDRAM_DDR2_DQ, DIR = IO, VEC = [63:0]",
	" PORT fpga_0_SRAM_CLK = ZBT_CLK_OUT_s, DIR = O",
	" PORT fpga_0_SRAM_CLK_FB = ZBT_CLK_FB_s, DIR = I, SIGIS = CLK, CLK_FREQ = 125000000",
	" PORT sys_clk_pin = dcm_clk_s, DIR = I, SIGIS = CLK, CLK_FREQ = 100000000",
	" PORT sys_rst_pin = sys_rst_s, DIR = I, RST_POLARITY = 0, SIGIS = RST",
	"",
	"",
	"BEGIN plb_v46",
	" PARAMETER INSTANCE = mb_plb",
	" PARAMETER HW_VER = 1.03.a",
	" PORT PLB_Clk = sys_clk_s",
	" PORT SYS_Rst = sys_bus_reset",
	"END",
	"",
	"BEGIN xps_uartlite",
	" PARAMETER INSTANCE = RS232_Uart_1",
	" PARAMETER HW_VER = 1.00.a",
	" PARAMETER C_BAUDRATE = 9600",
	" PARAMETER C_DATA_BITS = 8",
	" PARAMETER C_ODD_PARITY = 0",
	" PARAMETER C_USE_PARITY = 0",
	" PARAMETER C_SPLB_CLK_FREQ_HZ = 125000000",
	" PARAMETER C_BASEADDR = 0x84000000",
	" PARAMETER C_HIGHADDR = 0x8400ffff",
	" BUS_INTERFACE SPLB = mb_plb",
	" PORT RX = fpga_0_RS232_Uart_1_RX",
	" PORT TX = fpga_0_RS232_Uart_1_TX",
	"END",
	"",
	"BEGIN xps_gpio",
	" PARAMETER INSTANCE = LEDs_8Bit",
	" PARAMETER HW_VER = 1.00.a",
	" PARAMETER C_GPIO_WIDTH = 8",
	" PARAMETER C_IS_DUAL = 0",
	" PARAMETER C_IS_BIDIR = 1",
	" PARAMETER C_ALL_INPUTS = 0",
	" PARAMETER C_BASEADDR = 0x81400000",
	" PARAMETER C_HIGHADDR = 0x8140ffff",
	" BUS_INTERFACE SPLB = mb_plb",
	" PORT GPIO_IO = fpga_0_LEDs_8Bit_GPIO_IO",
	"END",
	"",
	"BEGIN xps_mch_emc",
	" PARAMETER INSTANCE = SRAM",
	" PARAMETER HW_VER = 2.00.a",
	" PARAMETER C_MCH_PLB_CLK_PERIOD_PS = 8000",
	" PARAMETER C_NUM_BANKS_MEM = 1",
	" PARAMETER C_MAX_MEM_WIDTH = 32",
	" PARAMETER C_MEM0_WIDTH = 32",
	" PARAMETER C_INCLUDE_DATAWIDTH_MATCHING_0 = 0",
	" PARAMETER C_SYNCH_MEM_0 = 1",
	" PARAMETER C_TCEDV_PS_MEM_0 = 0",
	" PARAMETER C_TWC_PS_MEM_0 = 0",
	" PARAMETER C_TAVDV_PS_MEM_0 = 0",
	" PARAMETER C_TWP_PS_MEM_0 = 0",
	" PARAMETER C_THZCE_PS_MEM_0 = 0",
	" PARAMETER C_THZOE_PS_MEM_0 = 0",
	" PARAMETER C_TLZWE_PS_MEM_0 = 0",
	" PARAMETER C_MEM0_BASEADDR = 0x8a300000",
	" PARAMETER C_MEM0_HIGHADDR = 0x8a3fffff",
	" BUS_INTERFACE SPLB = mb_plb",
	" PORT Mem_A = fpga_0_SRAM_Mem_A_split",
	" PORT Mem_BEN = fpga_0_SRAM_Mem_BEN",
	" PORT Mem_WEN = fpga_0_SRAM_Mem_WEN",
	" PORT Mem_OEN = fpga_0_SRAM_Mem_OEN",
	" PORT Mem_DQ = fpga_0_SRAM_Mem_DQ",
	" PORT Mem_CEN = fpga_0_SRAM_Mem_CEN",
	" PORT Mem_ADV_LDN = fpga_0_SRAM_Mem_ADV_LDN",
	" PORT RdClk = sys_clk_s",
	"END",
	"",
	"BEGIN mpmc",
	" PARAMETER INSTANCE = DDR2_SDRAM",
	" PARAMETER HW_VER = 4.03.a",
	" PARAMETER C_NUM_PORTS = 1",
	" PARAMETER C_MEM_PARTNO = mt4htf3264h-53e",
	" PARAMETER C_NUM_IDELAYCTRL = 3",
	" PARAMETER C_IDELAYCTRL_LOC = IDELAYCTRL_X0Y6-IDELAYCTRL_X0Y2-IDELAYCTRL_X0Y1",
	" PARAMETER C_MEM_DQS_IO_COL = 0b000000000000000000",
	" PARAMETER C_MEM_DQ_IO_MS = 0b000000000111010100111101000011110001111000101110110000111100000110111100",
	" PARAMETER C_DDR2_DQSN_ENABLE = 1",
	" PARAMETER C_MEM_CE_WIDTH = 2",
	" PARAMETER C_MEM_CS_N_WIDTH = 2",
	" PARAMETER C_MEM_CLK_WIDTH = 2",
	" PARAMETER C_MEM_ODT_WIDTH = 2",
	" PARAMETER C_MEM_ODT_TYPE = 1",
	" PARAMETER C_MEM_BANKADDR_WIDTH = 2",
	" PARAMETER C_MEM_ADDR_WIDTH = 13",
	" PARAMETER C_PIM0_BASETYPE = 2",
	" PARAMETER C_MPMC_CLK0_PERIOD_PS = 8000",
	" PARAMETER C_MPMC_BASEADDR = 0x90000000",
	" PARAMETER C_MPMC_HIGHADDR = 0x9fffffff",
	" BUS_INTERFACE SPLB0 = mb_plb",
	" PORT DDR2_ODT = fpga_0_DDR2_SDRAM_DDR2_ODT",
	" PORT DDR2_Addr = fpga_0_DDR2_SDRAM_DDR2_Addr",
	" PORT DDR2_BankAddr = fpga_0_DDR2_SDRAM_DDR2_BankAddr",
	" PORT DDR2_CAS_n = fpga_0_DDR2_SDRAM_DDR2_CAS_n",
	" PORT DDR2_CE = fpga_0_DDR2_SDRAM_DDR2_CE_split",
	" PORT DDR2_CS_n = fpga_0_DDR2_SDRAM_DDR2_CS_n_split",
	" PORT DDR2_RAS_n = fpga_0_DDR2_SDRAM_DDR2_RAS_n",
	" PORT DDR2_WE_n = fpga_0_DDR2_SDRAM_DDR2_WE_n",
	" PORT DDR2_Clk = fpga_0_DDR2_SDRAM_DDR2_Clk",
	" PORT DDR2_Clk_n = fpga_0_DDR2_SDRAM_DDR2_Clk_n",
	" PORT DDR2_DM = fpga_0_DDR2_SDRAM_DDR2_DM",
	" PORT DDR2_DQS = fpga_0_DDR2_SDRAM_DDR2_DQS",
	" PORT DDR2_DQS_n = fpga_0_DDR2_SDRAM_DDR2_DQS_n",
	" PORT DDR2_DQ = fpga_0_DDR2_SDRAM_DDR2_DQ",
	" PORT MPMC_Clk0 = sys_clk_s",
	" PORT MPMC_Clk90 = DDR2_SDRAM_mpmc_clk_90_s",
	" PORT MPMC_Clk_200MHz = clk_200mhz_s",
	" PORT MPMC_Clk0_DIV2 = DDR2_SDRAM_MPMC_Clk_Div2",
	" PORT MPMC_Rst = sys_periph_reset",
	"END",
	"",
	"BEGIN xps_timer",
	" PARAMETER INSTANCE = xps_timer_1",
	" PARAMETER HW_VER = 1.00.a",
	" PARAMETER C_COUNT_WIDTH = 32",
	" PARAMETER C_ONE_TIMER_ONLY = 1",
	" PARAMETER C_BASEADDR = 0x83c00000",
	" PARAMETER C_HIGHADDR = 0x83c0ffff",
	" BUS_INTERFACE SPLB = mb_plb",
	"END",
	"",
	"BEGIN util_bus_split",
	" PARAMETER INSTANCE = SRAM_util_bus_split_0",
	" PARAMETER HW_VER = 1.00.a",
	" PARAMETER C_SIZE_IN = 32",
	" PARAMETER C_LEFT_POS = 7",
	" PARAMETER C_SPLIT = 31",
	" PORT Sig = fpga_0_SRAM_Mem_A_split",
	" PORT Out1 = fpga_0_SRAM_Mem_A",
	"END",
	"",
	"BEGIN util_bus_split",
	" PARAMETER INSTANCE = DDR2_SDRAM_util_bus_split_1",
	" PARAMETER HW_VER = 1.00.a",
	" PARAMETER C_SIZE_IN = 2",
	" PARAMETER C_LEFT_POS = 0",
	" PARAMETER C_SPLIT = 1",
	" PORT Sig = fpga_0_DDR2_SDRAM_DDR2_CE_split",
	" PORT Out2 = fpga_0_DDR2_SDRAM_DDR2_CE",
	"END",
	"",
	"BEGIN util_bus_split",
	" PARAMETER INSTANCE = DDR2_SDRAM_util_bus_split_2",
	" PARAMETER HW_VER = 1.00.a",
	" PARAMETER C_SIZE_IN = 2",
	" PARAMETER C_LEFT_POS = 0",
	" PARAMETER C_SPLIT = 1",
	" PORT Sig = fpga_0_DDR2_SDRAM_DDR2_CS_n_split",
	" PORT Out2 = fpga_0_DDR2_SDRAM_DDR2_CS_n",
	"END",
	"",
	"BEGIN clock_generator",
	" PARAMETER INSTANCE = clock_generator_0",
	" PARAMETER HW_VER = 2.01.a",
	" PARAMETER C_EXT_RESET_HIGH = 1",
	" PARAMETER C_CLKIN_FREQ = 100000000",
	" PARAMETER C_CLKOUT0_FREQ = 125000000",
	" PARAMETER C_CLKOUT0_BUF = TRUE",
	" PARAMETER C_CLKOUT0_PHASE = 0",
	" PARAMETER C_CLKOUT0_GROUP = PLL0",
	" PARAMETER C_CLKOUT1_FREQ = 125000000",
	" PARAMETER C_CLKOUT1_BUF = TRUE",
	" PARAMETER C_CLKOUT1_PHASE = 90",
	" PARAMETER C_CLKOUT1_GROUP = PLL0",
	" PARAMETER C_CLKOUT2_FREQ = 200000000",
	" PARAMETER C_CLKOUT2_BUF = TRUE",
	" PARAMETER C_CLKOUT2_PHASE = 0",
	" PARAMETER C_CLKOUT2_GROUP = NONE",
	" PARAMETER C_CLKOUT3_FREQ = 62500000",
	" PARAMETER C_CLKOUT3_BUF = TRUE",
	" PARAMETER C_CLKOUT3_PHASE = 0",
	" PARAMETER C_CLKOUT3_GROUP = NONE",
	" PARAMETER C_CLKFBIN_FREQ = 125000000",
	" PARAMETER C_CLKFBOUT_FREQ = 125000000",
	" PARAMETER C_CLKFBOUT_BUF = TRUE",
	" PORT CLKOUT0 = sys_clk_s",
	" PORT CLKOUT1 = DDR2_SDRAM_mpmc_clk_90_s",
	" PORT CLKOUT2 = clk_200mhz_s",
	" PORT CLKOUT3 = DDR2_SDRAM_MPMC_Clk_Div2",
	" PORT CLKIN = dcm_clk_s",
	" PORT LOCKED = Dcm_all_locked",
	" PORT RST = net_gnd",
	" PORT CLKFBIN = ZBT_CLK_FB_s",
	" PORT CLKFBOUT = ZBT_CLK_OUT_s",
	"END",
	"",
	"BEGIN mdm",
	" PARAMETER INSTANCE = debug_module",
	" PARAMETER HW_VER = 1.00.d",
	" PARAMETER C_MB_DBG_PORTS = "++(show num_procs),
	" PARAMETER C_BASEADDR = 0x84400000",
	" PARAMETER C_HIGHADDR = 0x8440ffff",
	" BUS_INTERFACE SPLB = mb_plb",
	" #"++(show num_procs),
	gen_debug_interfaces 0 sw_nodes num_procs,
	" PORT Debug_SYS_Rst = Debug_SYS_Rst",
	"END",
	"",
	"BEGIN proc_sys_reset",
	" PARAMETER INSTANCE = proc_sys_reset_0",
	" PARAMETER HW_VER = 2.00.a",
	" PARAMETER C_EXT_RESET_HIGH = 0",
	" PORT Slowest_sync_clk = sys_clk_s",
	" PORT Dcm_locked = Dcm_all_locked",
	" PORT Ext_Reset_In = sys_rst_s",
	" PORT MB_Reset = mb_reset",
	" PORT Bus_Struct_Reset = sys_bus_reset",
	" PORT MB_Debug_Sys_Rst = Debug_SYS_Rst",
	" PORT Peripheral_Reset = sys_periph_reset",
	"END"]

-- *****************************************************
-- Test Cases
-- *****************************************************
n1 = (NodeDef "producer" SW_node)
n2 = (NodeDef "consumer" HW_node)
n3 = (NodeDef "observer" SW_node)

-- 2 way connections
cn2_1 = (TwoWayNodeConnection "producer" "chan1" "pc" "consumer" "chan1")
cn2_2 = (TwoWayNodeConnection "consumer" "chan2" "pc" "observer" "chan1")

-- 1 way connections
cn1 = (NodeConnection "producer" "chan1" "p_c" "consumer" "chan1")
cn2 = (NodeConnection "consumer" "chan1" "c_p" "producer" "chan1")
cn3 = (NodeConnection "consumer" "chan2" "c_o" "observer" "chan1")
cn4 = (NodeConnection "observer" "chan1" "o_c" "consumer" "chan2")

ad1 = ArchDef [n1,n2,n3] [cn1,cn2,cn3,cn4]
ad2 = ArchDef [n1,n2,n3] [cn2_1, cn2_2]

-- Mesh of processors
mb0 = (NodeDef "mb0" SW_node)
mb1 = (NodeDef "mb1" SW_node)
mb2 = (NodeDef "mb2" SW_node)
mb3 = (NodeDef "mb3" SW_node)

cnn0 = (TwoWayNodeConnection "mb0" "c0" "aa" "mb1" "c3")
cnn1 = (TwoWayNodeConnection "mb0" "c2" "bb" "mb2" "c0")
cnn2 = (TwoWayNodeConnection "mb1" "c2" "cc" "mb3" "c0")
cnn3 = (TwoWayNodeConnection "mb3" "c3" "dd" "mb2" "c1")

mb_mesh = ArchDef [mb0,mb1,mb2,mb3] [cnn0,cnn1,cnn2,cnn3]

-- Function used to generate a list of nodes for a mesh
gen_node_mesh nodePrefix width =
  gen_node_list 0 nodePrefix (width*width)
  where gen_node_list count nodePrefix max =
           if (count == max)
             then
              []
             else
              (NodeDef (name nodePrefix count) SW_node):(gen_node_list (count+1) nodePrefix max)

-- Function used to generate a list of connections for a mesh
gen_n_connection_mesh nodePrefix width =
  gen_n_connection_list 0 nodePrefix (width*width) width
  where gen_n_connection_list count nodePrefix max width =
           if (count == max)
             then
              []
             else
              let r = calc_r count width -- number for right connection
                  d = mod (count + width) max -- number for down connection
                  rpre = count + 1
                  dpre = count + width
                in
                 let rc =
                       if (rpre <= r)
                        then(TwoWayNodeConnection (name nodePrefix count) (rname nodePrefix count) (rccname nodePrefix count) (name nodePrefix r) (rname nodePrefix r))
						else junk
                     dc = 
                       if (dpre <= d)
                         then(TwoWayNodeConnection (name nodePrefix count) (dname nodePrefix count) (dccname nodePrefix count) (name nodePrefix d) (dname nodePrefix d))
						 else junk
					in
						if (rc == junk)
                         then
                           if (dc == junk)
                             then
								((gen_n_connection_list (count+1) nodePrefix max width))
							 else
								(dc:(gen_n_connection_list (count+1) nodePrefix max width))
						 else
                           if (dc == junk)
                             then
								(rc:(gen_n_connection_list (count+1) nodePrefix max width))
							 else
								(rc:dc:(gen_n_connection_list (count+1) nodePrefix max width))


junk = (TwoWayNodeConnection "abccc" "abccc" "abccc" "abccc" "abccc")


calc_r x w = (mod (x+1) w) + (quot x w)*w



rccname s c= s++(show c)++"_r_conn"
dccname s c= s++(show c)++"_d_conn"

name s c = s++(show c)
rname s c = s++(show c)++"_r"
dname s c = s++(show c)++"_d"

rsname s c = s++(show c)++"_rs"
dsname s c = s++(show c)++"_ds"

mbMesh3 = ArchDef (gen_node_mesh "mb" 3) (gen_n_connection_mesh "mb" 3)
mbMesh4 = ArchDef (gen_node_mesh "mb" 4) (gen_n_connection_mesh "mb" 4)
mbMesh2 = ArchDef (gen_node_mesh "mb" 2) (gen_n_connection_mesh "mb" 2)

-- *****************************************************
-- Generates MSS header with all ports, busses, etc.
-- *****************************************************
mss_header num_procs sw_nodes =  
  unlines [
	    "# Created by FSMLanguage Compiler",
		"PARAMETER VERSION = 2.2.0",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = uartlite",
		" PARAMETER DRIVER_VER = 1.13.a",
		" PARAMETER HW_INSTANCE = RS232_Uart_1",
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = mpmc",
		" PARAMETER DRIVER_VER = 2.00.a",
		" PARAMETER HW_INSTANCE = DDR2_SDRAM",
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = generic",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = SRAM_util_bus_split_0",
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = generic",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = DDR2_SDRAM_util_bus_split_1",
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = generic",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = DDR2_SDRAM_util_bus_split_2",
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = generic",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = clock_generator_0",
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = uartlite",
		" PARAMETER DRIVER_VER = 1.13.a",
		" PARAMETER HW_INSTANCE = debug_module",
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = generic",
		" PARAMETER DRIVER_VER = 1.00.a",
		" PARAMETER HW_INSTANCE = proc_sys_reset_0",
		"END",
		"",
		"BEGIN DRIVER",
		" PARAMETER DRIVER_NAME = gpio",
		" PARAMETER DRIVER_VER = 2.12.a",
		" PARAMETER HW_INSTANCE = LEDs_8Bit",
		"END",
		""
	]
