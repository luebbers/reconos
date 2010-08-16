# Reconos design creation + eapr design flow

ifeq ($(RECONOS),)
    $(error ReconOS environment variable $$RECONOS not defined)
endif

# find used Xilinx tools version (from ISE)
XILINX_VER = $(shell cat $(XILINX)/fileset.txt | grep version | tail -1 | sed "s/.*version=\([0-9]\+\.[0-9]\+\).*/\1/")

# location of the base design (EDK project)
EDK_BASE_DIR ?= $(RECONOS)/support/refdesigns/$(XILINX_VER)/xup/eth_tft_cf
# the fpga layout file
LAYOUT ?= layout.lyt
# the hw thread directory
HW_THREAD_DIR ?= hwthreads
# options to par
PAROPTS ?= -ol high -w

#reconos version to use
RECONOS_VER ?= v2_01_a

# osif and library versions
PCORE_OSIF=$(RECONOS)/core/pcores/osif_$(RECONOS_VER) $(RECONOS)/core/pcores/plb_osif_$(RECONOS_VER) $(RECONOS)/core/pcores/osif_core_$(RECONOS_VER)
PCORE_RECONOS=$(RECONOS)/core/pcores/reconos_$(RECONOS_VER)
# fifo cores
PCORE_FIFO=$(RECONOS)/core/pcores/mbox_fifo_v1_01_a
# burst ram cores
PCORE_BURSTRAM=$(RECONOS)/core/pcores/burst_ram_$(RECONOS_VER)
# the number of reconos osifs/slots
NUM_OSIFS=$(shell grep -i "^slot" $(LAYOUT) | wc -l)

# location of the tools and files we need
ADDOSIF=$(RECONOS)/tools/python/mhsaddosif.py
ADDDRIVER=$(RECONOS)/tools/python/mssadddriver.py
ADDTHREAD=$(RECONOS)/tools/python/mhsaddthread.py
MKHWTHREAD=$(RECONOS)/tools/python/mkhwthread.py
MAKETOP=$(RECONOS)/tools/python/maketop.py
MAKEUCF=$(RECONOS)/tools/python/makeucf.py
BUSMACROS=$(RECONOS)/attic/busmacros/xc2vp
BUSMACRO_LIB=busmacro_xc2vp
MAKE_BITS=$(RECONOS)/tools/makefiles/eapr/make_bits.tcl
MAKE_NETLIST=$(RECONOS)/tools/makefiles/eapr/make_netlist.tcl
XPS=xps
XST=xst
NGDBUILD=ngdbuild
MAP=map
PAR=par
DUMMY_THREAD_VHDL=$(RECONOS)/core/samples/dummy_ul.vhd
PR_VERIFYDESIGN=PR_verifydesign
PR_ASSEMBLE=PR_assemble
MAKE_LOG=$(shell pwd)/make.log

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
QUIET_XPS    =     echo "    XPS         $@"; $(XPS)
QUIET_XST    =     echo "    XST         $@"; $(XST)
QUIET_NGDBUILD=    echo "    NGDBUILD    $@"; $(NGDBUILD)
QUIET_MAP    =     echo "    MAP         $@"; $(MAP)
QUIET_PAR    =         echo "    PAR         $@"; $(PAR)
QUIET_PR_VERIFYDESIGN= echo "    PR_VERIFY   $@"; $(PR_VERIFYDESIGN)
QUIET_PR_ASSEMBLE=     echo "    PR_ASSEMBLE $@"; $(PR_ASSEMBLE)

export Q QQ NUM_OSIFS RECONOS_VER



all: merges

help:
	@echo "Targets:"
	@echo "    all:"
	@echo "        create bitstreams for the complete reconfigurable hwdesign"
	@echo "    bits-static:"
	@echo "        create bitstream for the static design (using dummy threads)"
	@echo "    edk-static:"
	@echo "        just set up the static edk design (do not create netlists)"
	

edk-base:
	#
	####################################################################
	#
	# Step 0:
	#     - create a link to the reference design 
	#
	$(Q)ln -s $(EDK_BASE_DIR) edk-base

edk-static: edk-base
	#
	####################################################################
	#
	# Step 1:
	#     - make a copy of the edk-base directory -> edk-static
	#     - add $(NUM_OSIFS) OSIFs and dummy threads to the hw design
	#     - add OSIF drivers
	#     - link/create pcores (OSIF, reconos, dummy threads)
	#
	$(Q)test -f $(LAYOUT)
	$(Q)cp -r edk-base/ edk-static
	$(Q)$($(QQ)ADDOSIF) edk-static/system.mhs $(NUM_OSIFS) > system.mhs.osif
	$(Q)$($(QQ)ADDTHREAD) system.mhs.osif > edk-static/system.mhs
	$(Q)rm -f system.mhs.osif
	$(Q)$($(QQ)ADDDRIVER) edk-static/system.mss $(NUM_OSIFS) > system.mss.osif
	$(Q)mv -f system.mss.osif edk-static/system.mss
	$(Q)[ -d edk-static/pcores ] || mkdir edk-static/pcores
	$(Q)ln -s $(PCORE_OSIF) $(PCORE_RECONOS) $(PCORE_FIFO) $(PCORE_BURSTRAM) edk-static/pcores/.
	$(Q)cd edk-static/pcores; for i in $$(seq 1 $(NUM_OSIFS)); do\
	    $($(QQ)MKHWTHREAD) dummy_ul $$i $(DUMMY_THREAD_VHDL) >> $(MAKE_LOG);\
	done

netlist-static: edk-static
	#
	####################################################################
	#
	# Step 2:
	#     - build netlist with dummy threads
	#     - generate libs (-> libxil.a, xparameters.h, etc.)
	#
	$(Q)cp -f $(MAKE_NETLIST) edk-static
	$(Q)cd edk-static && $($(QQ)XPS) -nw -scr $(MAKE_NETLIST) | tee -a $(MAKE_LOG) | grep -s ERROR; [ $$? -ne 0 ] 
	$(Q)touch netlist-static

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
	$(Q)cp $(LAYOUT) edk-static/data/$(LAYOUT)
	$(Q)cp edk-static/hdl/system.vhd edk-static/hdl/system.edk.vhd
	$(Q)cd edk-static/hdl && $($(QQ)MAKETOP) -l ../data/$(LAYOUT) system.vhd >> $(MAKE_LOG)
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
	#     - implement the toplevel design (does not contain any modules)
	#
	$(Q)mkdir -p top
	$(Q)cd top && cp ../edk-static/implementation/system.ngc top.ngc
	$(Q)cd top && cp ../edk-static/data/pr.ucf top.ucf
	$(Q)cd top && $($(QQ)NGDBUILD) -uc top.ucf -modular initial top.ngc >> $(MAKE_LOG)
	
base: top
	#
	####################################################################
	#
	# Step 5:
	#     - create the base directory
	#     - copy netlists (see Step 2) and busmacros to the base 
	#       directory
	#     - remove dummy hw thread netlists
	#     - replace system netlist with the one from step 4 (maybe not 
	#       necessary-needs investigation)
	#     - implement the base design (the part that does not change 
	#       during reconfiguration)
	#
	$(Q)mkdir base
	$(Q)find edk-static/implementation/ -iname "*.ngc" -exec cp {} base/. \;
	$(Q)find edk-static/implementation/ -iname "*.edf" -exec cp {} base/. \;
	$(Q)find edk-static/implementation/ -iname "*.edn" -exec cp {} base/. \;
	$(Q)find edk-static/implementation/ -iname "*.ngo" -exec cp {} base/. \;
	$(Q)find edk-static/implementation/ -iname "*.nmc" -exec cp {} base/. \;
	$(Q)rm -f base/system.ngc base/hw_task*.ngc
	$(Q)cp top/top.ucf base/.
	$(Q)cd base && $($(QQ)NGDBUILD) -uc top.ucf -modular initial ../top/top.ngc >> $(MAKE_LOG)
	$(Q)cd base && $($(QQ)MAP) top.ngd >> $(MAKE_LOG)
	$(Q)cd base && $($(QQ)PAR) $(PAROPTS) top.ncd base_routed.ncd >> $(MAKE_LOG)
	
eapr-modules: base
	#
	####################################################################
	#
	# Step 6:
	#     - enter $(HW_THREAD_DIR) and run make in order to build the hw
	#       thread netlists
	#     - for each OSIF N, and each thread M implement the module and
	#       move it to prms/prmN_M/prmN_M_routed.ncd
	#
	$(Q)test -f $(LAYOUT)
	$(Q)make -C $(HW_THREAD_DIR) all
	$(Q)[ -d prms ] || mkdir prms
	$(Q)cd $(HW_THREAD_DIR)/netlists && for s in $$(seq 0 $$(($(NUM_OSIFS)-1))); do\
		for t in *; do\
			( [ -d ../../prms/prm$${s}_$$t ] || mkdir ../../prms/prm$${s}_$$t ) &&\
			cp $$t/hw_task_$${s}_wrapper.ngc ../../prms/prm$${s}_$$t &&\
			cp $(BUSMACROS)/*.nmc ../../prms/prm$${s}_$$t &&\
			cp ../../base/static.used ../../prms/prm$${s}_$$t/arcs.exclude &&\
			cp ../../top/top.ucf ../../prms/prm$${s}_$$t &&\
			cd ../../prms/prm$${s}_$$t &&\
			$($(QQ)NGDBUILD) -uc top.ucf -modular module -active hw_task_$${s}_wrapper ../../top/top.ngc >> $(MAKE_LOG) &&\
			$($(QQ)MAP) top.ngd >> $(MAKE_LOG) &&\
			$($(QQ)PAR) $(PAROPTS) top.ncd prm$${s}_$${t}_routed.ncd >> $(MAKE_LOG) &&\
			cd ../../$(HW_THREAD_DIR)/netlists;\
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
		
	
bits-static: edk-static
	$(Q)cp -f $(MAKE_BITS) edk-static
	$(Q)cd edk-static && $($(QQ)XPS) -nw -scr $(MAKE_BITS) | tee -a $(MAKE_LOG) | grep -s ERROR; [ $$? -ne 0 ]


.PHONY:	clean hwclean 

clean: hwclean

eapr-clean:
	

hwclean:
	rm -f  edk-base eapr-modules eapr-setup netlist-static
	rm -rf edk-static
	rm -rf base
	rm -rf top
	rm -rf prms
	rm -rf merges
	rm -f $(MAKE_LOG)
	cd $(HW_THREAD_DIR) && make clean

