#include "xparameters.h"
#include "xstatus.h"
#include "xmpmc.h"

static XMpmc	Mpmc;

int setStaticPHY() {
	XMpmc_Config *CfgPtr;
	int Status;
	Xuint32 RegValue, StaticRegValue;
	
	CfgPtr = XMpmc_LookupConfig(XPAR_MPMC_0_DEVICE_ID);
	if (CfgPtr == XNULL) {
		xil_printf("Error by init Cfgptr\r\n");
		return XST_FAILURE;
	}
	
	Status = XMpmc_CfgInitialize(&Mpmc, CfgPtr, CfgPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("Error by init \r\n");
		return XST_FAILURE;
	}
	
	/*
	 * Wait for the initial initialization sequence to be complete.
	 */
	while ((XMpmc_GetStaticPhyReg(&Mpmc) & XMPMC_SPIR_INIT_DONE_MASK) !=
						XMPMC_SPIR_INIT_DONE_MASK);
	
	//Now set the static phy reg so that the dcmtap is set to 40
	RegValue = 0x1500028;
	StaticRegValue = 0x60000000;
	XMpmc_SetStaticPhyReg(&Mpmc, RegValue | StaticRegValue);
	
	return XST_SUCCESS;
}

int main(void)
{
	setStaticPHY();
	
}