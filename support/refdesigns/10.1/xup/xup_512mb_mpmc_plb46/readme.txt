This design contains the plb_v46 with the mpmc_v4.03 memory controller.
The parameters and settings apply to the XUP board with the 512MB RAM Modul from Kingston(KVR266x64c25/512).
To configure the mpmc right (to work with this RAM modul), a dcm with a phaseshift of 40 is connected to the mpmc. Also the static phy register is set correctly (i.e. the dcm tap value, which cannot be set via vhdl parameters). This is done by adding the program "calibration" to the bitstream, so that it can be executed directly after programming the FPGA.
After that initialization, the mpmc works correct and every other executable can be executed.   
