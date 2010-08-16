onerror {resume}
quietly WaveActivateNextPane {} 0

echo  "Setting up Wave window display ..."

if { ![info exists xcmdc] } {echo "Warning : c compile command was not run"}
if { ![info exists xcmds] } {echo "Warning : s simulate command was not run"}

#  Because EDK did not create the testbench, the user
#  specifies the path to the device under test, $tbpath.
#
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }

#
#  Display top-level ports
#
set binopt {-logic}
set hexopt {-literal -hex}
eval add wave -noupdate -divider {"top-level ports"}
eval add wave -noupdate $binopt $tbpath${ps}sys_reset
eval add wave -noupdate $binopt $tbpath${ps}sys_clk

#
# MYCORE Signals
#
set binopt {-logic}
set hexopt {-literal -hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }
eval add wave -noupdate -divider {"my_core: DCR signals"}
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}dcrABus
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}dcrDBus_out
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}dcrWrite
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}dcrRead
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}dcrDBus_in
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}busy_local
eval add wave -noupdate -divider {"my_core: memplb signals"}
 eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}Bus2IP_MstRd_src_rdy_n
 eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}Bus2IP_MstRd_eof_n
 eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}ll_sm_state
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}ll_sm_rd_dst_rdy    
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}o_burstWE
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstBE 
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstBurst
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstRdReq
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstWrReq 
eval add wave -noupdate -divider {"my_core: LocalLink WriteBackend"}
 eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstWr_d
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstWr_sof_n
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstWr_eof_n
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstWr_src_rdy_n
eval add wave -noupdate -divider {"my_core: LocalLink ReadBackend"}
 eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}IP2Bus_MstRd_dst_rdy_n
 eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}mem_plb46_i${ps}Bus2IP_MstRd_d
 
eval add wave -noupdate -divider {"OSIF_NEW signals"}
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}osif_os2task_vec
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}osif_task2os_vec
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}busy
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}blocking
  eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}o_dcrAck
eval add wave -noupdate -divider {"USERLOGIC signals"}
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}sys_clk
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}sys_reset
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}osif_os2task_vec
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}osif_task2os_vec
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}busy
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}blocking
eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}i_mem_busy
eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}slv_busy
#eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}
eval add wave -noupdate -divider {"USERLOGIC->COMMAND_DECODER signals"}
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}i_clk
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}i_reset
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}i_osif
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}o_osif
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}i_init_data
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}i_slv_bus2osif_command
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}i_slv_bus2osif_data
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}i_slv_bus2osif_shm
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}o_slv_osif2bus_command
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}o_slv_osif2bus_data
  eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}uut${ps}user_logic_i${ps}command_decoder_inst${ps}o_slv_osif2bus_shm
eval add wave -noupdate -divider {"my_core plb signals"}
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}MPLB_Clk
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}MPLB_Rst
# eval add wave -noupdate $binopt $tbpath${ps}my_core${ps}MD_error
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

#
# Testmutex Signals
#
set binopt {-logic}
set hexopt {-literal -hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "${ps}bfm_system" }
eval add wave -noupdate -divider {"Testmutex signals"}
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}task_0_inst${ps}clk
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}task_0_inst${ps}reset
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}task_0_inst${ps}i_osif
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}task_0_inst${ps}o_osif
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}task_0_inst${ps}state
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}task_0_inst${ps}in_value
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}task_0_inst${ps}out_value
eval add wave -noupdate $hexopt $tbpath${ps}my_core${ps}my_core${ps}task_0_inst${ps}init_data
#
#  Display bus signal ports
#
do plb_v46_0_wave.do


TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {763867 ps} 0}
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {0 ps} {2 us}
