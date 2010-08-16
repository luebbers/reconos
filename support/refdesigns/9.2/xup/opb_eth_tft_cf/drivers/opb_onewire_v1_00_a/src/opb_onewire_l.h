#ifndef OPB_ONEWIRE_L_H /* prevent circular inclusions */
#define OPB_ONEWIRE_L_H /* by using protection macros */

/***************************** Include Files ********************************/

#include "xbasic_types.h"

/************************** Constant Definitions ****************************/

#define ETH_ADDR_LEN_PLUS_COLONS 12

#define ETH_ADDR_LEN 6

#define CRC_PASSED 0x2000000

/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Function Prototypes *****************************/


void OneWire_GetHardwareAddrWithColons(Xuint32 ONEWIRE_BASEADDR, unsigned char* hw_addr);
void OneWire_GetHardwareAddr(Xuint32 ONEWIRE_BASEADDR, unsigned char* hw_addr);

#endif            /* end of protection macro */
