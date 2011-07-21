#
# \file Makefile
#
# Reconos design creation + eapr design flow
#
# \author Enno Luebbers <luebbers@reconos.de>
# \date   06.08.2010
#
#---------------------------------------------------------------------------
# %%%RECONOS_COPYRIGHT_BEGIN%%%
# 
# This file is part of ReconOS (http://www.reconos.de).
# Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
# All rights reserved.
# 
# ReconOS is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
# 
# ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along
# with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
# 
# %%%RECONOS_COPYRIGHT_END%%%
#---------------------------------------------------------------------------
#

ifeq ($(RECONOS),)
    $(error ReconOS environment variable $$RECONOS not defined)
endif

# find used Xilinx tools version (from ISE)
XILINX_VER = $(shell cat $(XILINX)/fileset.txt | grep version | tail -1 | sed "s/.*version=\([0-9]\+\.[0-9]\+\).*/\1/")

# the ReconOS project file
PROJECT_FILE ?= $(shell find .. -iname "*.rprj*" | tail -1 )
PROJECT_ROOT ?= ..
# location of the base design (EDK project)
EDK_BASE_DIR ?= $(RECONOS)/support/refdesigns/$(XILINX_VER)/xup/xup_light
# the fpga layout file
LAYOUT ?= hw/layout.lyt
# the hw thread directory
HW_THREAD_DIR ?= hwthreads
# options to par
PAROPTS ?= -ol high -w

#reconos version to use
RECONOS_VER ?= v2_01_a

# osif and library versions
PCORE_OSIF=$(RECONOS)/core/pcores/xps_osif_$(OSIF_VER) $(RECONOS)/core/pcores/plb_osif_$(OSIF_VER) $(RECONOS)/core/pcores/osif_core_$(OSIF_VER)
PCORE_RECONOS=$(RECONOS)/core/pcores/reconos_*
# fifo cores
PCORE_FIFO=$(RECONOS)/core/pcores/mbox_fifo_v1_01_a
# burst ram cores
PCORE_BURSTRAM=$(RECONOS)/core/pcores/burst_ram_*
# MGT protector (for V4FX engineering samples)
PCORE_MGTPROTECTOR=$(RECONOS)/support/pcores/v4_mgt_protector_v1_00_a
# the number of reconos osifs/slots that are dynamic
# if no dynamic threads are specified, set this to 0 (static only)
ifeq ($(DYNAMIC_THREADS),)
    NUM_DYNAMIC_OSIFS=0
else
    NUM_DYNAMIC_OSIFS=$(shell grep -i "^\s*slot" $(PROJECT_ROOT)/$(LAYOUT) | wc -l)
endif
# the number of reconos osifs/slots that are static (always present)
NUM_STATIC_OSIFS=$(shell echo $(STATIC_THREADS) | wc -w)
# the total number of OSIFs
NUM_OSIFS=$(shell echo "$$(($(NUM_DYNAMIC_OSIFS) + $(NUM_STATIC_OSIFS)))")
# the target FPGA's family (for determining bus macro locations and names)
TARGET_FAMILY=$(shell grep -i "\s*family" $(PROJECT_ROOT)/$(LAYOUT) | sed "s/^\s*family //")
BUFG_WRAPPER_PATTERN?=: bufg_logic_.*_wrapper
BUFG_WRAPPER_REPLACE?=: BUFG

ifeq ($(NUM_OSIFS),0)
    $(error NUM_OSIFS is 0! Have you specified threads [static/dynamic] and slots [dynamic]?)
endif


# location of the tools and files we need
ADDOSIF=$(RECONOS)/tools/python/mhsaddosif.py
ADDDRIVER=$(RECONOS)/tools/python/mssadddriver.py
ADDTHREAD=$(RECONOS)/tools/python/mhsaddthread.py
MKHWTHREAD=$(RECONOS)/tools/python/mkhwthread.py
MAKETOP=$(RECONOS)/tools/python/maketop.py
MAKEUCF=$(RECONOS)/tools/python/makeucf.py
BUSMACROS=$(RECONOS)/attic/busmacros/$(TARGET_FAMILY)
BUSMACRO_LIB=busmacro_$(TARGET_FAMILY)
MAKE_BITS=$(RECONOS)/tools/makefiles/eapr/make_bits.tcl
MAKE_NETLIST=$(RECONOS)/tools/makefiles/eapr/make_netlist.tcl
XPS=xps
XST=xst
NGDBUILD=ngdbuild
MAP=map
PAR=par
DUMMY_THREAD_VHDL=$(RECONOS)/support/threads/dummy_ul.vhd
PR_VERIFYDESIGN=PR_verifydesign
PR_ASSEMBLE=PR_assemble
MAKE_LOG=$(shell pwd)/make.log
PLANAHEAD=planAhead
MAKE_PA_TCL_PARTIAL=$(RECONOS)/tools/python/mkpatcl_partial.py
PA_SCRIPT=pa_partial.tcl

########################################################
# beautify output
#
# For every (more complicated) executable, there is a
# macro QUIET_<name_of_executable>), which prints out a
# more beautiful version of the command line and then
# invokes the command. By using 
#
#      $($(QQ)MYCOMMAND)
#
# instead of
#
#      $(MYCOMMAND)
#
# we can pretty-print the output dependant on the QQ macro
# (set to "QUIET_" for quiet output, or to nothing for
# verbose).
# Also, we hide the regular output by setting $(Q) to '@'.
#
ifeq ($(BUILD_VERBOSE),1)
  Q =
  QQ = 
else
  Q = @
  QQ = QUIET_
endif

QUIET_ADDOSIF=     echo "    ADDOSIF     $@"; $(ADDOSIF)
QUIET_ADDDRIVER=   echo "    ADDDRIVER   $@"; $(ADDDRIVER)
QUIET_ADDTHREAD=   echo "    ADDTHREAD   $@"; $(ADDTHREAD)
QUIET_MKHWTHREAD=  echo "    MKHWTHREAD  $@"; $(MKHWTHREAD)
QUIET_MAKETOP=     echo "    MAKETOP     $@"; $(MAKETOP)
QUIET_MAKEUCF=     echo "    MAKEUCF     $@"; $(MAKEUCF)
QUIET_MAKE_PA_TCL_PARTIAL= echo "    MAKE_PA_TCL_PARTIAL $@"; $(MAKE_PA_TCL_PARTIAL)
QUIET_XPS    =     echo "    XPS         $@"; $(XPS)
QUIET_XST    =     echo "    XST         $@"; $(XST)
QUIET_NGDBUILD=    echo "    NGDBUILD    $@"; $(NGDBUILD)
QUIET_MAP    =     echo "    MAP         $@"; $(MAP)
QUIET_PAR    =         echo "    PAR         $@"; $(PAR)
QUIET_PR_VERIFYDESIGN= echo "    PR_VERIFY   $@"; $(PR_VERIFYDESIGN)
QUIET_PR_ASSEMBLE=     echo "    PR_ASSEMBLE $@"; $(PR_ASSEMBLE)
QUIET_PLANAHEAD =      echo "    PLANAHEAD   $@"; $(PLANAHEAD)

export Q QQ NUM_OSIFS NUM_DYNAMIC_OSIFS RECONOS_VER DYNAMIC_THREADS



all: planahead-all

# pseudo-targets to match mkpatcl_partial.py's recipe names
complete: planahead-all

extensible-base: planahead-base

extensible-threads: planahead-threads

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
	

	

edk-base:
	#
	####################################################################
	#
	# edk-base:
	#     - create a link to the reference design 
	#
	$(Q)ln -s $(EDK_BASE_DIR) edk-base

edk-static: edk-static/system.mhs

edk-static/system.mhs: edk-base
	#
	####################################################################
	#
	# edk-static:
	#     - make a copy of the edk-base directory -> edk-static
	#     - add $(NUM_OSIFS) OSIFs and dummy threads to the hw design
	#     - add OSIF drivers
	#     - link/create pcores (OSIF, reconos, dummy threads)
	#
	$(Q)cp -r edk-base/ edk-static
	$(Q)$($(QQ)ADDOSIF) edk-static/system.mhs $(NUM_OSIFS) $(ADDOSIF_OPTS) > system.mhs.osif
	$(Q)$($(QQ)ADDTHREAD) $(ADDTHREAD_OPTS) system.mhs.osif > edk-static/system.mhs
	$(Q)rm -f system.mhs.osif
	$(Q)$($(QQ)ADDDRIVER) edk-static/system.mss $(NUM_OSIFS) > system.mss.osif
	$(Q)mv -f system.mss.osif edk-static/system.mss
	$(Q)[ -d edk-static/pcores ] || mkdir edk-static/pcores
	$(Q)ln -s $(PCORE_OSIF) $(PCORE_RECONOS) $(PCORE_FIFO) $(PCORE_BURSTRAM) $(PCORE_MGTPROTECTOR) edk-static/pcores/.
	$(Q)cd edk-static/pcores; for i in $$(seq 1 $(NUM_OSIFS)); do\
	    $($(QQ)MKHWTHREAD) dummy_ul $$i $(DUMMY_THREAD_VHDL) >> $(MAKE_LOG);\
	done

static-threads: edk-static/system.mhs
	#
	######################################################################
	#
	# static-threads:
	#	- link static hardware threads into pcore directory
	#	  
	$(Q)for t in $(STATIC_THREADS); do make -C hwthreads/$$t clean; done
	$(Q)cd edk-static/pcores && c=$(NUM_DYNAMIC_OSIFS) && for t in $(STATIC_THREADS); do\
	    c=$$(($$c+1)) &&\
	    rm -rf hw_task_v1_0$${c}_b &&\
	    make -C ../../hwthreads/$$t hw_task_v1_0$${c}_b &&\
	    ln -s ../../hwthreads/$$t/hw_task_v1_0$${c}_b .;\
	done
	$(Q)touch static-threads


netlist-static: edk-static/synthesis/system.ngc

edk-static/synthesis/system.ngc: static-threads
	#
	####################################################################
	#
	# netlist-static:
	#     - build netlist with static and dummy threads
	#     - generate libs (-> libxil.a, xparameters.h, etc.)
	#
	$(Q)cp -f $(MAKE_NETLIST) edk-static
	$(Q)cd edk-static && $($(QQ)XPS) -nw -scr $(MAKE_NETLIST) | tee -a $(MAKE_LOG) | grep -s ERROR; [ $$? -ne 0 ] 


bits-static: static-threads
	#
	######################################################################
	#
	# bits-static:
	#     - implement purely static design
	#
	$(Q)[ $(NUM_DYNAMIC_OSIFS) -eq 0 ] || echo -e "ERROR: You have dynamic threads, but want to build a purely static design.\n       Use 'make all' instead."
	$(Q)[ $(NUM_DYNAMIC_OSIFS) -eq 0 ]
	$(Q)cp -f $(MAKE_BITS) edk-static
	$(Q)cd edk-static && $($(QQ)XPS) -nw -scr $(MAKE_BITS) | tee -a $(MAKE_LOG) | grep -s ERROR; [ $$? -ne 0 ]


remove-dummy-netlists: edk-static/synthesis/system.ngc
	#
	######################################################################
	#
	# remove-dummy-netlists:
	#     - remove netlists for dummy threads to prepare for partial
	#       reconfiguration flow
	#
	$(Q)for s in $$(seq 0 $$(($(NUM_DYNAMIC_OSIFS)-1))); do\
	    rm -f edk-static/implementation/hw_task_$${s}_wrapper.ngc;\
	done;


dynamic-threads-netlists:
	#
	######################################################################
	#
	# dynamic-threads-netlists:
	#     - build netlists for dynamic threads
	#
	$(Q)make -C $(PROJECT_ROOT)/$(HW_THREAD_DIR) all >> $(MAKE_LOG)
	$(Q)touch dynamic-threads-netlists


planahead-all: remove-dummy-netlists dynamic-threads-netlists
	#
	####################################################################
	#
	# planahead-all:
	#     - run PlanAhead to generate all bitstreams
	#	This creates all static and dynamic bitstreams in a
	#       single run
	#
	$(Q)$($(QQ)MAKE_PA_TCL_PARTIAL) -p $(PROJECT_FILE) -o $(PA_SCRIPT) -r complete >> $(MAKE_LOG)
	$(Q)$($(QQ)PLANAHEAD) -mode batch -source $(PA_SCRIPT) >> $(MAKE_LOG)
	$(Q)touch planahead-all


planahead-base: remove-dummy-netlists dynamic-threads-netlists
	#
	####################################################################
	#
	# planahead-base:
	#     - prepare base design and implement static part and first
	#       configuration (config_1). 
	#       This forms the base (static part) for incrementally
	#       built ReconOS systems.
	#
	$(Q)$($(QQ)MAKE_PA_TCL_PARTIAL) -p $(PROJECT_FILE) -o $(PA_SCRIPT) -r extensible-base >> $(MAKE_LOG)
	$(Q)$($(QQ)PLANAHEAD) -mode batch -source $(PA_SCRIPT) >> $(MAKE_LOG)
	$(Q)touch planahead-base


planahead-threads: 
	#
	####################################################################
	#
	# planahead-threads:
	#     - build partial bitstreams of an extensible ReconOS project
	#       Requires a completed planahead-base design
	#
	$(Q)$($(QQ)MAKE_PA_TCL_PARTIAL) -p $(PROJECT_FILE) -o $(PA_SCRIPT) -r extensible-threads >> $(MAKE_LOG)
	$(Q)$($(QQ)PLANAHEAD) -mode batch -source $(PA_SCRIPT) >> $(MAKE_LOG)



.PHONY:	clean hwclean planahead-threads

clean: hwclean

eapr-clean:
	

hwclean:
	rm -f  edk-base eapr-modules eapr-setup static-threads planahead-all planahead-base planahead-threads dynamic-threads-netlists
	rm -rf edk-static
	rm -rf project_reconos_1
	rm -rf base
	rm -rf top
	rm -rf prms
	rm -rf merges
	rm -f $(MAKE_LOG)
	make -C $(PROJECT_ROOT)/$(HW_THREAD_DIR) clean



###################################################
###################################################
###################################################
###################################################
###################################################
###################################################
#--------------------------------------------------
# steps below are DEPRECATED
#--------------------------------------------------
###################################################
###################################################
###################################################
###################################################
###################################################
###################################################

eapr-setup: netlist-static
	#
	####################################################################
	#
	# Step 3:
	#     - modify toplevel vhdl description (system.vhd), insert and 
	#       connect busmacros, etc.
	#     - modify ucf
	#     - create netlists (modules, toplevel)
	#
	#     => family: $(TARGET_FAMILY)
	#     => busmacros: $(BUSMACROS)
	$(Q)[ $(NUM_DYNAMIC_OSIFS) -gt 0 ] || echo -e "ERROR: You have no dynamic threads/slots, but want to build a dynamic design.\n       Use 'make bits-static' instead."
	$(Q)[ $(NUM_DYNAMIC_OSIFS) -gt 0 ]
	$(Q)cp $(LAYOUT) edk-static/data/$(LAYOUT)
	$(Q)cp edk-static/hdl/system.vhd edk-static/hdl/system.edk.vhd
	$(Q)cd edk-static/hdl && $($(QQ)MAKETOP) $(MAKETOP_OPTS) -l ../data/$(LAYOUT) system.vhd >> $(MAKE_LOG)
	cd edk-static/hdl && cp system.vhd system.vhd.sedsave && sed "s/$(BUFG_WRAPPER_PATTERN)/$(BUFG_WRAPPER_REPLACE)/" system.vhd.sedsave > system.vhd
	$(Q)cd edk-static/data && $($(QQ)MAKEUCF) -o pr.ucf -l $(LAYOUT) -t ../hdl/system.vhd system.ucf >> $(MAKE_LOG)
	$(Q)cp $(BUSMACROS)/*.nmc edk-static/implementation/.
	$(Q)cp $(BUSMACROS)/*.vhd edk-static/hdl/.
	$(Q)echo "vhdl $(BUSMACRO_LIB) ../hdl/$(BUSMACRO_LIB)_pkg.vhd" >> edk-static/synthesis/system_xst.prj
	$(Q)cd edk-static/synthesis && $($(QQ)XST) -ifn system_xst.scr >> $(MAKE_LOG)
	$(Q)touch eapr-setup
	
top: eapr-setup
	#
	####################################################################
	#
	# Step 4:
	#     - create the top directory
	#
	$(Q)mkdir -p top
	$(Q)cd top && cp ../edk-static/implementation/system.ngc top.ngc
	$(Q)cd top && cp ../edk-static/data/pr.ucf top.ucf
	
base: top
	#
	####################################################################
	#
	# Step 5:
	#     - create the base directory
	#     - copy netlists (see Step 2) and busmacros to the base 
	#       directory
	#     - remove dummy hw thread netlists for all dynamic slots
	#     - implement the base design (the part that does not change 
	#       during reconfiguration)
	#
	$(Q)mkdir base
	$(Q)find edk-static/implementation/ -iname "*.ngc" -exec cp {} base/. \;
	$(Q)find edk-static/implementation/ -iname "*.edf" -exec cp {} base/. \;
	$(Q)find edk-static/implementation/ -iname "*.edn" -exec cp {} base/. \;
	$(Q)find edk-static/implementation/ -iname "*.ngo" -exec cp {} base/. \;
	$(Q)find edk-static/implementation/ -iname "*.nmc" -exec cp {} base/. \;
	$(Q)for s in $$(seq 0 $$(($(NUM_DYNAMIC_OSIFS)-1))); do\
	    rm -f base/system.ngc base/hw_task_$${s}_wrapper.ngc;\
	done;
	$(Q)cp top/top.ucf base/.
	$(Q)cd base && $($(QQ)NGDBUILD) -uc top.ucf -modular initial ../top/top.ngc >> $(MAKE_LOG)
	$(Q)cd base && $($(QQ)MAP) $(MAPOPTS) top.ngd >> $(MAKE_LOG)
	$(Q)cd base && $($(QQ)PAR) $(PAROPTS) top.ncd base_routed.ncd >> $(MAKE_LOG)
	
eapr-modules: base
	#
	####################################################################
	#
	# Step 6:
	#     - enter $(HW_THREAD_DIR) and run make in order to build the hw
	#       thread netlists for all dynamic threads
	#     - for each dynamic OSIF s, and each dynamic thread t implement the 
	#       module and move it to prms/prmN_M/prmN_M_routed.ncd
	#
	$(Q)test -f $(LAYOUT)
	$(Q)make -C $(HW_THREAD_DIR) dynamic
	$(Q)[ -d prms ] || mkdir prms
	$(Q)cd $(HW_THREAD_DIR)/netlists && for s in $$(seq 0 $$(($(NUM_DYNAMIC_OSIFS)-1))); do\
		for t in $(DYNAMIC_THREADS); do\
			( [ -d ../../prms/prm$${s}_$$t ] || mkdir ../../prms/prm$${s}_$$t ) &&\
			cp $$t/hw_task_$${s}_wrapper.ngc ../../prms/prm$${s}_$$t &&\
			cp $(BUSMACROS)/*.nmc ../../prms/prm$${s}_$$t &&\
			cp ../../base/static.used ../../prms/prm$${s}_$$t/arcs.exclude &&\
			cp ../../top/top.ucf ../../prms/prm$${s}_$$t &&\
			cd ../../prms/prm$${s}_$$t &&\
			$($(QQ)NGDBUILD) -uc top.ucf -modular module -active hw_task_$${s}_wrapper ../../top/top.ngc >> $(MAKE_LOG) &&\
			$($(QQ)MAP) $(MAPOPTS) top.ngd >> $(MAKE_LOG) &&\
			$($(QQ)PAR) $(PAROPTS) top.ncd prm$${s}_$${t}_routed.ncd >> $(MAKE_LOG) &&\
			cd ../../$(HW_THREAD_DIR)/netlists && pwd;\
		done;\
	done;
	$(Q)touch eapr-modules

merges: eapr-modules
	#
	####################################################################
	#
	# Step 7:
	#     - merge base system and reconfigurable modules
	#     - for each OSIF N, and each thread M place the merged designs
	#	and the bitstreams into merges/prmN_M
	#
	$(Q)[ -d merges ] || mkdir merges
	$(Q)cd prms && for d in *; do\
		( [ -d ../merges/$$d ] || mkdir ../merges/$$d ) &&\
		cd ../merges/$$d &&\
		cp ../../base/base_routed.ncd . &&\
		cp ../../prms/$$d/$${d}_routed.ncd . &&\
		$($(QQ)PR_VERIFYDESIGN) base_routed.ncd $${d}_routed.ncd >> $(MAKE_LOG) &&\
		$($(QQ)PR_ASSEMBLE) base_routed.ncd $${d}_routed.ncd >> $(MAKE_LOG) &&\
		cd ../../prms;\
	done
	#
	# Bitstream assembly finished.
	#
		
	

static-eapr: static-threads
	#
	######################################################################
	#
	# eapr-static: implement static design with bus macros for timing
	#              analysis
	#	- build static netlist
	#	- modify top level HDL and UCF files
	#	- add bus macro libraries and netlists
	#	- resynthesize toplevel design
	#	- translate, map, place and route design
	#
	$(Q)cd edk-static && $($(QQ)XPS) -nw -scr $(MAKE_NETLIST) | tee -a $(MAKE_LOG) | grep -s ERROR; [ $$? -ne 0 ] 
	$(Q)cd edk-static/hdl && $($(QQ)MAKETOP) $(MAKETOP_OPTS) -l ../../pr_demo.lyt system.vhd >> $(MAKE_LOG)
	$(Q)cd edk-static/data && [ -f system.ucf.bak ] || cp system.ucf system.ucf.bak
	$(Q)cd edk-static/data && $($(QQ)MAKEUCF) -s -o system.ucf -l ../../pr_demo.lyt -t ../hdl/system.vhd system.ucf.bak >> $(MAKE_LOG)
	$(Q)cp $(BUSMACROS)/*.vhd edk-static/hdl/.
	$(Q)echo "vhdl $(BUSMACRO_LIB) ../hdl/$(BUSMACRO_LIB)_pkg.vhd" >> edk-static/synthesis/system_xst.prj
	$(Q)cd edk-static/synthesis && $($(QQ)XST) -ifn system_xst.scr >> $(MAKE_LOG)
	$(Q)cp $(BUSMACROS)/*.nmc edk-static/implementation/.
	$(Q)cd edk-static/implementation && $($(QQ)NGDBUILD) -uc ../data/system.ucf system.ngc >> $(MAKE_LOG)
	$(Q)cd edk-static/implementation && $($(QQ)MAP) $(MAPOPTS) system.ngd >> $(MAKE_LOG)
	$(Q)cd edk-static/implementation && $($(QQ)PAR) $(PAROPTS) system.ncd system_routed_static-eapr.ncd >> $(MAKE_LOG)


