#
# \file Makefile
#
# Build simulation libraries for ModelSim
#
# Used to build the modelsim libraries for ReconOS pcores. To have the modelsim
# tools find these libraries, add them to the libraries section in your
# modelsim.ini, or set
# 
#     MODELSIM=$RECONOS/modelsim.ini
# 
# prior to modelsim invocation.
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

export MODELSIM=${RECONOS}/support/modelsim.ini
PCORES=reconos_v2_01_a \
       plb_osif_v2_01_a osif_core_v2_01_a\
       xps_osif_v2_01_a burst_ram_v2_01_a

all: ${PCORES}

.PHONY: clean

clean:
	rm -rf ${PCORES}

reconos_v2_01_a:
	echo ${MODELSIM}
	vlib $@
	vcom -work $@ ../pcores/$@/hdl/vhdl/reconos_pkg.vhd

osif_core_v2_01_a: reconos_v2_01_a
	vlib $@
	vcom -work $@ ../pcores/$@/hdl/vhdl/dcr_slave_regs.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/command_decoder.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/osif_core.vhd

xps_osif_v2_01_a: reconos_v2_01_a
	vlib $@
#	vcom -work $@ ../pcores/$@/hdl/vhdl/bus_slave_regs.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/fifo_mgr.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/mem_plb46.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/xps_osif.vhd

plb_osif_v2_01_a: osif_core_v2_01_a
	vlib $@
	vcom -work $@ ../pcores/$@/hdl/vhdl/bus_slave_regs.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/fifo_mgr.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/bus_master.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/mem_plb34.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/plb_osif.vhd

burst_ram_v2_01_a:
	vlib $@
	vcom -work $@ ../pcores/$@/hdl/vhdl/ram_single.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/bram_wrapper.vhd
	vcom -work $@ ../pcores/$@/hdl/vhdl/burst_ram.vhd

