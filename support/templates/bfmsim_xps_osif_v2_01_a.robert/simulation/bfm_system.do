#  Simulation Model Generator
#  Xilinx EDK 10.1.03 EDK_K_SP3.6
#  Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.
#
#  File     bfm_system.do (Tue Jun 30 10:28:23 2009)
#
vmap XilinxCoreLib "/Xilinx/simlib/10.1/ISE_Lib/XilinxCoreLib/"
vmap XilinxCoreLib_ver "/Xilinx/simlib/10.1/ISE_Lib/XilinxCoreLib_ver/"
vmap secureip "/Xilinx/simlib/10.1/ISE_Lib/secureip/"
vmap simprim "/Xilinx/simlib/10.1/ISE_Lib/simprim/"
vmap simprims_ver "/Xilinx/simlib/10.1/ISE_Lib/simprims_ver/"
vmap unisim "/Xilinx/simlib/10.1/ISE_Lib/unisim/"
vmap unisims_ver "/Xilinx/simlib/10.1/ISE_Lib/unisims_ver/"
vmap bfm_synch_v1_00_a "/Xilinx/simlib/10.1/EDK_Lib/bfm_synch_v1_00_a/"
vmap proc_common_v2_00_a "/Xilinx/simlib/10.1/EDK_Lib/proc_common_v2_00_a/"
vmap plb_v46_v1_03_a "/Xilinx/simlib/10.1/EDK_Lib/plb_v46_v1_03_a/"
vmap plbv46_bfm "/Xilinx/simlib/10.1/EDK_Lib/plbv46_bfm/"
vmap plbv46_slave_bfm_v1_00_a "/Xilinx/simlib/10.1/EDK_Lib/plbv46_slave_bfm_v1_00_a/"
vmap plbv46_monitor_bfm_v1_00_a "/Xilinx/simlib/10.1/EDK_Lib/plbv46_monitor_bfm_v1_00_a/"
vmap plbv46_master_bfm_v1_00_a "/Xilinx/simlib/10.1/EDK_Lib/plbv46_master_bfm_v1_00_a/"
vmap plbv46_master_burst_v1_00_a "/Xilinx/simlib/10.1/EDK_Lib/plbv46_master_burst_v1_00_a/"

vlib osif_tb_v1_00_c
vmap osif_tb_v1_00_c osif_tb_v1_00_c
vlib work
vmap work work
vcom -93 -work osif_tb_v1_00_c /home/rmeiche/reconos/trunk/hw/templates/coregen/fifo/fifo.vhd
vcom -93 -work osif_tb_v1_00_c ../test_mutex.vhd
vcom -novopt -93 -work osif_tb_v1_00_c "../../pcores/osif_tb_v1_00_c/simhdl/vhdl/osif_tb.vhd"
vcom -novopt -93 -work work "synch_bus_wrapper.vhd"
vcom -novopt -93 -work work "plb_v46_0_wrapper.vhd"
vcom -novopt -93 -work work "bfm_memory_wrapper.vhd"
vcom -novopt -93 -work work "bfm_monitor_wrapper.vhd"
vcom -novopt -93 -work work "bfm_processor_wrapper.vhd"
vcom -novopt -93 -work work "my_core_wrapper.vhd"
vcom -novopt -93 -work work "bfm_system.vhd"
