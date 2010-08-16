Files:

ac97_timing.vhd		 Generates timing signals for AC97 core
ac97_core.vhd		 Core AC97 controller interface (no buffering)
srl_fifo.vhd             Parameterizable FIFO module
ac97_fifo.vhd            AC97 interface with a data fifo
opb_ac97.vhd		 OPB interface to core
ac97_model.vhd		 Simplistic behavioral model of AC97 protocol

TESTBENCH_ac97_package.vhd  Common simulation procedures
TESTBENCH_ac97_core.vhd	 Testbench for ac97_core
TESTBENCH_ac97_fifo.vhd	 Testbench for ac97_fifo


