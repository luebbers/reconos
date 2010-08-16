##############################################################################
## Description:       Custom Makefile for EDK BFM Simulation Only
## Date:              Tue Aug  1 12:52:05 2006 (by Create and Import Peripheral Wizard)
##############################################################################


include bfm_system_incl.make

BRAMINIT_ELF_FILE_ARGS = 

SUBMODULE_OPT = -lp ../../../../../

BFC_CMD = xilbfc

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
	rm -rf $(BFM_SCRIPTS)

simclean:
	rm -rf simulation/behavioral

############################################################
# BEHAVIORAL SIMULATION GENERATION FLOW
############################################################

$(BEHAVIORAL_SIM_SCRIPT): $(MHSFILE)
	@echo "*********************************************"
	@echo "Create behavioral simulation models ..."
	@echo "*********************************************"
	simgen $(MHSFILE) $(SIMGEN_OPTIONS) -m behavioral

$(BFM_SCRIPTS):
	@echo "*********************************************"
	@echo "Compile bfl script(s) for BFM simulation ..."
	@echo "*********************************************"
	cd scripts; \
	$(BFC_CMD) $(BFL_SCRIPTS)


