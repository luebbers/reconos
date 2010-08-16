##############################################################################
## Filename:          /home/luebbers/work/plb46/bfmsim_9.2/pcores/xps_osif_v2_01_a/devl/bfmsim/bfm_sim_xps.make
## Description:       Custom Makefile for EDK BFM Simulation Only
## Date:              Thu Jul 23 14:47:35 2009 (by Create and Import Peripheral Wizard)
##############################################################################


include bfm_system_incl.make

BRAMINIT_ELF_FILE_ARGS = 

BFC_CMD = xilbfc -plbv46

BFL_SCRIPTS = \
	sample.bfl

BFM_SCRIPTS = \
	scripts/sample.do

DO_SCRIPT = scripts/run.do

############################################################
# EXTERNAL TARGETS
############################################################

bfl: $(BFM_SCRIPTS)

sim: $(BEHAVIORAL_SIM_SCRIPT) $(BFM_SCRIPTS)
	@echo "*********************************************"
	@echo "Start BFM simulation ..."
	@echo "*********************************************"
	cd simulation/behavioral; \
	$(SIM_CMD) -do ../../$(DO_SCRIPT) -gui &

simmodel: $(BEHAVIORAL_SIM_SCRIPT)

clean: simclean

simclean:
	rm -rf $(BFM_SCRIPTS); \
	rm -rf simulation/behavioral

############################################################
# BEHAVIORAL SIMULATION GENERATION FLOW
############################################################

$(BEHAVIORAL_SIM_SCRIPT): $(MHSFILE)
	@echo "*********************************************"
	@echo "Create behavioral simulation models ..."
	@echo "*********************************************"
	simgen $(MHSFILE) $(SIMGEN_OPTIONS) -m behavioral

$(BFM_SCRIPTS): scripts/$(BFL_SCRIPTS)
	@echo "*********************************************"
	@echo "Compile bfl script(s) for BFM simulation ..."
	@echo "*********************************************"
	cd scripts; \
	$(BFC_CMD) $(BFL_SCRIPTS)


