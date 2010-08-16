#  Simulation Model Generator
#  Xilinx EDK 9.2.02 EDK_Jm_SP2.3
#  Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
#
#  File     plb_bus_wave.do (Fri Jul 24 13:41:05 2009)
#
#  Module   plb_bus_wrapper
#  Instance plb_bus
#  Because EDK did not create the testbench, the user
#  specifies the path to the device under test, $tbpath.
#
set binopt {-logic}
set hexopt {-literal -hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }

  eval add wave -noupdate -divider {"plb_bus"}
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_Clk
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}SYS_Rst
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_Rst
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}SPLB_Rst
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}MPLB_Rst
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_dcrAck
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_dcrDBus
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}DCR_ABus
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}DCR_DBus
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}DCR_Read
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}DCR_Write
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_ABus
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_UABus
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_BE
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_RNW
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_abort
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_busLock
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_TAttribute
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_lockErr
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_MSize
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_priority
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_rdBurst
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_request
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_size
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_type
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_wrBurst
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}M_wrDBus
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_addrAck
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}Sl_MRdErr
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}Sl_MWrErr
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}Sl_MBusy
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_rdBTerm
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_rdComp
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_rdDAck
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}Sl_rdDBus
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}Sl_rdWdAddr
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_rearbitrate
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}Sl_SSize
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_wait
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_wrBTerm
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_wrComp
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Sl_wrDAck
# eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}Sl_MIRQ
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MIRQ
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_ABus
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_UABus
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_BE
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MAddrAck
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MTimeout
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MBusy
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MRdErr
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MWrErr
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MRdBTerm
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MRdDAck
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MRdDBus
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MRdWdAddr
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MRearbitrate
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MWrBTerm
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MWrDAck
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MSSize
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_PAValid
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_RNW
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_SAValid
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_abort
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_busLock
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_TAttribute
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_lockErr
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_masterID
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_MSize
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_rdPendPri
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_wrPendPri
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_rdPendReq
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_wrPendReq
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_rdBurst
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_rdPrim
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_reqPri
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_size
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_type
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_wrBurst
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_wrDBus
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_wrPrim
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_SaddrAck
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_SMRdErr
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_SMWrErr
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_SMBusy
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_SrdBTerm
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_SrdComp
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_SrdDAck
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_SrdDBus
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_SrdWdAddr
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_Srearbitrate
  eval add wave -noupdate $hexopt $tbpath${ps}plb_bus${ps}PLB_Sssize
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_Swait
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_SwrBTerm
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_SwrComp
  eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB_SwrDAck
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}PLB2OPB_rearb
# eval add wave -noupdate $binopt $tbpath${ps}plb_bus${ps}Bus_Error_Det

