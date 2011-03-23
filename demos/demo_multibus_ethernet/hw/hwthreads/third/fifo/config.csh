#!/bin/csh -f

###############################################################################
##
##    File Name:  config.csh         
##      Version:  1.2
##         Date:  2005-06-29
##      Project:  Parameterizable LocalLink FIFO
##
##      Company:  Xilinx, Inc.
##  Contributor:  Wen Ying Wei, Davy Huang
##
##   Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
##                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
##                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
##                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
##                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
##                APPLICATION OR STANDARD, XILINX IS MAKING NO
##                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
##                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
##                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
##                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
##                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
##                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
##                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
##                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
##                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
##                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
##                PURPOSE.
##                
##                (c) Copyright 2005 Xilinx, Inc.
##                All rights reserved.
##
###############################################################################

###############################################################################
## This is a shell script to setup environment on Solaris for Parameterizable
## LocalLink FIFO Reference Design
##
## Following these steps to setup the environment:
## (1) Install software tools (Xilinx ISE, ModelSim, etc.)
## (2) Modify all the lines containing "<...>" in this script
## (3) Run this script.
##
## A summary of environment variables follows.
## 
## Variables needs to be modified by user:
## setenv DUT_PATH         <Path_to_LL_FIFO_Reference_Design>
## setenv XILINX           <Path_to_Xilinx_ISE_software>
## setenv MODEL_TECH       <Path_to_ModelSim_installation>
## setenv MTI_LIBS         <Path_to_ModelSim_Sim_Library>
##
## Variables derive from above items:
## setenv LMC_FOUNDRY_HOME $LMC_HOME
## setenv LMC_PATH         $LMC_HOME/foundry
## setenv LMC_CONFIG       $LMC_HOME/data/solaris.lmc
## setenv MODEL_TECH_LIBSM $MODEL_TECH/sunos5/libsm.sl
## setenv MODELSIM         $DUT_PATH/simulation/modelsim_unix.ini
## setenv LD_LIBRARY_PATH  $XILINX/bin/sol:$XILINX_EDK/bin/sol:$LMC_HOME/lib/sun4Solaris.lib:${LD_LIBRARY_PATH}
## setenv PATH             $XILINX/bin/sol:$MODEL_TECH/sunos5:$LMC_HOME/bin:$XILINX_EDK/bin/sol:$XILINX_EDK/gnu/microblaze/sol/bin:$XILINX_EDK/gnu/powerpc-eabi/sol/bin:${PATH}
##
## Optional variables:
## setenv LM_LICENSE_FILE  ${LM_LICENSE_FILE}:<Port@LicenseServer>
###############################################################################

set xilinx_ver =	"G.37"
set mti_ver =           "5.8b"


#################################################################################
## Step 1: Set a variable to point to installation of this Reference Design
##
## For example:
## setenv DUT_PATH /home/user/work/LL_FIFO
#################################################################################

setenv DUT_PATH <LL_FIFO_ROOT>


#################################################################################
## Step 2: Setup Xilinx ISE Tool Environment
##
## For example:
## setenv XILINX    /tool/xilinx
## setenv LD_LIBRARY_PATH $XILINX/bin/sol:${LD_LIBRARY_PATH}
## setenv PATH $XILINX/bin/sol:${PATH}
#################################################################################

if $?XILINX then
	echo  "Xilinx ISE software environment ready."
else
	echo  "Setup Xilinx ISE software environment ..."
	
	setenv XILINX    <Path_to_Xilinx_ISE_software>

#	setenv XILINX    /build/sjxfndry/${xilinx_ver}/rtf

	
	setenv PATH $XILINX/bin/sol:${PATH}

	if ($?LD_LIBRARY_PATH) then
	    setenv LD_LIBRARY_PATH $XILINX/bin/sol:${LD_LIBRARY_PATH}
	else
	    setenv LD_LIBRARY_PATH $XILINX/bin/sol
	endif

endif



#################################################################################
## Step 3: Setup ModelSim Environment
##
## For example:
## setenv MODEL_TECH /tool/mentor/modeltech5.6e/
## setenv MODEL_TECH_LIBSM $MODEL_TECH/sunos5/libsm.sl
## setenv PATH $MODEL_TECH/sunos5:${PATH}
## setenv MODELSIM $DUT_PATH/test/func_sim/modelsim_unix.ini
##
## Note:       Environment variable MODELSIM points to the ModelSim
##             initialization file provided in the LocalLink Reference Design at 
##             $DUT_PATH/test/func_sim/modelsim_unix.ini
##             This file contains proper setup for SmartModels simulation
##             Refer to Xilinx Answer Record #15501 and #14019 for further
##             information regarding SmartModel/Swift Interface and
##             installation of SmartModels. 
##
#################################################################################
if $?MODEL_TECH then
	echo  "ModelSim environment ready."
else
	echo  "Setup ModelSim environment ..."

	setenv MODEL_TECH <Path_to_ModelSim_installation>
#	setenv MODEL_TECH /tools/packages/mentor/modelsim/${mti_ver}/sunos5
	
	setenv MODEL_TECH_LIBSM ${MODEL_TECH}/libsm.sl
	setenv PATH ${MODEL_TECH}:${PATH}
endif

setenv MODELSIM ${DUT_PATH}/test/func_sim/modelsim_unix.ini

#################################################################################
## Step 4: Setup User's Local Simulation Library Environment 
##
## MTI_LIBS    points to the directory that is used to store
##             Verilog/VHDL based ModelSim libraries for 
##             Virtex/Virtex-II Pro families, including unisim,
##             simprim and SmartModel libraries.
##
## For example:
## setenv MTI_LIBS /home/user/work/mti_libs
## 
#################################################################################
echo  "Setup local simulation library environment..."

setenv MTI_LIBS <Path_to_ModelSim_Sim_Library>



#################################################################################
## Step 5: Setup Tester Environment Variable
##
#################################################################################
setenv TESTER  ${DUT_PATH}/test/testbench/Tester


#################################################################################
## Step 6: If necessary, setup licenses for EDA tools. 
##
## For example:
##
## if $?LM_LICENSE_FILE then
##    setenv LM_LICENSE_FILE ${LM_LICENSE_FILE}:<Port@LicenseServer>
## else
##    setenv LM_LICENSE_FILE <Port@LicenseServer>
## endif
##
#################################################################################
echo  "Setup EDA tools licenses ..."


## ModelSIM
#setenv LM_LICENSE_FILE ${LM_LICENSE_FILE}:<port>@xmask

## Foundation  
#setenv LM_LICENSE_FILE ${LM_LICENSE_FILE}:<path>/license.dat


echo  "DONE."
echo  ""

