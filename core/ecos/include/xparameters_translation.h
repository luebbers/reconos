// determine which bus system to use by looking at which interrupt controller
// is present (OPB or XPS)
#if defined(XPAR_XPS_INTC_0_BASEADDR)
    #include <xparameters_translation_plbv46.h>
#elif defined(XPAR_OPB_INTC_0_BASEADDR)
    #include <xparameters_translation_plbv34.h>
#else
    #error "No XPS_INTC_0 or OPB_INTC_0 found!"
#endif

// ReconOS
#ifdef __RECONOS__
#include <xparameters_reconos.h>
#endif

