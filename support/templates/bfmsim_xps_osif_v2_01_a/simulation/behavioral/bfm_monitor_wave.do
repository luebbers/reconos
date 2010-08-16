#  Simulation Model Generator
#  Xilinx EDK 9.2.02 EDK_Jm_SP2.3
#  Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
#
#  File     bfm_monitor_wave.do (Fri Jul 24 13:41:05 2009)
#
#  Module   bfm_monitor_wrapper
#  Instance bfm_monitor
#  Because EDK did not create the testbench, the user
#  specifies the path to the device under test, $tbpath.
#
set binopt {-logic}
set hexopt {-literal -hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }

  eval add wave -noupdate -divider {"bfm_monitor"}
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_CLK
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_RESET
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}SYNCH_OUT
  eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}SYNCH_IN
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_request
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_priority
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_buslock
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_RNW
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_BE
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_msize
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_size
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_type
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_TAttribute
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_lockErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_abort
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_UABus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_ABus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_wrDBus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_wrBurst
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}M_rdBurst
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MAddrAck
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MRearbitrate
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MTimeout
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MBusy
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MRdErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MWrErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MIRQ
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MWrDAck
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MRdDBus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MRdWdAddr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MRdDAck
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MRdBTerm
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_MWrBTerm
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_Mssize
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_PAValid
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_SAValid
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_rdPrim
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_wrPrim
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_MasterID
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_abort
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_busLock
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_RNW
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_BE
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_msize
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_size
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_type
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_TAttribute
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_lockErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_UABus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_ABus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_wrDBus
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_wrBurst
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_rdBurst
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_rdpendReq
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_wrpendReq
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_rdpendPri
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_wrpendPri
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_reqPri
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_addrAck
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_wait
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_rearbitrate
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_wrDAck
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_wrComp
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_wrBTerm
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}Sl_rdDBus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}Sl_rdWdAddr
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_rdDAck
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_rdComp
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}Sl_rdBTerm
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}Sl_MBusy
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}Sl_MRdErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}Sl_MWrErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}Sl_MIRQ
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}Sl_ssize
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_SaddrAck
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_Swait
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_Srearbitrate
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_SwrDAck
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_SwrComp
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_SwrBTerm
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_SrdDBus
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_SrdWdAddr
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_SrdDAck
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_SrdComp
# eval add wave -noupdate $binopt $tbpath${ps}bfm_monitor${ps}PLB_SrdBTerm
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_SMBusy
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_SMRdErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_SMWrErr
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_SMIRQ
# eval add wave -noupdate $hexopt $tbpath${ps}bfm_monitor${ps}PLB_Sssize

