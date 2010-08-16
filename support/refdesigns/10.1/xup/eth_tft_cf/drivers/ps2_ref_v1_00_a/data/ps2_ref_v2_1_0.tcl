#     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
#     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR
#     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION
#     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION
#     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS
#     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
#     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
#     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
#     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
#     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
#     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
#     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#     FOR A PARTICULAR PURPOSE.
#     
#     (c) Copyright 2004 Xilinx, Inc.
#     All rights reserved.

#uses "xillib.tcl"

proc generate {drv_handle} {
    set level [xget_value $drv_handle "PARAMETER" "level"]
    puts "ps2 driver level = $level"
    if {$level == 0} {
	#xdefine_include_file $drv_handle "xparameters.h" "XPs2" "NUM_INSTANCES" "C_BASEADDR" "C_HIGHADDR"
	
	# Open include file
	set file_handle [xopen_include_file "xparameters.h"]
	
	# Get all peripherals connected to this driver
	set periphs [xget_periphs $drv_handle] 
	
	# Define NUM_INSTANCES
	set arg "NUM_INSTANCES"
	set double_instances [expr 2*[llength $periphs]]
	#puts "DEBUG: #define [xget_dname "XPs2" $arg] $double_instances"
	puts $file_handle "#define [xget_dname "XPs2" $arg] $double_instances"
	
	# Print all parameters for all peripherals
	foreach periph $periphs {
	    set baseaddr [xget_param_value $periph "C_BASEADDR"]
	    puts $file_handle "#define [xget_name $periph C_BASEADDR]_0 $baseaddr"
	    puts $file_handle [format "%s (%s+%s)" "#define [xget_name $periph C_HIGHADDR]_0" $baseaddr "0x3F"]
	    puts $file_handle [format "%s (%s+%s)" "#define [xget_name $periph C_BASEADDR]_1" $baseaddr "0x1000"]
	    puts $file_handle [format "%s (%s+%s)" "#define [xget_name $periph C_HIGHADDR]_1" $baseaddr "0x103F"]
	}
	
	#puts "\n/******************************************************************/\n"
	puts $file_handle "\n/******************************************************************/\n"
	close $file_handle
    }
    
    if {$level == 1} {
	# Open include file
	set file_handle [xopen_include_file "xparameters.h"]
	
	# Get all peripherals connected to this driver
	set periphs [xget_periphs $drv_handle] 
	
	# Define NUM_INSTANCES
	set arg "NUM_INSTANCES"
	set double_instances [expr 2*[llength $periphs]]
	puts $file_handle "#define [xget_dname "XPs2" $arg] $double_instances"
	
	# Print all parameters for all peripherals
	set device_id 0
	foreach periph $periphs {
	    set baseaddr [xget_param_value $periph "C_BASEADDR"]
	    puts $file_handle "#define [xget_name $periph DEVICE_ID]_0 $device_id"
	    puts $file_handle "#define [xget_name $periph C_BASEADDR]_0 $baseaddr"
	    puts $file_handle [format "%s (%s+%s)" "#define [xget_name $periph C_HIGHADDR]_0" $baseaddr "0x3F"]
	    incr device_id

	    puts $file_handle "#define [xget_name $periph DEVICE_ID]_1 $device_id"
	    puts $file_handle [format "%s (%s+%s)" "#define [xget_name $periph C_BASEADDR]_1" $baseaddr "0x1000"]
	    puts $file_handle [format "%s (%s+%s)" "#define [xget_name $periph C_HIGHADDR]_1" $baseaddr "0x103F"]
	    incr device_id
	}
	
	#puts "\n/******************************************************************/\n"
	puts $file_handle "\n/******************************************************************/\n"
	close $file_handle
	
	set filename [file join "src" "xps2_g.c"] 
	file delete $filename
	set config_file [open $filename w]
	xprint_generated_header $config_file "Driver configuration"
	puts $config_file "#include \"xparameters.h\""
	puts $config_file "#include \"xps2.h\""
	puts $config_file "\n/*"
	puts $config_file "* The configuration table for devices"
	puts $config_file "*/\n"
	puts $config_file [format "%s_Config %s_ConfigTable\[\] =" "XPs2" "XPs2"]
	puts $config_file "\{"
	# these are the defines we would like to have

	set periphs [xget_periphs $drv_handle]     
	set cfg_entry "\t{\n\t\t%s,\n\t\t%s\n\t},"
	foreach periph $periphs {
	    set name [xget_name $periph DEVICE_ID]
	    set baseaddr [xget_name $periph C_BASEADDR]
	    puts $config_file [format $cfg_entry "${name}_0" "${baseaddr}_0"]
	    puts $config_file [format $cfg_entry "${name}_1" "${baseaddr}_1"]
	}

	puts $config_file "\};"
	close $config_file
    }
}
