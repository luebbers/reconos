# Hierarchy
# uut/ 				opb_ac97
# uut/ac97_fifo_i		ac97_fifo
# uut/ac97_fifo_i/ac97_core_i	ac97_core

vsim work.testbench_opb_ac97

#######################################################
# Testbench signals
#######################################################
add wave test_number


#######################################################
# OPB Bus signals
#######################################################
add wave OPB_Clk OPB_RNW OPB_select Sln_xferAck
add wave -hex OPB_ABus OPB_DBus Sln_DBus opb_read_value


#######################################################
# AC97 Model signals
#######################################################
#add wave -hex uut_1/slot0
add wave -hex uut_1/slot3 uut_1/slot4
#add wave -hex uut_1/shift_reg
#add wave uut_1/slot_counter uut_1/bit_counter 

#######################################################
# AC97 signals
#######################################################
add wave Bit_Clk Sync SData_Out SData_In ac97reset_n uut/ac97_fifo_i/BitClk_New_frame uut/ac97_fifo_i/IpClk_codec_rdy;
#add wave uut/ac97_core/slot_no uut/ac97_core/slot_end
#add wave -hex uut/ac97_core/data_in uut/ac97_core/pcm_playback_left uut/ac97_core/pcm_playback_right uut/ac97_core/pcm_record_left uut/ac97_core/pcm_record_right
add wave uut/ac97_fifo_i/ac97_core_i/slot_no

#######################################################
# FIFO signals
#######################################################
#add wave uut/in_FIFO_write uut/in_fifo_read
#add wave uut/in_FIFO_Underrun uut/in_data_Exists uut/in_FIFO_Full uut/in_data_Exists
#add wave -hex uut/in_Data_FIFO
#add wave uut/out_FIFO_Overrun uut/in_FIFO_Underrun uut/codec_rdy uut/register_Access_Finished uut/out_Data_Exists  uut/in_FIFO_Full
add wave -hex uut/ac97_fifo_i/status_reg
add wave -hex uut/ac97_fifo_i/in_FIFO_Read uut/ac97_fifo_i/in_Data_Fifo
add wave -hex uut/ac97_fifo_i/out_Data_Fifo uut/ac97_fifo_i/out_Data_Read
add wave -hex uut/ac97_fifo_i/in_fifo_level uut/ac97_fifo_i/out_fifo_level
add wave uut/ac97_fifo_i/out_fifo_empty uut/ac97_fifo_i/out_data_exists

# Interrupts
#add wave Interrupt
#aadd wave uut/in_fifo_interrupt_en uut/out_fifo_interrupt_en uut/in_Data_Exists uut/out_FIFO_Full uut/in_FIFO_full


# Register Transfer Signals
add wave uut/ac97_fifo_i/access_SM uut/ac97_fifo_i/IpClk_ac97_reg_ready uut/ac97_fifo_i/ac97_reg_access_S
#add wave -hex uut/ac97_reg_write_data uut/ac97_reg_addr
#add wave uut/ac97_reg_access_S uut/waiting_for_reg_access_ack uut/ac97_reg_ready_t uut/opb_ac97_reg_ready_1 uut/waiting_for_reg_access_completion uut/register_access_sequence_complete uut/register_Access_Finished
#add wave uut/ac97_reg_read_t uut/ac97_reg_write_t uut/ac97_core/reg_read_data_valid_i
#add wave uut/ac97_core/read_command uut/ac97_core/write_command 
#add wave uut/ac97_core/ac97_reg_read_i 

#add wave uut/ac97_reg_write_data

#add wave uut/ac97_core/slot0 uut/ac97_core/slot1 uut/ac97_core/slot2

#add wave -r /*

#force OPB_Rst 0
#force SData_In 0

