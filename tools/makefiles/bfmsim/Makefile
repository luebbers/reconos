#
# Makefile for automated bfm simulations (/tests/simulation/*)
#

# use PLBv46 by default
PLB_VER ?= "46"

bfmsim: 
	[ -d bfmsim ] || mkbfmsim.py -v -V $(PLB_VER) -e $(ENTITY) $(ENTITY).vhd > /dev/null
	cp scripts/* bfmsim/scripts
	make -f $(RECONOS)/tools/makefiles/bfmsim/Makefile.scripts -C bfmsim/scripts all
	#
	# Starting simulation
	#
	cd bfmsim/simulation/behavioral && echo "do ../../scripts/run_nogui.do" | vsim | grep -A 1 -i error; [ $$? -ne 0 ]
	#
	# Simulation finished
	#

bfmsim_gui: 
	[ -d bfmsim ] || mkbfmsim.py -v -V $(PLB_VER) -e $(ENTITY) $(ENTITY).vhd > /dev/null
	cp scripts/* bfmsim/scripts
	make -f $(RECONOS)/tools/makefiles/bfmsim/Makefile.scripts -C bfmsim/scripts all
	#
	# Starting simulation
	#
	cd bfmsim/simulation/behavioral && vsim -do ../../scripts/run.do
	#
	# Simulation finished
	#

clean:
	rm -rf bfmsim transcript
	make -f $(RECONOS)/tools/makefiles/bfmsim/Makefile.scripts -C scripts clean
	#
	# All is clean and tidy now.
	#

.PHONY: bfmsim clean
