# Set the following values as appropriate for your hardware thread

# VHDL source files ( in the correct evaluation order! )
VHDL_FILES= 	physical/v6_gtxwizard.vhd \
		physical/v6_gtxwizard_gtx.vhd \
		physical/rx_elastic_buffer.vhd \
		physical/v6_gtxwizard_top.vhd \
		client/fifo/tx_client_fifo_8.vhd \
		client/fifo/rx_client_fifo_8.vhd \
		client/fifo/eth_fifo_8.vhd \
		client/address_swap_module_8.vhd \
		v6_emac_v1_4.vhd \
		v6_emac_v1_4_block.vhd \
		v6_emac_v1_4_locallink.vhd \
		fifo/src/vhdl/BRAM/BRAM_fifo_pkg.vhd \
		fifo/src/vhdl/BRAM/BRAM_S72_S72.vhd \
		fifo/src/vhdl/BRAM/BRAM_S144_S144.vhd \
		fifo/src/vhdl/BRAM/BRAM_S8_S72.vhd \
		fifo/src/vhdl/BRAM/BRAM_S18_S72.vhd \
		fifo/src/vhdl/BRAM/BRAM_S36_S72.vhd \
		fifo/src/vhdl/BRAM/BRAM_S8_S144.vhd \
		fifo/src/vhdl/BRAM/BRAM_S16_S144.vhd \
		fifo/src/vhdl/BRAM/BRAM_S36_S144.vhd \
		fifo/src/vhdl/BRAM/BRAM_S72_S144.vhd \
		fifo/src/vhdl/BRAM/BRAM_macro.vhd \
		fifo/src/vhdl/BRAM/BRAM_fifo.vhd \
		fifo/src/vhdl/DRAM/DRAM_fifo_pkg.vhd \
		fifo/src/vhdl/DRAM/RAM_64nX1.vhd \
		fifo/src/vhdl/DRAM/DRAM_macro.vhd \
		fifo/src/vhdl/DRAM/DRAM_fifo.vhd \
		fifo/src/vhdl/ll_fifo_pkg.vhd \
		fifo/src/vhdl/fifo_utils.vhd \
		fifo/src/vhdl/ll_fifo_BRAM.vhd \
		fifo/src/vhdl/ll_fifo_DRAM.vhd \
		fifo/src/vhdl/ll_fifo.vhd \
		third.vhd

# netlist files needed by your thread (.edn or .ngc)
NETLIST_FILES=
USER_PORT_DECL_FILE=user_port_decl.txt
# Name of the thread's top entity
USER_LOGIC_ENTITY=third
# Target architecture
ARCHITECTURE=virtex2p


######### NO CHANGES NECESSARY BEYOND THIS LINE ###########

MKHWTHREAD=$(RECONOS)/tools/python/mkhwthread_user_ports.py
MKPRMHS=$(RECONOS)/tools/python/mkprmhs.py
PLATGEN=platgen
THREAD_PCORE_PREFIX=hw_task_v1_0
THREAD_PCORE_SUFFIX=_b
THREAD_PCORE=$(THREAD_PCORE_PREFIX)1$(THREAD_PCORE_SUFFIX)
CORE_PCORES=reconos_$(RECONOS_VER) burst_ram_$(RECONOS_VER)

QUIET_MKHWTHREAD=  echo "    MKHWTHREAD  $@"; $(MKHWTHREAD)
QUIET_MKPRMHS=     echo "    MKPRMHS     $@"; $(MKPRMHS)
QUIET_PLATGEN=     echo "    PLATGEN     $@"; $(PLATGEN)

ifeq ($(NUM_DYNAMIC_OSIFS),)
    $(error Number of dynamic OSIFs unknown. Specify NUM_DYNAMIC_OSIFS)
endif

all: hwthread

clean:
	$(Q)rm -f platgen.log platgen.opt system.mhs
	$(Q)rm -rf hdl implementation synthesis pcores
	$(Q)rm -rf hw_task_v1_*_b
	$(Q)rm -f hw_task_*.ngc

$(THREAD_PCORE_PREFIX)%$(THREAD_PCORE_SUFFIX): 
	$(Q)$($(QQ)MKHWTHREAD) $(USER_LOGIC_ENTITY) $(subst $(THREAD_PCORE_SUFFIX),,$(subst $(THREAD_PCORE_PREFIX),,$@)) $(USER_PORT_DECL_FILE) $(VHDL_FILES) $(NETLIST_FILES) >> make.log

hwthread: clean $(THREAD_PCORE)
	$(Q)mkdir pcores
	$(Q)cd pcores && ln -s ../$(THREAD_PCORE) .
	$(Q)cd pcores && for z in $(CORE_PCORES); do \
	    ln -s $(RECONOS)/core/pcores/$$z . ;\
	done
	$(Q)$($(QQ)MKPRMHS) 1 $(NUM_DYNAMIC_OSIFS) > system.mhs
	$(Q)$($(QQ)PLATGEN) -lp $$(pwd) -p $(ARCHITECTURE) system.mhs >> make.log
	
