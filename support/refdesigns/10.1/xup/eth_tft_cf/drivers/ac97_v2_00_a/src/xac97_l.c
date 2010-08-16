/***********************************************************************
 * Records a buffer of sound from either the Line-In or Mic-In ports 
 * to the AC97 controller and plays it back through the Line-Out port 
 * using the AC97.
 ***********************************************************************/
#include <xbasic_types.h>
#include <xio.h>
#include "xac97_l.h"

void XAC97_WriteReg(Xuint32 baseaddr, Xuint32 reg_addr, Xuint32 value) {
    XAC97_mSetAC97RegisterData(baseaddr, value);
    XAC97_mSetAC97RegisterAccessCommand(baseaddr, reg_addr);
    while (!XAC97_isRegisterAccessFinished(baseaddr));
}

Xuint32 XAC97_ReadReg(Xuint32 baseaddr, Xuint32 reg_addr) {
    XAC97_mSetAC97RegisterAccessCommand(baseaddr, reg_addr  | 0x80);
    while (!XAC97_isRegisterAccessFinished(baseaddr));
    return XAC97_mGetAC97RegisterData(baseaddr);
}

void XAC97_AwaitCodecReady(Xuint32 baseaddr) {
    while(!XAC97_isCodecReady(baseaddr));
}


void XAC97_Delay(Xuint32 value) {
  while(value-- > 0);
}


void XAC97_SoftReset(Xuint32 BaseAddress) {
  XAC97_WriteReg(BaseAddress, AC97_Reset, 0x0000);

  /** Set default output volumes **/
  XAC97_WriteReg(BaseAddress, AC97_MasterVol, AC97_VOL_MID);
  XAC97_WriteReg(BaseAddress, AC97_AuxOutVol, AC97_VOL_MAX);
  XAC97_WriteReg(BaseAddress, AC97_MasterVolMono, AC97_VOL_MAX);
  XAC97_WriteReg(BaseAddress, AC97_PCMOutVol, AC97_VOL_MAX);

  /** Clear the fifos **/
  XAC97_ClearFifos(BaseAddress);
}


void XAC97_HardReset(Xuint32 BaseAddress) {
  XAC97_mSetControl(BaseAddress, AC97_ENABLE_RESET_AC97);
  XAC97_Delay(100000);
  XAC97_mSetControl(BaseAddress, AC97_DISABLE_RESET_AC97);
  XAC97_Delay(100000);
  XAC97_SoftReset(BaseAddress);
}


void XAC97_InitAudio(Xuint32 BaseAddress, Xuint8 Loopback) {
  Xuint8 i;

  /** Reset audio codec **/
  XAC97_SoftReset(BaseAddress);

  /** Wait until we receive the ready signal **/
  XAC97_AwaitCodecReady(BaseAddress);

  if( Loopback == AC97_ANALOG_LOOPBACK ) {
    XAC97_WriteReg(BaseAddress, AC97_MicVol, AC97_VOL_MAX);
    XAC97_WriteReg(BaseAddress, AC97_LineInVol, AC97_VOL_MAX);
  }
  else if( Loopback == AC97_DIGITAL_LOOPBACK )
    XAC97_WriteReg(BaseAddress, AC97_GeneralPurpose, AC97_GP_ADC_DAC_LOOPBACK);

} // end XAC97_InitAudio()


void XAC97_EnableInput(Xuint32 BaseAddress, Xuint8 InputType) {
  XAC97_WriteReg(BaseAddress, AC97_RecordGain, AC97_VOL_MAX);  

  if( InputType == AC97_MIC_INPUT ) 
    XAC97_WriteReg(BaseAddress, AC97_RecordSelect, AC97_RECORD_MIC_IN);
  else if( InputType == AC97_LINE_INPUT ) 
    XAC97_WriteReg(BaseAddress, AC97_RecordSelect, AC97_RECORD_LINE_IN);
}


void XAC97_DisableInput(Xuint32 BaseAddress, Xuint8 InputType) {
  XAC97_WriteReg(BaseAddress, AC97_RecordGain, AC97_VOL_MUTE);  
  
  if( InputType == AC97_MIC_INPUT ) 
    XAC97_WriteReg(BaseAddress, AC97_MicVol, AC97_VOL_MUTE);
  else if( InputType == AC97_LINE_INPUT ) 
    XAC97_WriteReg(BaseAddress, AC97_LineInVol, AC97_VOL_MUTE);
}


void XAC97_RecAudio(Xuint32 BaseAddress, Xuint32 StartAddress, 
		    Xuint32 EndAddress) {
  Xuint32 i;
  Xuint32 sample;
  volatile Xuint32 *sound_ptr = (Xuint32*)StartAddress;
  
  /** Enable VRA Mode **/
  XAC97_WriteReg(BaseAddress, AC97_ExtendedAudioStat, 1);

  /** Clear out the FIFOs **/
  XAC97_ClearFifos(BaseAddress);

  /** Wait until we receive the ready signal **/
  XAC97_AwaitCodecReady(BaseAddress);

  /** Volume settings **/
  XAC97_WriteReg(BaseAddress, AC97_MasterVol, AC97_VOL_MUTE);
  XAC97_WriteReg(BaseAddress, AC97_AuxOutVol, AC97_VOL_MUTE);
  XAC97_WriteReg(BaseAddress, AC97_MasterVolMono, AC97_VOL_MUTE);
  XAC97_WriteReg(BaseAddress, AC97_PCBeepVol, AC97_VOL_MUTE);
  XAC97_WriteReg(BaseAddress, AC97_PCMOutVol, AC97_VOL_MUTE);
    
  XAC97_WriteReg(BaseAddress, AC97_GeneralPurpose, AC97_GP_PCM_BYPASS_3D);
  
  /** Record the incoming audio **/
  while( sound_ptr < (Xuint32*)EndAddress ) {
    sample = XAC97_ReadFifo(BaseAddress);
    *sound_ptr = sample;
    sound_ptr++;
  }

} // end XAC97_RecAudio()



void XAC97_PlayAudio(Xuint32 BaseAddress, Xuint32 StartAddress, 
		     Xuint32 EndAddress){
  Xuint32 i;
  Xuint32 sample;
  volatile Xuint32 *sound_ptr = (Xuint32*)StartAddress;

  /** Wait for the ready signal **/
  XAC97_AwaitCodecReady(BaseAddress);

  /** Disable VRA Mode **/
  XAC97_WriteReg(BaseAddress, AC97_ExtendedAudioStat, 0);

  /** Play Volume Settings **/
  XAC97_WriteReg(BaseAddress, AC97_MasterVol, AC97_VOL_MAX); 
  XAC97_WriteReg(BaseAddress, AC97_AuxOutVol, AC97_VOL_MAX);
  XAC97_WriteReg(BaseAddress, AC97_MasterVolMono, AC97_VOL_MAX);
  XAC97_WriteReg(BaseAddress, AC97_PCBeepVol, AC97_VOL_MAX);
  XAC97_WriteReg(BaseAddress, AC97_PCMOutVol, AC97_VOL_MAX);
  XAC97_WriteReg(BaseAddress, AC97_LineInVol, AC97_VOL_MAX);
  XAC97_WriteReg(BaseAddress, AC97_MicVol, AC97_VOL_MAX);

  /** Clear FIFOs **/
  XAC97_ClearFifos(BaseAddress);
 
  while( sound_ptr < (Xuint32*)EndAddress ) {
    sample = *sound_ptr; 
    sound_ptr = sound_ptr + 1;
    XAC97_WriteFifo(BaseAddress, sample);
  }

  XAC97_ClearFifos(BaseAddress);
  
} // end XAC97_PlayAudio()


Xuint32 XAC97_ReadFifo(Xuint32 BaseAddress) {
  while(XAC97_isOutFIFOEmpty(BaseAddress));
  return XAC97_mGetOutFifoData(BaseAddress);
}

void XAC97_WriteFifo(Xuint32 BaseAddress, Xuint32 sample) {
  while(XAC97_isInFIFOFull(BaseAddress));
  XAC97_mSetInFifoData(BaseAddress, sample);
}

void XAC97_ClearFifos(Xuint32 BaseAddress) {
  Xuint32 i;
  XAC97_mSetControl(BaseAddress, AC97_CLEAR_FIFOS);
  for( i = 0; i < 512; i++ )
    XAC97_mSetInFifoData(BaseAddress, 0);
}
