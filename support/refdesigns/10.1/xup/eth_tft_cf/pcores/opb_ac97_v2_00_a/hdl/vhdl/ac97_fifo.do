
vsim work.testbench_ac97_fifo

add wave test_no
add wave Bus2IP_Reset Bus2IP_Clk

### AC97 signals

# I/O pins
add wave bit_clk sync sdata_out sdata_in ac97reset_n 
# control signals
add wave uut/ac97_core_i/slot_no uut/ac97_core_i/slot_end uut/ac97_core_i/codec_rdy 
add wave -hex uut/status_reg
add wave -hex uut/ac97_core_i/using_playback_bram/in_fifo/in_address
add wave -hex uut/ac97_core_i/using_playback_bram/in_fifo/out_address

# Parallel data
#add wave -hex uut/ac97_core/AC97_Reg_Write_Data
#add wave -hex uut/ac97_core/pcm_playback_left uut/ac97_core/pcm_playback_right uut/ac97_core/pcm_record_left uut/ac97_core/pcm_record_right
#add wave uut/pcm_record_right_valid uut/pcm_record_left_valid
#add wave sample

### IP bus signals
add wave -hex uut/Bus2IP_Addr  uut/Bus2IP_Data uut/IP2Bus_Data IP_READ
add wave uut/Bus2IP_RdCE uut/Bus2IP_WrCE
add wave -hex uut/out_Data_read

### AC97 register transfer signals
add wave uut/ac97_register_access_sm
add wave uut/ac97_core_i/reg_if_state
#add wave uut/access_SM uut/ac97_reg_access_S uut/reset_register_access_sequence uut/IpClk_ac97_reg_ready

### Interrupt signals
add wave Interrupt uut/in_fifo_interrupt_en uut/in_FIFO_Half_Empty