#  Simulation Model Generator
#  Xilinx EDK 9.2.02 EDK_Jm_SP2.3
#  Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
#
#  File     synch_bus_list.do (Fri Jul 24 13:41:05 2009)
#
#  Module   synch_bus_wrapper
#  Instance synch_bus
#  Because EDK did not create the testbench, the user
#  specifies the path to the device under test, $tbpath.
#
set binopt {-bin}
set hexopt {-hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }

  eval add list $hexopt $tbpath${ps}synch_bus${ps}FROM_SYNCH_OUT
  eval add list $hexopt $tbpath${ps}synch_bus${ps}TO_SYNCH_IN

