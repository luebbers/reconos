#  Simulation Model Generator
#  Xilinx EDK 8.2.02 EDK_Im_Sp2.4
#  Copyright (c) 1995-2006 Xilinx, Inc.  All rights reserved.
#
#  File     bfm_memory_list.do (Thu Feb 15 13:04:30 2007)
#
#  Module   bfm_memory_wrapper
#  Instance bfm_memory
#  Because EDK did not create the testbench, the user
#  specifies the path to the device under test, $tbpath.
#
set binopt {-bin}
set hexopt {-hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }

# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_CLK
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_RESET
  eval add list $hexopt $tbpath${ps}bfm_memory${ps}SYNCH_OUT
  eval add list $hexopt $tbpath${ps}bfm_memory${ps}SYNCH_IN
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_PAValid
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_SAValid
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_rdPrim
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_wrPrim
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_masterID
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_abort
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_busLock
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_RNW
# eval add list $hexopt $tbpath${ps}bfm_memory${ps}PLB_BE
# eval add list $hexopt $tbpath${ps}bfm_memory${ps}PLB_msize
# eval add list $hexopt $tbpath${ps}bfm_memory${ps}PLB_size
# eval add list $hexopt $tbpath${ps}bfm_memory${ps}PLB_type
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_compress
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_guarded
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_ordered
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_lockErr
# eval add list $hexopt $tbpath${ps}bfm_memory${ps}PLB_ABus
# eval add list $hexopt $tbpath${ps}bfm_memory${ps}PLB_wrDBus
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_wrBurst
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_rdBurst
# eval add list $binopt $tbpath${ps}bfm_memory${ps}PLB_pendReq
# eval add list $hexopt $tbpath${ps}bfm_memory${ps}PLB_pendPri
# eval add list $hexopt $tbpath${ps}bfm_memory${ps}PLB_reqPri
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_addrAck
  eval add list $hexopt $tbpath${ps}bfm_memory${ps}Sl_ssize
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_wait
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_rearbitrate
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_wrDAck
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_wrComp
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_wrBTerm
  eval add list $hexopt $tbpath${ps}bfm_memory${ps}Sl_rdDBus
  eval add list $hexopt $tbpath${ps}bfm_memory${ps}Sl_rdWdAddr
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_rdDAck
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_rdComp
  eval add list $binopt $tbpath${ps}bfm_memory${ps}Sl_rdBTerm
  eval add list $hexopt $tbpath${ps}bfm_memory${ps}Sl_MBusy
  eval add list $hexopt $tbpath${ps}bfm_memory${ps}Sl_MErr

