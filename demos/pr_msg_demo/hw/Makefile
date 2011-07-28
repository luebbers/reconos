#----------------------------------------------------------------------------
# CONFIGURATION AND CHECKS

PROJECT_FILE=../pr_msg_demo.rprj

include $(PROJECT_FILE)

ifeq ($(RECONOS),)
    $(error ReconOS environment variable $$RECONOS not defined)
endif

DYNAMIC_THREADS_NETLISTS=$(foreach t,$(DYNAMIC_THREADS),build/$(t).ngc)

#----------------------------------------------------------------------------
# HELP

help:
	@echo "Targets:"
	@echo "    all:"
	@echo "        create bitstreams for the complete reconfigurable hwdesign"
	@echo "    complete:"
	@echo "        like 'all'"
	@echo "    extensible-base:"
	@echo "        build base (initial) bitstreams for extensible hwdesign"
	@echo "    extensible-threads:"
	@echo "        build partial (dynamic) bitstreams for extensible hwdesign"
	@echo "    bits-static:"
	@echo "        create bitstream for a static design (using static threads)"
	@echo "    edk-static:"
	@echo "        just set up the static edk design (do not create netlists)"
	@echo "    netlist-static:"
	@echo "        generate all netlists for the static design"

#----------------------------------------------------------------------------
# SHORTCUTS

all: complete

complete: build/planahead-complete/planahead-complete.runs

extensible-base: build/planahead-base/planahead-base.runs

bits-static: build/edk/implementation/system.bit

edk-static: build/edk/system.mhs

netlist-static: build/edk/synthesis/system.ngc

#----------------------------------------------------------------------------
# TARGETS

include Makefile.hwthreads

build/edk/system.mhs:
	[ -d build ] || mkdir build
	prepedk -o build/edk -p ../pr_msg_demo.rprj -d

build/edk/synthesis/system.ngc: build/edk/system.mhs
	cd build/edk && xps -nw -scr $(RECONOS)/tools/tcl/make_netlist.tcl

# not applicable - this is a dynamic design
#
build/edk/implementation/system.bit: build/edk/synthesis/system.ngc
	$(error bits-static not appplicable - this is a dynamic design)
	cd build/edk && xps -nw -scr $(RECONOS)/tools/tcl/make_bits.tcl

build/planahead-complete/planahead-complete.runs: build/edk/synthesis/system.ngc $(DYNAMIC_THREADS_NETLISTS)
	rm -f `rinfo -p $(PROJECT_FILE) find_dynamic_wrapper_netlists`
	mkpatcl_partial.py -P build/planahead-complete -p $(PROJECT_FILE) -o build/pa-complete.tcl -r complete
	cd build && planAhead -mode batch -source pa-complete.tcl

build/planahead-base/planahead-base.runs: build/edk/synthesis/system.ngc $(DYNAMIC_THREADS_NETLISTS)
	rm -f `rinfo -p $(PROJECT_FILE) find_dynamic_wrapper_netlists`
	mkpatcl_partial.py -P build/planahead-base -p $(PROJECT_FILE) -o build/pa-base.tcl -r extensible-base
	cd build && planAhead -mode batch -source pa-base.tcl

extensible-threads:
	mkpatcl_partial.py -P build/planahead-base -p $(PROJECT_FILE) -o build/pa-threads.tcl -r extensible-threads
	cd build && planAhead -mode batch -source pa-threads.tcl

#----------------------------------------------------------------------------
# OTHER PHONY TARGETS

clean:
	rm -rf build 

.PHONY: clean all bits-static complete extensible-base extensible-threads bits-static netlist-static edk-static

