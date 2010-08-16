TODOs:
------
- Create following directory structure somewhere:  Repository/MyProcessorIPLib/
- In "MyProcessorIPLib" create the directories "drivers" and "pcores", where "pcores" is a link to the reconos pcores directory
- Add the following to your Makefile at $RECONOS/support/simlibs:
    osif_new_v1_00_a: 
	   vlib $@
	   vcom -work $@ ../pcores/$@/hdl/vhdl/mem_plb46.vhd
	   vcom -work $@ ../pcores/$@/hdl/vhdl/osif_new.vhd
    
- run make to compile the simlib for osif_new
- Because of problems with the simulation, some bfm-pcores have to be changed, therefore the following changes have to be made:
  CHANGE 1: -Goto $EDK_DIR/hw/XilinxBFMinterface/pcores/plbv46_bfm/hdl/vhdl
            - At line 35 of the "plb_dcl" change the value of "PLB_DATA_BUS_WIDTH" to 64
  CHANGE 2: -Goto $EDK_DIR/hw/XilinxBFMinterface/pcores/plbv46_slave_bfm_v1_00_a/hdl/vhdl
            - comment the lines 211 and 212
            should be this lines:  sig_PLB_BE(8 to 11)  <= PLB_BE(8 to 11);
                                   sig_PLB_BE(12 to 15) <= "0000";
  CHANGE 3: -Goto $EDK_DIR/hw/XilinxBFMinterface/pcoresplbv46_master_bfm_v1_00_a/data
            - add "PARAMETER PLB_DATA_BUS_WIDTH = 64, DT = integer, BUS = MPLB, RANGE = (32,64,128)" to the mpd file
  Now the simlibs of these cores have to be recompiled, therefore do the following commands at commandline
      -vcom -93 -novopt -quiet -work plbv46_bfm -f $PATH_TO_EDK_SIMLib/CompileListFiles/plbv46_bfm_compile_order
      -vcom -93 -novopt -quiet -work plbv46_slave_bfm_v1_00_a -f $PATH_TO_EDK_SIMLib/CompileListFiles/plbv46_slave_bfm_v1_00_a_compile_order
      -vcom -93 -novopt -quiet -work plbv46_master_bfm_v1_00_a -f $PATH_TO_EDK_SIMLib/CompileListFiles/plbv46_master_bfm_v1_00_a_compile_order
  
- Now start EDK with the bfm_system.xmp and go to the menu Project->Project Options
- Set the "Project Peripheral Repository"(the first tab) to "Repository" created at step 1
- Generate the simulation hdl files (Simulation->generate....)
- Goto the simulation/behavioral directory and change the bfm_system.do (in the simulation directory is a bfm_system.do. Your bfm_system.do at the behavioral directory should be the same, apart from the Paths.
- The test_mutex.vhd file in the simulation directory is the pcore which is connected to the OSIF.
- Now the simulation can be started: in simulation/behavioral run "vsim -do ../../scripts/run.do"

                                                        
