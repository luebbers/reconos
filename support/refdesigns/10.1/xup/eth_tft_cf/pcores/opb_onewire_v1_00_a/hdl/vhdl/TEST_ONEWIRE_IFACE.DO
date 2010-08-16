vlib work
vmap work work
vcom -93 -explicit -work work shreg.vhd
vcom -93 -explicit -work work bitreg.vhd
vcom -93 -explicit -work work bytereg.vhd
vcom -93 -explicit -work work jcounter.vhd
vcom -93 -explicit -work work crcreg.vhd
vcom -93 -explicit -work work clk_div.vhd
vcom -93 -explicit -work work onewire_master.vhd
vcom -93 -explicit -work work onewire_iface.vhd
vcom -93 -explicit -work work test_onewire_iface.vhd
vsim work.onewire_iface_tb
view signals structure wave source
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/clk_1mhz
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/clk_50khz
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/reset
add wave -noupdate -color #ff0000 -format Literal /onewire_iface_tb/uut/ow_master_i/thisstate
add wave -noupdate -format Literal /onewire_iface_tb/uut/ow_master_i/nextstate
add wave -noupdate -color #ffff00 -format Logic /onewire_iface_tb/uut/ow_master_i/dq
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/din
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/dout
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/d_ctrl
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/din_pp
add wave -noupdate -format Literal -radix hexadecimal /onewire_iface_tb/uut/ow_master_i/data
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/data_valid
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/crcok
add wave -noupdate -format Literal -radix hexadecimal /onewire_iface_tb/uut/ow_master_i/sn_data
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/tx_cmd_bit
add wave -noupdate -color #008080 -format Logic /onewire_iface_tb/uut/ow_master_i/sr1_reset
add wave -noupdate -color #008080 -format Logic /onewire_iface_tb/uut/ow_master_i/sr1_en
add wave -noupdate -color #008080 -format Literal /onewire_iface_tb/uut/ow_master_i/sr1_q
add wave -noupdate -color #8080c0 -format Logic /onewire_iface_tb/uut/ow_master_i/sr2_reset
add wave -noupdate -color #8080c0 -format Logic /onewire_iface_tb/uut/ow_master_i/sr2_en
add wave -noupdate -color #8080c0 -format Literal /onewire_iface_tb/uut/ow_master_i/sr2_q
add wave -noupdate -color #800040 -format Logic /onewire_iface_tb/uut/ow_master_i/jc1_reset
add wave -noupdate -color #800040 -format Literal /onewire_iface_tb/uut/ow_master_i/jc1_q
add wave -noupdate -color #400080 -format Literal /onewire_iface_tb/uut/ow_master_i/jc2_q
add wave -noupdate -format Literal /onewire_iface_tb/uut/ow_master_i/bitreg_en
add wave -noupdate -format Literal /onewire_iface_tb/uut/ow_master_i/bytereg_en
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/databit_valid
add wave -noupdate -format Logic /onewire_iface_tb/uut/ow_master_i/crcreg_en
add wave -noupdate -format Literal -radix hexadecimal /onewire_iface_tb/uut/ow_master_i/crcvalue_i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {6780972632 ps} {0 ps}
WaveRestoreZoom {6181562423 ps} {7884905719 ps}
run 8 ms