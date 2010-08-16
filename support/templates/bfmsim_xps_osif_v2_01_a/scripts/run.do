##############################################################################
## Filename:          /home/luebbers/work/plb46/bfmsim_9.2/pcores/xps_osif_v2_01_a/devl/bfmsim/scripts/run.do
## Description:       ModelSim Run Script - modify with your discretion
## Date:              Thu Jul 23 14:47:35 2009 (by Create and Import Peripheral Wizard)
##############################################################################


# Compile BFM test modules
do bfm_system.do

# Load BFM test platform
vsim bfm_system

# Load Wave window
do ../../scripts/wave.do

# Load BFL
do ../../scripts/sample.do

# Start system clock and reset system
force -freeze sim:/bfm_system/sys_clk 1 0, 0 {10 ns} -r 20 ns
force -freeze sim:/bfm_system/sys_reset 1
force -freeze sim:/bfm_system/sys_reset 0 100 ns, 1 {200 ns}

# Run test time
run 100 us

# Release ModelSim simulation license
quit -sim

# Close previous dataset if it exists
if {[dataset info exists bfm_test]} {dataset close bfm_test}

# Open and view waveform
dataset open vsim.wlf bfm_test
do ../../scripts/wave.do
