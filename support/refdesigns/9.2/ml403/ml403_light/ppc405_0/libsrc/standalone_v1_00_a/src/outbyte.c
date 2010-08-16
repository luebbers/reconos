#include "xparameters.h"
#include "xuartns550_l.h"

#ifdef __cplusplus
extern "C" {
#endif
void outbyte(char c); 

#ifdef __cplusplus
}
#endif 

void outbyte(char c) {
	 XUartNs550_SendByte(STDOUT_BASEADDRESS, c);
}
