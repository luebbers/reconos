/***********************************************************************
 * Records a buffer of sound from either the Line-In or Mic-In ports 
 * to the AC97 controller and plays it back through the Line-Out port 
 * using the AC97.
 ***********************************************************************/
#include <xbasic_types.h>
#include <xio.h>
#include "xac97_l.h"

void XAc97_WriteReg(Xuint32 baseaddr, Xuint32 reg_addr, Xuint32 value) {
    XAc97_mSetAC97RegisterData(baseaddr, value);
    XAc97_mSetAC97RegisterAccessCommand(baseaddr, reg_addr);
    while (!XAc97_isRegisterAccessFinished(baseaddr));
}

Xuint32 XAc97_ReadReg(Xuint32 baseaddr, Xuint32 reg_addr) {
    XAc97_mSetAC97RegisterAccessCommand(baseaddr, reg_addr  | 0x80);
    while (!XAc97_isRegisterAccessFinished(baseaddr));
    return XAc97_mGetAC97RegisterData(baseaddr);
}

void XAc97_AwaitCodecReady(Xuint32 baseaddr) {
    while(!XAc97_isCodecReady(baseaddr));
}


void XAc97_Delay(Xuint32 value) {
  while(value-- > 0);
}


void XAc97_SoftReset(Xuint32 BaseAddress) {
  XAc97_WriteReg(BaseAddress, AC97_Reset, 0x0000);

  /** Set default output volumes **/
  XAc97_WriteReg(BaseAddress, AC97_MasterVol, AC97_VOL_MID);
  XAc97_WriteReg(BaseAddress, AC97_AuxOutVol, AC97_VOL_MAX);
  XAc97_WriteReg(BaseAddress, AC97_MasterVolMono, AC97_VOL_MAX);
  XAc97_WriteReg(BaseAddress, AC97_PCMOutVol, AC97_VOL_MAX);

  /** Clear the fifos **/
  XAc97_ClearFifos(BaseAddress);
}


void XAc97_HardReset(Xuint32 BaseAddress) {
  XAc97_mSetControl(BaseAddress, AC97_ENABLE_RESET_AC97);
  XAc97_Delay(100000);
  XAc97_mSetControl(BaseAddress, AC97_DISABLE_RESET_AC97);
  XAc97_Delay(100000);
  XAc97_SoftReset(BaseAddress);
}


void XAc97_InitAudio(Xuint32 BaseAddress, Xuint8 Loopback) {
  Xuint8 i;

  /** Reset audio codec **/
  XAc97_SoftReset(BaseAddress);

  /** Wait until we receive the ready signal **/
  XAc97_AwaitCodecReady(BaseAddress);

  if( Loopback == AC97_ANALOG_LOOPBACK ) {
    XAc97_WriteReg(BaseAddress, AC97_MicVol, AC97_VOL_MAX);
    XAc97_WriteReg(BaseAddress, AC97_LineInVol, AC97_VOL_MAX);
  }
  else if( Loopback == AC97_DIGITAL_LOOPBACK )
    XAc97_WriteReg(BaseAddress, AC97_GeneralPurpose, AC97_GP_ADC_DAC_LOOPBACK);

} // end XAc97_InitAudio()


void XAc97_EnableInput(Xuint32 BaseAddress, Xuint8 InputType) {
  XAc97_WriteReg(BaseAddress, AC97_RecordGain, AC97_VOL_MAX);  

  if( InputType == AC97_MIC_INPUT ) 
    XAc97_WriteReg(BaseAddress, AC97_RecordSelect, AC97_RECORD_MIC_IN);
  else if( InputType == AC97_LINE_INPUT ) 
    XAc97_WriteReg(BaseAddress, AC97_RecordSelect, AC97_RECORD_LINE_IN);
}


void XAc97_DisableInput(Xuint32 BaseAddress, Xuint8 InputType) {
  XAc97_WriteReg(BaseAddress, AC97_RecordGain, AC97_VOL_MUTE);  
  
  if( InputType == AC97_MIC_INPUT ) 
    XAc97_WriteReg(BaseAddress, AC97_MicVol, AC97_VOL_MUTE);
  else if( InputType == AC97_LINE_INPUT ) 
    XAc97_WriteReg(BaseAddress, AC97_LineInVol, AC97_VOL_MUTE);
}


void XAc97_RecAudio(Xuint32 BaseAddress, Xuint32 StartAddress, 
		    Xuint32 EndAddress) {
  Xuint32 i;
  Xuint32 sample;
  volatile Xuint32 *sound_ptr = (Xuint32*)StartAddress;
  
  /** Enable VRA Mode **/
  XAc97_WriteReg(BaseAddress, AC97_ExtendedAudioStat, 1);

  /** Clear out the FIFOs **/
  XAc97_ClearFifos(BaseAddress);

  /** Wait until we receive the ready signal **/
  XAc97_AwaitCodecReady(BaseAddress);

  /** Volume settings **/
  XAc97_WriteReg(BaseAddress, AC97_MasterVol, AC97_VOL_MUTE);
  XAc97_WriteReg(BaseAddress, AC97_AuxOutVol, AC97_VOL_MUTE);
  XAc97_WriteReg(BaseAddress, AC97_MasterVolMono, AC97_VOL_MUTE);
  XAc97_WriteReg(BaseAddress, AC97_PCBeepVol, AC97_VOL_MUTE);
  XAc97_WriteReg(BaseAddress, AC97_PCMOutVol, AC97_VOL_MUTE);
    
  XAc97_WriteReg(BaseAddress, AC97_GeneralPurpose, AC97_GP_PCM_BYPASS_3D);
  
  /** Record the incoming audio **/
  while( sound_ptr < (Xuint32*)EndAddress ) {
    sample = XAc97_ReadFifo(BaseAddress);
    *sound_ptr = sample;
    sound_ptr++;
  }

} // end XAc97_RecAudio()



void XAc97_PlayAudio(Xuint32 BaseAddress, Xuint32 StartAddress, 
		     Xuint32 EndAddress){
  Xuint32 i;
  Xuint32 sample;
  volatile Xuint32 *sound_ptr = (Xuint32*)StartAddress;

  /** Wait for the ready signal **/
  XAc97_AwaitCodecReady(BaseAddress);

  /** Disable VRA Mode **/
  XAc97_WriteReg(BaseAddress, AC97_ExtendedAudioStat, 0);

  /** Play Volume Settings **/
  XAc97_WriteReg(BaseAddress, AC97_MasterVol, AC97_VOL_MAX); 
  XAc97_WriteReg(BaseAddress, AC97_AuxOutVol, AC97_VOL_MAX);
  XAc97_WriteReg(BaseAddress, AC97_MasterVolMono, AC97_VOL_MAX);
  XAc97_WriteReg(BaseAddress, AC97_PCBeepVol, AC97_VOL_MAX);
  XAc97_WriteReg(BaseAddress, AC97_PCMOutVol, AC97_VOL_MAX);
  XAc97_WriteReg(BaseAddress, AC97_LineInVol, AC97_VOL_MAX);
  XAc97_WriteReg(BaseAddress, AC97_MicVol, AC97_VOL_MAX);

  /** Clear FIFOs **/
  XAc97_ClearFifos(BaseAddress);
 
  while( sound_ptr < (Xuint32*)EndAddress ) {
    sample = *sound_ptr; 
    sound_ptr = sound_ptr + 1;
    XAc97_WriteFifo(BaseAddress, sample);
  }

  XAc97_ClearFifos(BaseAddress);
  
} // end XAc97_PlayAudio()


Xuint32 XAc97_ReadFifo(Xuint32 BaseAddress) {
  while(XAc97_isOutFIFOEmpty(BaseAddress));
  return XAc97_mGetOutFifoData(BaseAddress);
}

void XAc97_WriteFifo(Xuint32 BaseAddress, Xuint32 sample) {
  while(XAc97_isInFIFOFull(BaseAddress));
  XAc97_mSetInFifoData(BaseAddress, sample);
}

void XAc97_ClearFifos(Xuint32 BaseAddress) {
  Xuint32 i;
  XAc97_mSetControl(BaseAddress, AC97_CLEAR_FIFOS);
  for( i = 0; i < 512; i++ )
    XAc97_mSetInFifoData(BaseAddress, 0);
}
