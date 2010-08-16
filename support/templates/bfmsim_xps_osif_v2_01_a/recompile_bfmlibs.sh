#!/usr/bin/env bash
vcom -93 -novopt -quiet -work plbv46_bfm -f $EDK_LIB/CompileListFiles/plbv46_bfm_compile_order
vcom -93 -novopt -quiet -work plbv46_slave_bfm_v1_00_a -f $EDK_LIB/CompileListFiles/plbv46_slave_bfm_v1_00_a_compile_order
vcom -93 -novopt -quiet -work plbv46_master_bfm_v1_00_a -f $EDK_LIB/CompileListFiles/plbv46_master_bfm_v1_00_a_compile_order
