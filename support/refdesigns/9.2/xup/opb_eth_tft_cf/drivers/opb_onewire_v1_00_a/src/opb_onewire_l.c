//#include "xbasic_types.h"

//#include "xio.h"

//#include "xipif_v1_23_b.h"

#include "opb_onewire_l.h"



/************************** Constant Definitions ***************************/





/**************************** Type Definitions *****************************/





/************************** Function Prototypes ****************************/



void OneWire_GetHardwareAddrWithColons(Xuint32 ONEWIRE_BASEADDR, unsigned char* hw_addr);
void OneWire_GetHardwareAddr(Xuint32 ONEWIRE_BASEADDR, unsigned char* hw_addr);



/************************** Variable Definitions **************************/





/****************************************************************************/

/**

* This function returns the MAC address off the boards serial chip into the 

* passed in unsigned char pointer.  It loops until the CRC bit is high

*

* @param   char array of length 12 that will be used to store the returned 

*			hardware address spaced by colons and ending in a '/0'

*

* @return

*

* Void

*

* @note

*

* None

*

******************************************************************************/


void OneWire_GetHardwareAddrWithColons(Xuint32 ONEWIRE_BASEADDR, unsigned char* hw_addr) {

  Xuint32 high, low;



  do {

	low = XIo_In32((ONEWIRE_BASEADDR)+0);

	high = XIo_In32((ONEWIRE_BASEADDR)+4);

  } while (!(high & CRC_PASSED));

  hw_addr[0]=((char*)&high)[2];

  hw_addr[1]=':';

  hw_addr[2]=((char*)&high)[3];

  hw_addr[3]=':';

  hw_addr[4]=((char*)&low)[0];

  hw_addr[5]=':';

  hw_addr[6]=((char*)&low)[1];

  hw_addr[7]=':';

  hw_addr[8]=((char*)&low)[2];

  hw_addr[9]=':';

  hw_addr[10]=((char*)&low)[03];

  hw_addr[11] = '\0';



//  xil_printf("high=%8x low=%8x\r\n",high,low);

} 

// end GetHardwareAddrWithColons()



void OneWire_GetHardwareAddr(Xuint32 ONEWIRE_BASEADDR, unsigned char* hw_addr) {

  Xuint32 high, low;



  do {

	low = XIo_In32((ONEWIRE_BASEADDR)+0);

	high = XIo_In32((ONEWIRE_BASEADDR)+4);

//	xil_printf("high=%8x low=%8x\r\n",high,low);

  } while (!(high & CRC_PASSED));

  hw_addr[0]=((char*)&high)[2];

  hw_addr[1]=((char*)&high)[3];

  hw_addr[2]=((char*)&low)[0];

  hw_addr[3]=((char*)&low)[1];

  hw_addr[4]=((char*)&low)[2];

  hw_addr[5]=((char*)&low)[3];



//  xil_printf("high=%8x low=%8x\r\n",high,low);

} 

// end GetHardwareAddr()