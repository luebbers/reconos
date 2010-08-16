# Simulation environment for testbench_ac97_core

vsim work.testbench_ac97_core

add wave test_no

############################################################
### AC97_core signals
############################################################

# I/O pins
add wave test_no codec_rdy clk sync sdata_out sdata_in

# timing signals
add wave uut/slot_no uut/slot_end uut/last_frame_cycle 
add wave -hex uut/data_out

# Sdata In/Sdata Out
add wave -hex uut/data_in
add wave uut/codec_rdy_i 
add wave uut/slot0 uut/slot1 uut/slot2 
add wave uut/slot3 uut/slot4

add wave -hex PCM_Playback_Left PCM_Playback_Right

# register IF
add wave uut/reg_if_state
add wave reg_error reg_busy play_right_accept PCM_Record_Left_Valid PCM_Record_Right_Valid

# Parallel data
#add wave -hex uut/pcm_playback_left uut/pcm_playback_right uut/pcm_record_left uut/pcm_record_right
#add wave uut/pcm_record_right_valid uut/pcm_record_left_valid



############################################################
## ac97_model signals
############################################################

add wave model/slot_counter model/bit_counter model/end_of_frame
#add wave model/frame_count model/valid_frame model/codec_rdy
add wave -hex model/shift_reg_out
#add wave -hex model/slot0_out model/slot1_out model/slot2_out
#add wave -hex model/slot0_in model/slot2_in
# model/slot1_out model/slot2_out model/slot3_out model/slot4_out
add wave model/register_control_valid model/register_address model/register_read

#add wave model/reset_state model/reset_delay model/AC97Reset_n