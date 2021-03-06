onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {BFM System Level Ports}
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/sys_clk
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/sys_reset
add wave -noupdate -divider {PLBv46 Bus Master Signals}
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_request
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_priority
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_buslock
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_rnw
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_be
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_msize
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_size
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_type
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_tattribute
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_lockerr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_abort
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_uabus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_abus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_wrdbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_wrburst
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_m_rdburst
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_maddrack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mssize
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mrearbitrate
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mtimeout
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mbusy
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mrderr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mwrerr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mirq
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mrddbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mrdwdaddr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mrddack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mrdbterm
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mwrdack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_mwrbterm
add wave -noupdate -divider {PLBv46 Bus Slave Signals}
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_abus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_uabus
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_pavalid
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_savalid
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_rdprim
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_wrprim
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_masterid
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_abort
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_buslock
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_rnw
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_be
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_msize
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_size
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_type
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_lockerr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_wrdbus
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_wrburst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_rdburst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_wrpendreq
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/plb_bus_plb_rdpendreq
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_wrpendpri
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_rdpendpri
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_reqpri
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_plb_tattribute
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_addrack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_ssize
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_wait
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_rearbitrate
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_wrdack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_wrcomp
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_wrbterm
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_rddbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_rdwdaddr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_rddack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_rdcomp
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_rdbterm
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_mbusy
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_mwrerr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_mrderr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/plb_bus_sl_mirq
add wave -noupdate -divider {BFM Synch Bus Signals}
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/synch_bus/synch_bus/from_synch_out
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/synch_bus/synch_bus/to_synch_in
add wave -noupdate -divider {xps_osif Peripheral Interface Signals}
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mplb_clk
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mplb_rst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/md_error
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_request
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_priority
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_buslock
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_rnw
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_be
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_msize
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_size
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_type
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_tattribute
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_lockerr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_abort
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_uabus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_abus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_wrdbus
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_wrburst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_rdburst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_maddrack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mssize
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrearbitrate
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mtimeout
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mbusy
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrderr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mwrerr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mirq
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrddbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrdwdaddr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrddack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrdbterm
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mwrdack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mwrbterm
add wave -noupdate -divider {Peripheral Internal Signals}
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstrd_req
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_req
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_addr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_length
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_be
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_type
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_lock
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_reset
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_cmdack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_cmplt
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_error
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_rearbitrate
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_cmd_timeout
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_d
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_rem
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_sof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_eof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_src_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_src_dsc_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstrd_dst_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstrd_dst_dsc_n
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_d
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_rem
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_sof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_eof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_src_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_src_dsc_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstwr_dst_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstwr_dst_dsc_n
add wave -noupdate -divider {User Logic Interface Signals}
add wave -noupdate -divider {User Logic Internal Master Space Signals}
add wave -noupdate -divider OSIF
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/interrupt
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/busy
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/blocking
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/task_clk
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/task_reset
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/osif_os2task_vec
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/osif_task2os_vec
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/burstaddr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/burstwrdata
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/burstrddata
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/burstwe
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/burstbe
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifo_clk
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifo_reset
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifo_read_en
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/fifo_read_data
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifo_read_ready
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifo_write_en
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/fifo_write_data
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifo_write_ready
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/bmenable
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/o_dcrack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/o_dcrdbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/i_dcrabus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/i_dcrdbus
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/i_dcrread
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/i_dcrwrite
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/i_dcricon
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mplb_clk
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mplb_rst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/md_error
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_request
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_priority
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_buslock
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_rnw
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_be
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_msize
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_size
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_type
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_tattribute
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_lockerr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_abort
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_uabus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_abus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/m_wrdbus
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_wrburst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/m_rdburst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_maddrack
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mssize
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrearbitrate
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mtimeout
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mbusy
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrderr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mwrerr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mirq
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrddbus
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrdwdaddr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrddack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mrdbterm
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mwrdack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/plb_mwrbterm
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstrd_req
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_req
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_addr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_length
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_be
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_type
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_lock
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mst_reset
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_cmdack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_cmplt
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_error
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_rearbitrate
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mst_cmd_timeout
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_d
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_rem
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_sof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_eof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_src_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstrd_src_dsc_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstrd_dst_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstrd_dst_dsc_n
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_d
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_rem
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_sof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_eof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_src_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_ip2bus_mstwr_src_dsc_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstwr_dst_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/ipif_bus2ip_mstwr_dst_dsc_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/task_clk_internal
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/task_reset_internal
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem2osif_singledata
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/osif2mem_singledata
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_localaddr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_targetaddr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_singlerdreq
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_singlewrreq
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_burstrdreq
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_burstwrreq
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_burstlen
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_busy
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_rddone
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_wrdone
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifomgr_read_remove
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/fifomgr_read_data
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifomgr_read_wait
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifomgr_write_add
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/fifomgr_write_data
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/fifomgr_write_wait
add wave -noupdate -divider mem_plbv46
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/clk
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/reset
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/o_burstaddr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/o_burstdata
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_burstdata
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/o_burstwe
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/o_burstbe
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_singledata
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/o_singledata
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_localaddr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_targetaddr
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_singlerdreq
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_singlewrreq
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_burstrdreq
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_burstwrreq
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/i_burstlen
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/o_busy
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/o_rddone
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/o_wrdone
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_clk
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_reset
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_msterror
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstlastack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstrdack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstwrack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstretry
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_msttimeout
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mst_cmdack
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mst_cmplt
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mst_error
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mst_cmd_timeout
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_addr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstbe
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstburst
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstbusreset
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstbuslock
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstnum
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstrdreq
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstwrreq
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstrd_d
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstrd_rem
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstrd_sof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstrd_eof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstrd_src_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstrd_src_dsc_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstrd_dst_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstrd_dst_dsc_n
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstwr_d
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstwr_rem
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstwr_sof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstwr_eof_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstwr_src_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/ip2bus_mstwr_src_dsc_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstwr_dst_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstwr_dst_dsc_n
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_state
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_set_done
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_set_error
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_set_timeout
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_busy
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_clr_go
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_rd_req
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_wr_req
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_reset
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_bus_lock
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_ip2bus_addr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_ip2bus_be
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_xfer_type
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_xfer_length
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_start_rd_llink
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cmd_sm_start_wr_llink
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_llrd_sm_state
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_llrd_sm_dst_rdy
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_llwr_sm_state
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_llwr_sm_src_rdy
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_llwr_sm_sof
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_llwr_sm_eof
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_llwr_byte_cnt
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bram_offset
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_fifo_valid_write_xfer
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_fifo_valid_read_xfer
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_xfer_length
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cntl_rd_req
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cntl_wr_req
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cntl_bus_lock
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_cntl_burst
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_ip2bus_addr
add wave -noupdate -format Literal -radix binary /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_ip2bus_be
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/bus2ip_mstrd_d
add wave -noupdate -format Literal -radix binary /bfm_system/my_core/my_core/uut/mem_plb46_i/rolled_mst_ip2bus_be
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/rolled_MstRd_d
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/uut/mem_plb46_i/mst_go
add wave -noupdate -format Logic /bfm_system/my_core/my_core/uut/mem_plb46_i/xfer_cross_wrd_bndry
add wave -noupdate -divider Thread
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/clk
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/reset
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/i_osif
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/o_osif
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/o_ramaddr
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/o_ramdata
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/i_ramdata
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/o_ramwe
add wave -noupdate -format Logic -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/o_ramclk
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/state
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/in_value
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/out_value
add wave -noupdate -format Literal -radix hexadecimal /bfm_system/my_core/my_core/task_0_inst/init_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2190000 ps} 0}
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
WaveRestoreZoom {1952011 ps} {2517757 ps}
