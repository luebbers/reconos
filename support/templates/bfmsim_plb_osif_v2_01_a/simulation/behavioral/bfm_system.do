#  Simulation Model Generator
#  Xilinx EDK 8.2.02 EDK_Im_Sp2.4
#  Copyright (c) 1995-2006 Xilinx, Inc.  All rights reserved.
#
#  File     bfm_system.do (Thu Feb 15 13:04:30 2007)
#
vmap XilinxCoreLib /opt/Xilinx/ISE_Lib/8.2.01_EAPR_06/XilinxCoreLib/
vmap XilinxCoreLib_ver /opt/Xilinx/ISE_Lib/8.2.01_EAPR_06/XilinxCoreLib_ver/
vmap simprim /opt/Xilinx/ISE_Lib/8.2.01_EAPR_06/simprim/
vmap simprims_ver /opt/Xilinx/ISE_Lib/8.2.01_EAPR_06/simprims_ver/
vmap unisim /opt/Xilinx/ISE_Lib/8.2.01_EAPR_06/unisim/
vmap unisims_ver /opt/Xilinx/ISE_Lib/8.2.01_EAPR_06/unisims_ver/
vmap plb_bfm /opt/Xilinx/EDK_Lib/plb_bfm/
vmap plb_master_bfm_v1_00_a /opt/Xilinx/EDK_Lib/plb_master_bfm_v1_00_a/
vmap plb_slave_bfm_v1_00_a /opt/Xilinx/EDK_Lib/plb_slave_bfm_v1_00_a/
vmap plb_monitor_bfm_v1_00_a /opt/Xilinx/EDK_Lib/plb_monitor_bfm_v1_00_a/
vmap bfm_synch_v1_00_a /opt/Xilinx/EDK_Lib/bfm_synch_v1_00_a/
vmap proc_common_v1_00_b /opt/Xilinx/EDK_Lib/proc_common_v1_00_b/
vmap plb_v34_v1_02_a /opt/Xilinx/EDK_Lib/plb_v34_v1_02_a/
vmap ipif_common_v1_00_e /opt/Xilinx/EDK_Lib/ipif_common_v1_00_e/
vmap dre_v1_00_a /opt/Xilinx/EDK_Lib/dre_v1_00_a/
vmap plb_ipif_v2_01_a /opt/Xilinx/EDK_Lib/plb_ipif_v2_01_a/
vlib osif_tb_v1_00_c
vmap osif_tb_v1_00_c osif_tb_v1_00_c
vlib work
vmap work work
vcom -93 -work work bfm_processor_wrapper.vhd
vcom -93 -work work bfm_memory_wrapper.vhd
vcom -93 -work work bfm_monitor_wrapper.vhd
vcom -93 -work work synch_bus_wrapper.vhd
vcom -93 -work work plb_bus_wrapper.vhd
vcom -93 -work osif_tb_v1_00_c ../../pcores/osif_tb_v1_00_c/simhdl/vhdl/osif_tb.vhd
#%%%
vcom -93 -work work my_core_wrapper.vhd
vcom -93 -work work bfm_system.vhd
