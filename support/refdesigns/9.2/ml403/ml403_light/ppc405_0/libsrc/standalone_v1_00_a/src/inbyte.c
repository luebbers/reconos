#include "xparameters.h"
#include "xuartns550_l.h"

#ifdef __cplusplus
extern "C" {
#endif
char inbyte(void);
#ifdef __cplusplus
}
#endif 

char inbyte(void) {
	 return XUartNs550_RecvByte(STDIN_BASEADDRESS);
}
