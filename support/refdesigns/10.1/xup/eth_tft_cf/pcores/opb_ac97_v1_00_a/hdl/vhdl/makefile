XILINX_PRIM_DIR = C:/Xilinx/ise6_2/mti_se
XILINX_EDK_LIBS_DIR = C:/usr/local/packages/xilinx/EDK_Lib
DESIGN_LIB = opb_ac97_v2_00_a
COMPILE = vcom -93

compile: modelsim.ini
	${COMPILE} ac97_timing.vhd
	${COMPILE} ac97_core.vhd
	${COMPILE} srl_fifo.vhd
	${COMPILE} bram_fifo.vhd
	${COMPILE} ac97_fifo.vhd
	${COMPILE} opb_ac97.vhd

testbench: compile
	${COMPILE} TESTBENCH_ac97_package.vhd
	${COMPILE} ac97_model.vhd
	${COMPILE} TESTBENCH_ac97_core.vhd
	${COMPILE} TESTBENCH_ac97_fifo.vhd
	${COMPILE} testbench_opb_ac97.vhd

standalone: compile testbench
	${COMPILE} command_fifo.vhd
	${COMPILE} ac97_if.vhd
	${COMPILE} standalone.vhd
	${COMPILE} TESTBENCH_ac97_if.vhd
# ac97_command_rom.vhd


modelsim.ini:
#	vmap XilinxCoreLib ${XILINX_PRIM_DIR}/XilinxCoreLib/
#	vmap simprim ${XILINX_PRIM_DIR}/simprim/
#	vmap unisim ${XILINX_PRIM_DIR}/unisim/
	vmap common_v1_00_a ${XILINX_EDK_LIBS_DIR}/common_v1_00_a/
	vlib ${DESIGN_LIB}
	vmap work ${DESIGN_LIB}

clean:
	rm -rf work ${DESIGN_LIB}
	rm -f modelsim.ini transcript *.mti vsim.wlf *.log

