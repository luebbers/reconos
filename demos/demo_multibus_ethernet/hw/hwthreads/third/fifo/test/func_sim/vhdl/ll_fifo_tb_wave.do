onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /ll_fifo_tb/rst
add wave -noupdate -divider {Tester Signals}
add wave -noupdate -format Logic /ll_fifo_tb/tester_clk
add wave -noupdate -format Logic /ll_fifo_tb/working
add wave -noupdate -format Logic /ll_fifo_tb/comparing
add wave -noupdate -format Logic /ll_fifo_tb/overflow
add wave -noupdate -color Magenta -format Logic /ll_fifo_tb/result_good
add wave -noupdate -color Magenta -format Logic /ll_fifo_tb/result_good_pdu
add wave -noupdate -format Literal /ll_fifo_tb/tx_d
add wave -noupdate -format Literal /ll_fifo_tb/tx_rem
add wave -noupdate -format Logic /ll_fifo_tb/tx_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/tx_eof_n
add wave -noupdate -format Logic /ll_fifo_tb/tx_src_rdy_n
add wave -noupdate -format Logic /ll_fifo_tb/tx_dst_rdy_n
add wave -noupdate -format Logic /ll_fifo_tb/src_rdy_n_ref_i
add wave -noupdate -format Literal /ll_fifo_tb/rx_d
add wave -noupdate -format Literal /ll_fifo_tb/rx_rem
add wave -noupdate -format Logic /ll_fifo_tb/rx_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/rx_eof_n
add wave -noupdate -format Logic /ll_fifo_tb/rx_src_rdy_n
add wave -noupdate -format Literal /ll_fifo_tb/tv
add wave -noupdate -divider {Loopback IF Signals}
add wave -noupdate -format Logic /ll_fifo_tb/loopback_clk
add wave -noupdate -format Literal /ll_fifo_tb/eloopback_data
add wave -noupdate -format Literal /ll_fifo_tb/eloopback_rem
add wave -noupdate -format Logic /ll_fifo_tb/eloopback_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/eloopback_eof_n
add wave -noupdate -format Logic /ll_fifo_tb/eloopback_src_rdy_n
add wave -noupdate -format Logic /ll_fifo_tb/eloopback_dst_rdy_n
add wave -noupdate -format Literal /ll_fifo_tb/iloopback_data
add wave -noupdate -format Literal /ll_fifo_tb/iloopback_rem
add wave -noupdate -format Logic /ll_fifo_tb/iloopback_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/iloopback_eof_n
add wave -noupdate -format Logic /ll_fifo_tb/iloopback_src_rdy_n
add wave -noupdate -format Logic /ll_fifo_tb/iloopback_dst_rdy_n
add wave -noupdate -format Literal /ll_fifo_tb/loopback_throttle_cnt
add wave -noupdate -format Logic /ll_fifo_tb/loopback_throttle
add wave -noupdate -format Literal /ll_fifo_tb/loopback_throttle_th
add wave -noupdate -divider {Other LocalLink FIFO Signals}
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifostatus
add wave -noupdate -format Logic /ll_fifo_tb/egress_len_rdy_out
add wave -noupdate -format Literal /ll_fifo_tb/egress_len_out
add wave -noupdate -format Logic /ll_fifo_tb/egress_len_err_out
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifostatus
add wave -noupdate -format Logic /ll_fifo_tb/ingress_len_rdy_out
add wave -noupdate -format Literal /ll_fifo_tb/ingress_len_out
add wave -noupdate -format Logic /ll_fifo_tb/ingress_len_err_out
add wave -noupdate -divider {BRAM_FIFO (Tester->LOOPBACK)}
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/fifo_gsr_in
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/write_clock_in
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_clock_in
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_data_out
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_rem_out
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_sof_out_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_eof_out_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_enable_in
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/write_data_in
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/write_rem_in
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/write_sof_in_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/write_eof_in_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/write_enable_in
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/fifostatus_out
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/full_out
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/empty_out
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/data_valid_out
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_out
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_rdy_out
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_err_out
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_en
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_en
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/fifo_gsr
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_data
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_data
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_rem
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_rem_plus_one
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_eof_n
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_rem
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_eof_n
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/min_addr1
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/min_addr2
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rem_sel1
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rem_sel2
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/full
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/empty
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_addr_full
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_addr
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_addr_minor
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_addrgray
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_nextgray
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_lastgray
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addr
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addr_full
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addr_minor
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addrgray
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/write_nextgray
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/fifostatus
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_allow
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_allow_minor
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_allow
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_allow_minor
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/full_allow
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/empty_allow
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/emptyg
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/fullg
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/ecomp
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/fcomp
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/emuxcyo
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/fmuxcyo
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/read_truegray
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rag_writesync
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/ra_writesync
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addrr
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/data_valid
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_byte_cnt
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_byte_cnt_plus_rem
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_word_cnt
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_byte_cnt_plus_rem_with_carry
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/total_len_byte_cnt_with_carry
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_word_cnt_with_carry
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_byte_cnt_with_carry
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/carry1
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/carry2
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/carry3
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/carry4
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_counter_overflow
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_rdy
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_rdy_p
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_wr_allow
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_wr_allow_p
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_rd_allow
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_rd_allow_temp
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_clk
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_clk
add wave -noupdate -color Magenta -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_wr_addr
add wave -noupdate -color Magenta -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_rd_addr
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_p
add wave -noupdate -color Magenta -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_r
add wave -noupdate -color Magenta -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len
add wave -noupdate -color Magenta -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len_rdy_2
add wave -noupdate -color Magenta -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len_rdy
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len_rdy_p
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len_rdy_p_p
add wave -noupdate -color Magenta -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_rdy_r
add wave -noupdate -color Magenta -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_wr_allow_r
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/len_err
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/inframe
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/inframe_i
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/fifo_gsr_n
add wave -noupdate -divider BRAM_MACRO(Tester->Loopback)
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/fifo_gsr
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_clk
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_clk
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_allow
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_allow_minor
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_addr_full
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_addr_minor
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_addr
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_data
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_rem
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_eof_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_allow
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_allow_minor
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_addr
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_addr_minor
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_addr_full
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_data
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_rem
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_eof_n
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_data_grp
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_data_p
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_ctrl_rem_p
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_sof_eof_p
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_ctrl_p
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_rem_plus_one
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_ctrl_rem
add wave -noupdate -format Literal -expand /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_ctrl_rem
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/min_addr1
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/min_addr2
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rem_sel1
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rem_sel2
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/gnd_bus
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/gnd
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/pwr
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_sof_eof
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_sof_eof
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/wr_sof_temp_n
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_rd_temp
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_wr_temp
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_wr_en
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/ram_wr_en
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/bram_rd_sel
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/bram_wr_sel
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_sof_eof_grp
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_ctrl_rem_grp
add wave -noupdate -format Literal /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_rd_ctrl_grp
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_rd_allow1
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_wr_allow1
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_rd_allow2
add wave -noupdate -format Logic /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_wr_allow2
add wave -noupdate -format Literal -expand /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/rd_ctrl_rem
add wave -noupdate -format Literal -expand /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_rd_ctrl_rem1
add wave -noupdate -format Literal -expand /ll_fifo_tb/egress_fifo/bram_gen/bramfifo/b_ram_fifo/bram_macro_inst/c_rd_ctrl_rem2
add wave -noupdate -divider BRAM_FIFO(LOOPBACK->Tester)
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/fifo_gsr_in
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/write_clock_in
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/write_data_in
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/write_rem_in
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/write_sof_in_n
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/write_eof_in_n
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/write_enable_in
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_clock_in
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_enable_in
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_data_out
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_rem_out
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_sof_out_n
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_eof_out_n
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/full_out
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/empty_out
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/data_valid_out
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/fifostatus_out
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_out
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_rdy_out
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_err_out
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_clk
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_clk
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_en
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_en
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/fifo_gsr
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_data
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_data
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_rem
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_rem_plus_one
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_eof_n
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_rem
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_sof_n
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_eof_n
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/min_addr1
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/min_addr2
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rem_sel1
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rem_sel2
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/full
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/empty
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_addr_full
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_addr
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_addr_minor
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_addrgray
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_nextgray
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_lastgray
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addr
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addr_full
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addr_minor
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addrgray
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/write_nextgray
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/fifostatus
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_allow
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_allow_minor
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_allow
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_allow_minor
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/full_allow
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/empty_allow
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/emptyg
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/fullg
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/ecomp
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/fcomp
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/emuxcyo
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/fmuxcyo
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/read_truegray
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rag_writesync
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/ra_writesync
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_addrr
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/data_valid
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_p
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_r
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_byte_cnt
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_byte_cnt_plus_rem
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_word_cnt
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_byte_cnt_plus_rem_with_carry
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/total_len_byte_cnt_with_carry
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_word_cnt_with_carry
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_byte_cnt_with_carry
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/carry1
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/carry2
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/carry3
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/carry4
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_counter_overflow
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len_rdy_2
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len_rdy
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len_rdy_p
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/rd_len_rdy_p_p
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_rdy
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_rdy_r
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/wr_len_rdy_p
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_wr_allow
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_wr_allow_r
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_wr_allow_p
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_rd_allow
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_rd_allow_temp
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_wr_addr
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_rd_addr
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/len_err
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/inframe
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/inframe_i
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/fifo_gsr_n
add wave -noupdate -format Literal /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/gnd_bus
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/gnd
add wave -noupdate -format Logic /ll_fifo_tb/ingress_fifo/bram_gen/bramfifo/b_ram_fifo/pwr
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {525 us}
configure wave -namecolwidth 212
configure wave -valuecolwidth 40
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
