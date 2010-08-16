#  Simulation Model Generator
#  Xilinx EDK 9.2.02 EDK_Jm_SP2.3
#  Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
#
#  File     my_core_wave.do (Fri Jul 24 13:41:05 2009)
#
#  Module   my_core_wrapper
#  Instance my_core
#  Because EDK did not create the testbench, the user
#  specifies the path to the device under test, $tbpath.
#
set binopt {-logic}
set hexopt {-literal -hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }

  eval add wave -noupdate -divider {"my_core"}
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}MPLB_Clk
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}MPLB_Rst
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}M_request
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_priority
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}M_busLock
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}M_RNW
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_BE
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_MSize
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_size
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_type
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_TAttribute
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}M_lockErr
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}M_abort
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_UABus
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_ABus
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}M_wrDBus
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}M_wrBurst
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}M_rdBurst
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MAddrAck
# eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}PLB_MSSize
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MRearbitrate
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MTimeout
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MBusy
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MRdErr
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MWrErr
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MIRQ
# eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}PLB_MRdDBus
# eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}PLB_MRdWdAddr
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MRdDAck
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MRdBTerm
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MWrDAck
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}PLB_MWrBTerm
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}SYNCH_IN
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}SYNCH_OUT

