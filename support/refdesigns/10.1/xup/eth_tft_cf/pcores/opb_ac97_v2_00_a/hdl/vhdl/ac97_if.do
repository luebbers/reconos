vsim TESTBENCH_ac97_if

add wave fast_clk bit_clk sdata_out sdata_in

#add wave uut/ac97_if_i/command_SM uut/ac97_if_i/codec_rdy
#add wave uut/ac97_if_i/command_num
#add wave -hex uut/ac97_if_i/rom_data

#add wave uut/ac97_if_i/ac97_core_i/reg_if_state

#add wave uut/new_sample