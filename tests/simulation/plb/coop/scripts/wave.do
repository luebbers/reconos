onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {System Level Ports}
add wave -noupdate -format Logic /bfm_system/sys_clk
add wave -noupdate -format Logic /bfm_system/sys_reset
add wave -noupdate -divider {PLB Bus Master Signals}
add wave -noupdate -format Literal /bfm_system/plb_bus_m_abort
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_abus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_be
add wave -noupdate -format Literal /bfm_system/plb_bus_m_buslock
add wave -noupdate -format Literal /bfm_system/plb_bus_m_compress
add wave -noupdate -format Literal /bfm_system/plb_bus_m_guarded
add wave -noupdate -format Literal /bfm_system/plb_bus_m_lockerr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_msize
add wave -noupdate -format Literal /bfm_system/plb_bus_m_ordered
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_priority
add wave -noupdate -format Literal /bfm_system/plb_bus_m_rdburst
add wave -noupdate -format Literal /bfm_system/plb_bus_m_request
add wave -noupdate -format Literal /bfm_system/plb_bus_m_rnw
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_size
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_type
add wave -noupdate -format Literal /bfm_system/plb_bus_m_wrburst
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_wrdbus
add wave -noupdate -format Literal /bfm_system/plb_bus_plb_mbusy
add wave -noupdate -format Literal /bfm_system/plb_bus_plb_merr
add wave -noupdate -format Literal /bfm_system/plb_bus_plb_mwrbterm
add wave -noupdate -format Literal /bfm_system/plb_bus_plb_mwrdack
add wave -noupdate -format Literal /bfm_system/plb_bus_plb_maddrack
add wave -noupdate -format Literal /bfm_system/plb_bus_plb_mrdbterm
add wave -noupdate -format Literal /bfm_system/plb_bus_plb_mrddack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mrddbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mrdwdaddr
add wave -noupdate -format Literal /bfm_system/plb_bus_plb_mrearbitrate
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mssize
add wave -noupdate -divider {PLB Bus Slave Signals}
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_addrack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_mbusy
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_merr
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_rdbterm
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_rdcomp
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_rddack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_rddbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_rdwdaddr
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_rearbitrate
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_ssize
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_wait
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_wrbterm
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_wrcomp
add wave -noupdate -format Literal /bfm_system/plb_bus_sl_wrdack
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_abort
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_abus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_be
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_buslock
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_compress
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_guarded
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_lockerr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_masterid
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_msize
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_ordered
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_pavalid
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_pendpri
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_pendreq
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_rdburst
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_rdprim
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_reqpri
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_rnw
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_savalid
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_size
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_type
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_wrburst
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_wrdbus
add wave -noupdate -format Logic /bfm_system/plb_bus_plb_wrprim
add wave -noupdate -divider {BFM Synch Bus Signals}
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/synch_bus/synch_bus/from_synch_out
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/synch_bus/synch_bus/to_synch_in
add wave -noupdate -divider {OSIF Signals}
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_clk
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_rst
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_addrack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/sl_mbusy
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/sl_merr
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_rdbterm
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_rdcomp
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_rddack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/sl_rddbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/sl_rdwdaddr
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_rearbitrate
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/sl_ssize
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_wait
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_wrbterm
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_wrcomp
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/sl_wrdack
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_abort
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_abus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_be
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_buslock
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_compress
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_guarded
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_lockerr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_masterid
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_msize
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_ordered
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_pavalid
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_pendpri
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_pendreq
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_rdburst
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_rdprim
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_reqpri
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_rnw
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_savalid
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_size
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_type
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_wrburst
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_wrdbus
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_wrprim
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_abort
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_abus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_be
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_buslock
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_compress
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_guarded
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_lockerr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_msize
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_ordered
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_priority
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_rdburst
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_request
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_rnw
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_size
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_type
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/m_wrburst
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_wrdbus
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_mbusy
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_merr
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_mwrbterm
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_mwrdack
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_maddrack
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_mrdbterm
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_mrddack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrddbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrdwdaddr
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/plb_mrearbitrate
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mssize
add wave -noupdate -divider {User Logic Interface Signals}
add wave -noupdate -divider {OSIF Slave Space Signals}
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/slv_osif2bus_command
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/slv_osif2bus_data
add wave -noupdate -divider {OSIF Master Space Signals}
add wave -noupdate -format Literal /bfm_system/my_core/my_core/task_0_inst/state
add wave -noupdate -divider {DCR signals}
add wave -noupdate -format Logic /bfm_system/my_core/my_core/dcrack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/dcrdbus_in
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/dcrabus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/dcrdbus_out
add wave -noupdate -format Logic /bfm_system/my_core/my_core/dcrread
add wave -noupdate -format Logic /bfm_system/my_core/my_core/dcrwrite
add wave -noupdate -divider {OSIF User Logic signals}
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/interrupt
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/busy
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/blocking
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/o_bm_enable
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/osif_task2os
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/o_osif
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/osif_os2task
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/i_osif
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/reset_counter
add wave -noupdate -divider {OSIF command decoder signals}
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_clk
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_sw_request
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_request_blocking
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_release_blocking
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_bm_my_addr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_bm_target_addr
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_bm_read_req
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_bm_write_req
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_bm_burst_read_req
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_bm_burst_write_req
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_bm_busy
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_bm_read_done
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_bm_write_done
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_slv_busy
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_slv_bus2osif_shm
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_slv_osif2bus_command
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_slv_osif2bus_data
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/o_slv_osif2bus_shm
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/step_enable
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/step_clear
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/step
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_resume
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_resume_state_enc
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/user_logic_i/command_decoder_inst/i_resume_step_enc
add wave -noupdate -divider {burst RAM signals}
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/clka
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/wea
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/ena
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/addra
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/dina
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/douta
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/clkax
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/weax
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/enax
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/addrax
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/dinax
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/doutax
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/clkb
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/web
add wave -noupdate -format Logic /bfm_system/my_core/my_core/burst_ram_i/enb
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/beb
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/addrb
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/dinb
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/burst_ram_i/doutb
add wave -noupdate -divider {user thread signals}
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/o_ramaddr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/o_ramdata
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/i_ramdata
add wave -noupdate -format Logic /bfm_system/my_core/my_core/task_0_inst/o_ramwe
add wave -noupdate -format Logic /bfm_system/my_core/my_core/task_0_inst/o_ramclk
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/state
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
WaveRestoreZoom {0 ps} {31064608 ps}
