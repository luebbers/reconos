#ifndef XAC97_H
#define XAC97_H

#include <xbasic_types.h>
#include <xio.h>

// AC97 core register offsets
#define AC97_IN_FIFO_OFFSET 	        0x0
#define AC97_OUT_FIFO_OFFSET 		0x0
#define AC97_STATUS_OFFSET 	        0x4
#define AC97_CONTROL_OFFSET             0x4
#define AC97_REG_READ_OFFSET 		0x8
#define AC97_REG_WRITE_OFFSET		0x8
#define AC97_REG_CONTROL_OFFSET         0xc

// Status register bitmask constants
#define AC97_IN_FIFO_FULL         0x01
#define AC97_IN_FIFO_EMPTY        0x02
#define AC97_OUT_FIFO_EMPTY       0x04
#define AC97_OUT_FIFO_DATA        0x08
//#define AC97_REG_ACCESS_FINISHED  0x10
#define AC97_REG_ACCESS_BUSY      0x10
#define AC97_CODEC_RDY            0x20
#define AC97_IN_FIFO_UNDERRUN     0x40
#define AC97_OUT_FIFO_OVERRUN     0x80
#define AC97_REG_ACCESS_ERROR     0x100
#define AC97_IN_FIFO_LEVEL        0x003ff000 // 21 downto 12
#define AC97_IN_FIFO_LEVEL_RSHFT  12
#define AC97_OUT_FIFO_LEVEL       0xffc00000 // 31 downto 22
#define AC97_OUT_FIFO_LEVEL_RSHFT 22

// FIFO Control Offsets
#define AC97_CLEAR_IN_FIFO              0x1
#define AC97_CLEAR_OUT_FIFO             0x2
#define AC97_ENABLE_IN_FIFO_INTERRUPT   0x4
#define AC97_ENABLE_OUT_FIFO_INTERRUPT  0x8
#define AC97_ENABLE_RESET_AC97          0x10
#define AC97_DISABLE_RESET_AC97         0x0
#define AC97_CLEAR_FIFOS AC97_CLEAR_IN_FIFO | AC97_CLEAR_OUT_FIFO

/** AC97 CODEC Registers **/
#define AC97_Reset              0x00
#define AC97_MasterVol          0x02
#define AC97_AuxOutVol          0x04
#define AC97_MasterVolMono      0x06
#define AC97_Reserved0x08       0x08
#define AC97_PCBeepVol          0x0A
#define AC97_PhoneInVol         0x0C
#define AC97_MicVol             0x0E
#define AC97_LineInVol          0x10
#define AC97_CDVol              0x12
#define AC97_VideoVol           0x14
#define AC97_AuxInVol           0x16
#define AC97_PCMOutVol          0x18
#define AC97_RecordSelect       0x1A
#define AC97_RecordGain         0x1C
#define AC97_Reserved0x1E       0x1E
#define AC97_GeneralPurpose     0x20
#define AC97_3DControl          0x22
#define AC97_PowerDown          0x26
#define AC97_ExtendedAudioID    0x28
#define AC97_ExtendedAudioStat  0x2A
#define AC97_PCM_DAC_Rate       0x2C
#define AC97_PCM_ADC_Rate       0x32
#define AC97_PCM_DAC_Rate0      0x78
#define AC97_PCM_DAC_Rate1      0x7A
#define AC97_Reserved0x34       0x34
#define AC97_JackSense          0x72
#define AC97_SerialConfig       0x74
#define AC97_MiscControlBits    0x76
#define AC97_VendorID1          0x7C
#define AC97_VendorID2          0x7E

// Volume Constants for registers:
//  AC97_MasterVol
//  AC97_HeadphoneVol
//  AC97_MasterVolMono
#define AC97_RIGHT_VOL_ATTN_0_DB       0x0
#define AC97_RIGHT_VOL_ATTN_1_5_DB     0x1
#define AC97_RIGHT_VOL_ATTN_3_0_DB     0x2
#define AC97_RIGHT_VOL_ATTN_4_5_DB     0x3
#define AC97_RIGHT_VOL_ATTN_6_0_DB     0x4
#define AC97_RIGHT_VOL_ATTN_7_5_DB     0x5
#define AC97_RIGHT_VOL_ATTN_9_0_DB     0x6
#define AC97_RIGHT_VOL_ATTN_10_0_DB     0x7
#define AC97_RIGHT_VOL_ATTN_11_5_DB     0x8
#define AC97_RIGHT_VOL_ATTN_13_0_DB     0x9
#define AC97_RIGHT_VOL_ATTN_14_5_DB     0xa
#define AC97_RIGHT_VOL_ATTN_16_0_DB     0xb
#define AC97_RIGHT_VOL_ATTN_17_5_DB     0xc
#define AC97_RIGHT_VOL_ATTN_19_0_DB     0xd
#define AC97_RIGHT_VOL_ATTN_20_5_DB     0xe
#define AC97_RIGHT_VOL_ATTN_22_0_DB     0xf
#define AC97_RIGHT_VOL_ATTN_23_5_DB     0x10
#define AC97_RIGHT_VOL_ATTN_25_0_DB     0x11
#define AC97_RIGHT_VOL_ATTN_26_5_DB     0x12
#define AC97_RIGHT_VOL_ATTN_28_0_DB     0x13
#define AC97_RIGHT_VOL_ATTN_29_5_DB     0x14
#define AC97_RIGHT_VOL_ATTN_31_0_DB     0x15
#define AC97_RIGHT_VOL_ATTN_32_5_DB     0x16
#define AC97_RIGHT_VOL_ATTN_34_0_DB     0x17
#define AC97_RIGHT_VOL_ATTN_35_5_DB     0x18
#define AC97_RIGHT_VOL_ATTN_37_0_DB     0x19
#define AC97_RIGHT_VOL_ATTN_38_5_DB     0x1a
#define AC97_RIGHT_VOL_ATTN_40_0_DB     0x1b
#define AC97_RIGHT_VOL_ATTN_41_5_DB     0x1c
#define AC97_RIGHT_VOL_ATTN_43_0_DB     0x1d
#define AC97_RIGHT_VOL_ATTN_44_5_DB     0x1e
#define AC97_RIGHT_VOL_ATTN_46_0_DB     0x1f

#define AC97_LEFT_VOL_ATTN_0_DB        0x0
#define AC97_LEFT_VOL_ATTN_1_5_DB      0x100
#define AC97_LEFT_VOL_ATTN_3_0_DB      0x200
#define AC97_LEFT_VOL_ATTN_4_5_DB      0x300
#define AC97_LEFT_VOL_ATTN_6_0_DB      0x400
#define AC97_LEFT_VOL_ATTN_7_5_DB      0x500
#define AC97_LEFT_VOL_ATTN_9_0_DB      0x600
#define AC97_LEFT_VOL_ATTN_10_0_DB     0x700
#define AC97_LEFT_VOL_ATTN_11_5_DB     0x800
#define AC97_LEFT_VOL_ATTN_13_0_DB     0x900
#define AC97_LEFT_VOL_ATTN_14_5_DB     0xa00
#define AC97_LEFT_VOL_ATTN_16_0_DB     0xb00
#define AC97_LEFT_VOL_ATTN_17_5_DB     0xc00
#define AC97_LEFT_VOL_ATTN_19_0_DB     0xd00
#define AC97_LEFT_VOL_ATTN_20_5_DB     0xe00
#define AC97_LEFT_VOL_ATTN_22_0_DB     0xf00
#define AC97_LEFT_VOL_ATTN_23_5_DB     0x1000
#define AC97_LEFT_VOL_ATTN_25_0_DB     0x1100
#define AC97_LEFT_VOL_ATTN_26_5_DB     0x1200
#define AC97_LEFT_VOL_ATTN_28_0_DB     0x1300
#define AC97_LEFT_VOL_ATTN_29_5_DB     0x1400
#define AC97_LEFT_VOL_ATTN_31_0_DB     0x1500
#define AC97_LEFT_VOL_ATTN_32_5_DB     0x1600
#define AC97_LEFT_VOL_ATTN_34_0_DB     0x1700
#define AC97_LEFT_VOL_ATTN_35_5_DB     0x1800
#define AC97_LEFT_VOL_ATTN_37_0_DB     0x1900
#define AC97_LEFT_VOL_ATTN_38_5_DB     0x1a00
#define AC97_LEFT_VOL_ATTN_40_0_DB     0x1b00
#define AC97_LEFT_VOL_ATTN_41_5_DB     0x1c00
#define AC97_LEFT_VOL_ATTN_43_0_DB     0x1d00
#define AC97_LEFT_VOL_ATTN_44_5_DB     0x1e00
#define AC97_LEFT_VOL_ATTN_46_0_DB     0x1f00

#define AC97_VOL_ATTN_0_DB    AC97_LEFT_VOL_ATTN_0_DB | AC97_RIGHT_VOL_ATTN_0_DB
#define AC97_VOL_ATTN_1_5_DB  AC97_LEFT_VOL_ATTN_1_5_DB | AC97_RIGHT_VOL_ATTN_1_5_DB
#define AC97_VOL_ATTN_3_0_DB  AC97_LEFT_VOL_ATTN_3_0_DB | AC97_RIGHT_VOL_ATTN_3_0_DB
#define AC97_VOL_ATTN_4_5_DB  AC97_LEFT_VOL_ATTN_4_5_DB | AC97_RIGHT_VOL_ATTN_4_5_DB
#define AC97_VOL_ATTN_6_0_DB  AC97_LEFT_VOL_ATTN_6_0_DB | AC97_RIGHT_VOL_ATTN_6_0_DB
#define AC97_VOL_ATTN_7_5_DB  AC97_LEFT_VOL_ATTN_7_5_DB | AC97_RIGHT_VOL_ATTN_7_5_DB
#define AC97_VOL_ATTN_9_0_DB  AC97_LEFT_VOL_ATTN_9_0_DB | AC97_RIGHT_VOL_ATTN_9_0_DB
#define AC97_VOL_ATTN_10_0_DB    AC97_LEFT_VOL_ATTN_10_0_DB | AC97_RIGHT_VOL_ATTN_10_0_DB
#define AC97_VOL_ATTN_11_5_DB    AC97_LEFT_VOL_ATTN_11_5_DB | AC97_RIGHT_VOL_ATTN_11_5_DB
#define AC97_VOL_ATTN_13_0_DB    AC97_LEFT_VOL_ATTN_13_0_DB | AC97_RIGHT_VOL_ATTN_13_0_DB
#define AC97_VOL_ATTN_14_5_DB    AC97_LEFT_VOL_ATTN_14_5_DB | AC97_RIGHT_VOL_ATTN_14_5_DB
#define AC97_VOL_ATTN_16_0_DB    AC97_LEFT_VOL_ATTN_16_0_DB | AC97_RIGHT_VOL_ATTN_16_0_DB
#define AC97_VOL_ATTN_17_5_DB    AC97_LEFT_VOL_ATTN_17_5_DB | AC97_RIGHT_VOL_ATTN_17_5_DB
#define AC97_VOL_ATTN_19_0_DB    AC97_LEFT_VOL_ATTN_19_0_DB | AC97_RIGHT_VOL_ATTN_19_0_DB
#define AC97_VOL_ATTN_20_5_DB    AC97_LEFT_VOL_ATTN_20_5_DB | AC97_RIGHT_VOL_ATTN_20_5_DB
#define AC97_VOL_ATTN_22_0_DB    AC97_LEFT_VOL_ATTN_22_0_DB | AC97_RIGHT_VOL_ATTN_22_0_DB
#define AC97_VOL_ATTN_23_5_DB    AC97_LEFT_VOL_ATTN_23_5_DB | AC97_RIGHT_VOL_ATTN_23_5_DB
#define AC97_VOL_ATTN_25_0_DB    AC97_LEFT_VOL_ATTN_25_0_DB | AC97_RIGHT_VOL_ATTN_25_0_DB
#define AC97_VOL_ATTN_26_5_DB    AC97_LEFT_VOL_ATTN_26_5_DB | AC97_RIGHT_VOL_ATTN_26_5_DB
#define AC97_VOL_ATTN_28_0_DB    AC97_LEFT_VOL_ATTN_28_0_DB | AC97_RIGHT_VOL_ATTN_28_0_DB
#define AC97_VOL_ATTN_29_5_DB    AC97_LEFT_VOL_ATTN_29_5_DB | AC97_RIGHT_VOL_ATTN_29_5_DB
#define AC97_VOL_ATTN_31_0_DB    AC97_LEFT_VOL_ATTN_31_0_DB | AC97_RIGHT_VOL_ATTN_31_0_DB
#define AC97_VOL_ATTN_32_5_DB    AC97_LEFT_VOL_ATTN_32_5_DB | AC97_RIGHT_VOL_ATTN_32_5_DB
#define AC97_VOL_ATTN_34_0_DB    AC97_LEFT_VOL_ATTN_34_0_DB | AC97_RIGHT_VOL_ATTN_34_0_DB
#define AC97_VOL_ATTN_35_5_DB    AC97_LEFT_VOL_ATTN_35_5_DB | AC97_RIGHT_VOL_ATTN_35_5_DB
#define AC97_VOL_ATTN_37_0_DB    AC97_LEFT_VOL_ATTN_37_0_DB | AC97_RIGHT_VOL_ATTN_37_0_DB
#define AC97_VOL_ATTN_38_5_DB    AC97_LEFT_VOL_ATTN_38_5_DB | AC97_RIGHT_VOL_ATTN_38_5_DB
#define AC97_VOL_ATTN_40_0_DB    AC97_LEFT_VOL_ATTN_40_0_DB | AC97_RIGHT_VOL_ATTN_40_0_DB
#define AC97_VOL_ATTN_41_5_DB    AC97_LEFT_VOL_ATTN_41_5_DB | AC97_RIGHT_VOL_ATTN_41_5_DB
#define AC97_VOL_ATTN_43_0_DB    AC97_LEFT_VOL_ATTN_43_0_DB | AC97_RIGHT_VOL_ATTN_43_0_DB
#define AC97_VOL_ATTN_44_5_DB    AC97_LEFT_VOL_ATTN_44_5_DB | AC97_RIGHT_VOL_ATTN_44_5_DB
#define AC97_VOL_ATTN_46_0_DB    AC97_LEFT_VOL_ATTN_46_0_DB | AC97_RIGHT_VOL_ATTN_46_0_DB

#define AC97_VOL_MUTE     0x8000
#define AC97_VOL_MIN      0x1f1f
#define AC97_VOL_MID      0x0a0a
#define AC97_VOL_MAX      0x0000

#define AC97_RECORD_MIC_IN  0x0000
#define AC97_RECORD_LINE_IN 0x0404 // both left and right

// Extended Audio Control
#define AC97_EXTENDED_AUDIO_CONTROL_VRA 0x1


// PCM Data rate constants
// AC97_PCM_DAC_Rate       0x2C
// AC97_PCM_ADC_Rate       0x32
#define AC97_PCM_RATE_8000_HZ  0x1F40
#define AC97_PCM_RATE_11025_HZ 0x2B11
#define AC97_PCM_RATE_16000_HZ 0x3E80
#define AC97_PCM_RATE_22050_HZ 0x5622
#define AC97_PCM_RATE_44100_HZ 0xAC44
#define AC97_PCM_RATE_48000_HZ 0xBB80


// General Purpose register constants (LM4549A)
// bits are zero by default
#define AC97_GP_PCM_BYPASS_3D       0x8000  // POP bit (on)
#define AC97_GP_NATIONAL_3D_ON      0x2000  // 3D bit (on)
#define AC97_GP_MONO_OUTPUT_MIX     0x0     // MIX bit (off)
#define AC97_GP_MONO_OUTPUT_MIC     0x200   // MIX bit (on)
#define AC97_GP_MIC_SELECT_MIC1     0x0     // MS bit (off)
#define AC97_GP_MIC_SELECT_MIC2     0x100   // MS bit (on)
#define AC97_GP_ADC_DAC_LOOPBACK    0x80    // LPBK bit

#define AC97_MIC_INPUT   1
#define AC97_LINE_INPUT  2

#define AC97_ANALOG_LOOPBACK  1
#define AC97_DIGITAL_LOOPBACK 2

#define XAC97_mGetRegister(BaseAddress, offset) \
            XIo_In32((BaseAddress + offset))

// Macros for reading/writing AC97 core registers
#define XAc97_mSetInFifoData(BaseAddress, value) \
            XIo_Out32((BaseAddress) + AC97_IN_FIFO_OFFSET,(value))
#define XAc97_mGetOutFifoData(BaseAddress) \
            XIo_In32((BaseAddress + AC97_OUT_FIFO_OFFSET))
#define XAc97_mGetStatus(BaseAddress) \
            XIo_In32((BaseAddress + AC97_STATUS_OFFSET))
#define XAc97_mSetControl(BaseAddress, value) \
            XIo_Out32((BaseAddress) + AC97_CONTROL_OFFSET,(value))
#define XAc97_mSetAC97RegisterAccessCommand(BaseAddress, value) \
            XIo_Out32((BaseAddress) + AC97_REG_CONTROL_OFFSET,(value))
#define XAc97_mGetAC97RegisterData(BaseAddress) \
            XIo_In32((BaseAddress + AC97_REG_READ_OFFSET))
#define XAc97_mSetAC97RegisterData(BaseAddress, value) \
            XIo_Out32((BaseAddress) + AC97_REG_WRITE_OFFSET,(value))

// Status register macros
#define XAC97_isInFIFOFull(BaseAddress) \
            (XAC97_mGetStatus(BaseAddress) & AC97_IN_FIFO_FULL)
#define XAC97_isInFIFOEmpty(BaseAddress) \
            (XAC97_mGetStatus(BaseAddress) & AC97_IN_FIFO_EMPTY)
#define XAC97_isOutFIFOEmpty(BaseAddress) \
            (XAC97_mGetStatus(BaseAddress) & AC97_OUT_FIFO_EMPTY)
#define XAC97_isOutFIFOFull(BaseAddress) \
            (XAC97_mGetStatus(BaseAddress) & AC97_OUT_FIFO_FULL)
#define XAC97_isRegisterAccessFinished(BaseAddress) \
            ((XAC97_mGetStatus(BaseAddress) & AC97_REG_ACCESS_BUSY) == 0)
//            (XAC97_mGetStatus(BaseAddress) & AC97_REG_ACCESS_FINISHED))
#define XAC97_isRegisterAccessError(BaseAddress) \
            ((XAC97_mGetStatus(BaseAddress) & AC97_REG_ACCESS_ERROR) > 0)

#define XAC97_isCodecReady(BaseAddress) \
            (XAC97_mGetStatus(BaseAddress) & AC97_CODEC_RDY)
#define XAC97_isInFIFOUnderrun(BaseAddress) \
            (XAC97_mGetStatus(BaseAddress) & AC97_IN_FIFO_UNDERRUN)
#define XAC97_isOutFIFOOverrun(BaseAddress) \
            (XAC97_mGetStatus(BaseAddress) & AC97_OUT_FIFO_UNDERRUN)
#define XAC97_getInFIFOLevel(BaseAddress) \
            ((XAC97_mGetStatus(BaseAddress) & AC97_IN_FIFO_LEVEL) >> \
             AC97_IN_FIFO_LEVEL_RSHFT)
#define XAc97_getOutFIFOLevel(BaseAddress) \
            ((XAc97_mGetStatus(BaseAddress) & AC97_OUT_FIFO_LEVEL) >> \
             AC97_OUT_FIFO_LEVEL_RSHFT)


// AC97 driver functions
void XAc97_WriteReg(Xuint32 BaseAddress, Xuint32 RegAddress, Xuint32 Value);
Xuint32 XAc97_ReadReg(Xuint32 BaseAddress, Xuint32 RegAddress);
void XAc97_AwaitCodecReady(Xuint32 BaseAddress);

void XAc97_Delay(Xuint32 Value);
void XAc97_SoftReset(Xuint32 BaseAddress);
void XAc97_HardReset(Xuint32 BaseAddress);

void XAc97_InitAudio(Xuint32 BaseAddress, Xuint8 Loopback);
void XAc97_EnableInput(Xuint32 BaseAddress, Xuint8 InputType);
void XAc97_DisableInput(Xuint32 BaseAddress, Xuint8 InputType);
void XAc97_RecAudio(Xuint32 BaseAddress, Xuint32 StartAddress,
		    Xuint32 EndAddress);
void XAc97_PlayAudio(Xuint32 BaseAddress, Xuint32 StartAddress,
		     Xuint32 EndAddress);
void XAc97_WriteFifo(Xuint32 BaseAddress, Xuint32 Sample);
Xuint32 XAc97_ReadFifo(Xuint32 BaseAddress);
void XAc97_ClearFifo(Xuint32 BaseAddress);

#endif
