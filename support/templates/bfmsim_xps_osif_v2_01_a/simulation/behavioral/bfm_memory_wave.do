#  Simulation Model Generator
#  Xilinx EDK 9.2.02 EDK_Jm_SP2.3
#  Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
#
#  File     bfm_memory_wave.do (Fri Jul 24 13:41:05 2009)
#
#  Module   bfm_memory_wrapper
#  Instance bfm_memory
#  Because EDK did not create the testbench, the user
#  specifies the path to the device under test, $tbpath.
#
set binopt {-logic}
set hexopt {-literal -hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }

  eval add wave -noupdate -divider {"bfm_memory"}
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_CLK
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_RESET
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}SYNCH_OUT
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}SYNCH_IN
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_PAValid
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_SAValid
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_rdPrim
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_wrPrim
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_masterID
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_abort
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_busLock
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_RNW
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_BE
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_msize
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_size
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_type
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_TAttribute
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_lockErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_UABus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_ABus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_wrDBus
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_wrBurst
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_rdBurst
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_rdpendReq
# eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}PLB_wrpendReq
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_rdpendPri
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_wrpendPri
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}PLB_reqPri
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_addrAck
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}Sl_ssize
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_wait
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_rearbitrate
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_wrDAck
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_wrComp
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_wrBTerm
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}Sl_rdDBus
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}Sl_rdWdAddr
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_rdDAck
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_rdComp
  eval add wave -noupdate $binopt $tbpath${ps}bfm_memory${ps}Sl_rdBTerm
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}Sl_MBusy
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}Sl_MRdErr
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}Sl_MWrErr
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_memory${ps}Sl_MIRQ

