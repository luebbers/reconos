##-----------------------------------------------------------------------------
##
##    File Name:  readme.txt
##      Project:  Parameterizable LocalLink FIFO
##      Version:  1.2
##         Date:  2005-06-29
##
##      Company:  Xilinx, Inc.
##  Contributor:  Wen Ying Wei, Davy Huang
##
##   Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
##                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
##                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
##                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
##                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
##                APPLICATION OR STANDARD, XILINX IS MAKING NO
##                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
##                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
##                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
##                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
##                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
##                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
##                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
##                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
##                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
##                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
##                PURPOSE.
##                
##                (c) Copyright 2005 Xilinx, Inc.
##                All rights reserved.
##
##-----------------------------------------------------------------------------
## README for LocalLink FIFO
## Author: Wen Ying Wei, Davy Huang, Systems Engineering Group, Xilinx, Inc.
##-----------------------------------------------------------------------------

================
Table of Content
================
 1. Introduction
 2. Tool Summary
 3. Installation of the Design and Tools
 4. File List and Hierarchy
 5. Simulation Instruction
 6. Netlist Generation
 7. Revision History

==========================
1. Introduction
==========================
This package contains the source codes of the Parameterizable LocalLink
FIFO Reference Design. This reference design is provided for XAPP691 
Application notes. This application note describes the implementation
of a parameterizable LocalLink FIFO, which is a First-In-First-Out
memory queue with LocalLink interfaces on both sides. The LocalLink
interface defines a set of protocol-agnostic signals that allows
transmission of packet-oriented data, and enables a set of features
such as flow control and transfer data of arbitrary length. The
LocalLink FIFO consists of two LocalLink interfaces, one on the write
port to interface with an upstream user application, the other on
the read port to interface with a downstream user application. Its control
logic interprets and generates LocalLink signaling, performs all read and
write pointer management, and generates FIFO status signals for flow
control purposes. The LocalLink FIFO uses fully synchronous and independent
clock domains for the read and write ports. The LocalLink FIFO handles data
width conversion between read and write ports. Its memory can be constructed
in block SelectRAM or distributed RAM with parameterizable depth. The
optional outputs of frame length and length ready provide visibility into
byte numbers of each received frames, which allows downstream user
application to acquire the length of a frame prior to reading the data.
For further information please refer to XAPP691 at 
http://www.xilinx.com/bvdocs/appnotes/xapp691.pdf

This README describes the necessary steps for running simulation and synthesis 
on the LocalLink FIFO reference design. 

===================
2. Tool Summary
===================
o Xilinx ISE 6.1.03i (G.26)
o Model Technology's ModelSim SE 5.6e
  - Require ModelSim to support mixed language simulation

=======================================
3. Installation of the Design and Tools
=======================================
1. Install Xilinx ISE 6.1.03i (G.26)

2. Install ModelSim SE 5.6e.
   
3. Extract this zip file into a directory <LL_FIFO_ROOT>.   

4. Modify config.csh (On Unix) file under <LL_FIFO_ROOT> to update all paths
   of the tools and libraries.
   
5. Source config.csh to setup the environment on Unix:
   
   On Unix: enter directory <LL_FIFO_ROOT>, then run the following command
   
   % source config.csh
   
6. After user completes these steps, you only need to run step 5 again
   next time after you restart the system.
   
   
==========================
4. File List and Hierarchy
==========================

Note: Only Verilog source is available in this release.

<LL_FIFO_ROOT>
        |       
        |----> src
        |       |----> vhdl
        |               |----> BRAM
        |               |       |----> BRAM_S144_S144.vhd
        |               |       |----> BRAM_S16_S144.vhd
        |               |       |----> BRAM_S18_S72.vhd
        |               |       |----> BRAM_S36_S144.vhd
        |               |       |----> BRAM_S36_S72.vhd
        |               |       |----> BRAM_S72_S144.vhd
        |               |       |----> BRAM_S72_S72.vhd
        |               |       |----> BRAM_S8_S144.vhd
        |               |       |----> BRAM_S8_S72.vhd
        |               |       |----> BRAM_macro.vhd   
        |               |       |----> BRAM_fifo.vhd
        |               |       |----> BRAM_fifo_pkg.vhd
        |               |----> DRAM
        |               |       |----> DRAM_fifo_pkg.vhd
        |               |       |----> RAM_64nX1.vhd
        |               |       |----> DRAM_macro.vhd
        |               |       |----> DRAM_fifo.vhd
        |               | 
        |               |----> fifo_utils.vhd
        |               |----> virtex2p.vhd
        |               |----> ll_fifo_BRAM.vhd
        |               |----> ll_fifo_DRAM.vhd
        |               |----> ll_fifo.vhd      
        |----> test
        |       |----> func_sim
        |       |       |----> vhdl
        |       |       |       |----> ll_fifo.pl
        |       |       |       |----> ll_fifo_tb_wave.do
        |       |       |----> modelsim_unix.ini
        |       |
        |       |----> testbench
        |               |----> vhdl
        |               |       |----> ll_fifo_tb.vhd
        |               |
        |               |----> Tester
        |                       |----> src
        |                       |       |----> verilog
        |                       |       |       |----> FILEREAD_TESTER.v
        |                       |       |       |----> OUTPUT_TESTER.v
        |                       |       |       |----> OUTPUT_TESTER_8_BIT.v
        |                       |       |       |----> UFC_CONVERTER.v
        |                       |       |       |----> UFC_CONVERTER_8_BIT.v
        |                       |       |       |----> TESTER_pkg.vhd   
        |                       |----> test
        |                               |----> test_vec
        |                                       |----> user_data_packets128.vec
        |                                       |----> user_data_packets16.vec
        |                                       |----> user_data_packets32.vec
        |                                       |----> user_data_packets64.vec
        |                                       |----> user_data_packets8.vec
        |         
        |----> build
        |       |----> vhdl 
        |               |----> syn
        |                       |----> ll_fifo.xst
        |                       |----> ll_fifo_run.pl
        |                       |----> ll_fifo.prj
        |                       
        |
        |----> config.csh
        |----> readme.txt


==========================
5. Simulation instruction
==========================

Below is a block diagram of the LocalLink FIFO testbench.
There are two LocalLink FIFO instantiated in the testbench: Egress FIFO
and Ingress FIFO.  The Tester module is connected to both FIFOs on
the tester interface. On the other side, two FIFOs are connected together
through a pipleline/throttle module so that the data can be looped back.


      +---------+        +---------+
      |         |        |         |
      |  Tester |  ==>   | Egress  | ====+
      |   (TX)  |        | LL_FIFO |     | 
      |         |        |         |  +----------+
      +---------+        +---------+  |Pipeline/ |
      +---------+        +---------+  |Throttle  |
      |         |        |         |  +----------+
      |  Tester |  <==   | Ingress |     |
      |   (RX)  |        | LL_FIFO |<====+
      |         |        |         |
      +---------+        +---------+
                    ^                  ^  
                    |                  |
               TESTER I/F        LOOPBACK I/F

Follow these steps to simulate the design on UNIX platform:

(1) Modify and run config.csh to setup the environment on Unix.

(2) Use compxlib tool (supplied in Xilinx ISE software) to compile
    both VHDL and Verilog unisim simulation library into $MTI_LIBS/unisim
    and $MTI_LIBS/unisim_ver directories. Below is an example of
    using the compxlib command to compile all simulation libraries.

    % compxlib -s mti_se -f virtex2p -l all -o $MTI_LIBS

(3) Change directory to <LL_FIFO_ROOT>/test/func_sim/vhdl 

(4) Run the following perl script to invoke simulation.
    
    % perl ll_fifo_tb.pl  

    This script will first ask user to input some FIFO parameters, 
    then automatically modify the top level testbench 
    (<LL_FIFO_ROOT>/test/testbench/vhdl/ll_fifo_tb.vhd) to apply
    these parameters on the FIFO, such as MEMORY_TYPE, DRAM_DEPTH, etc. 
    You can find the description for each parameter in XAPP691.
        
    This script will invoke ModelSim GUI and execute the script
    test.do to compile all the source codes into simulation library.  
    
    Once ModelSim GUI pops up, user should see the waveform window
    also pops up with pre-loaded signals.
    
    If there is any error occurred when compiling the source codes,
    please check the specified parameters on the LocalLink FIFO 
    test bench for any unacceptable values. 

(5) Run the simulation in ModelSim.  
    
    > run 100 us  
    
    User can specify a longer simulation duration (e.g. 50 us). Note
    that the length of the test pattern is limited and simulation
    may run out of test pattern if it runs too long. If this happens,
    user can manually add more test patterns into the test vector
    file. See step (6)
    
    If simulation passes, you should see RESULT_GOOD signal on the
    waveform stays high after the reset.
    
    If there is an error in simulation, probably a data mismatch
    between transmitted data to the Egress FIFO and received data
    from the Ingress FIFO, you should see RESULT_GOOD signal 
    is deasserted at certain time spots when the error is detected.
    
(6) The testvectors under <LL_FIFO_ROOT>/test/testbench/Tester/test/test_vec
    can be modified for loading different test patterns.  
    The user would need to read the description at the
    beginning of each vector file in order to modify them properly.  
    
    
(7) Re-compilation is needed after user changes any source code. If user
    wants to test the design with the same paramters, there is no need to
    exit ModelSim.  Use the following command to recompile the source files
    and run the simulation again.
    
    > do test.do
    > run 100 us
    
    
==========================
6. Netlist generation
==========================
Follow these steps to generate a netlist using XST synthesis on Unix
platform: 
    
(1) Before generating a netlist, the user should set the desired parameters  
    on the top level file (<LL_FIFO_ROOT>/src/vhdl/ll_fifo.vhd).  
    The top level file has the following parameters. Refer to XAPP691 for
    acceptable values of these parameters.

                MEM_TYPE (integer)     
                BRAM_MACRO_NUM (integer)                
                DRAM_DEPTH (integer)            
                WR_DWIDTH (integer)                                                                     
                RD_DWIDTH (integer)                                                             
                RD_REM_WIDTH (integer)  
                WR_REM_WIDTH (integer)  
                USE_LENGTH (boolean)            
                glbtm (don't care in netlist generation)
        
    These parameters must be assigned to a proper value otherwise the generated
    netlist can not function properly. 
    
(2) Change directory to <LL_FIFO_ROOT>/build/vhdl, run the perl script ll_fifo_run.pl
    to generate the netlist for the desired configuration:
    
    % perl ll_fifo_run.pl
    
    The generated netlist will be stored in the same directory, named as ll_fifo.ngc  

=====================
7. Design Notes
=====================
(1) Memory collision error:

    When simulating the XAPP691 with Length FIFO option turned on, user may see the
    following warning message in ModelSim:
    
    ** Warning:  Memory Collision Error on RAMB16_S*_S*: :ll_fifo_tb:*: 
       at simulation time *** ns.
    #  A read was performed on address *** (hex) of port A while a write was
    #  requested to the same address on Port B  The write will be successful
    #  however the read value is unknown until the next CLKA cycle  

    This message occurs due to an event of read and write on the length FIFO
    at the same     address. When this happens, it creates metastability on the read
    port for reading the frame length. However, this is safe because: 
    The write address on the length FIFO automatically advances immediately after
    a write finishes. This means that the metastability lasts at most one read clock
    cycle. As long as the read on the length FIFO is delayed least one read clock cycle,
    it is safe to read the data on the same address. In XAPP691, the read on the
    length FIFO is always delayed for two read clock cycles. 


=====================
8. Revision History
=====================

1.0  02/03/03  Initial release

1.1  12/27/04  Bugs/Issues Fixed:
               (1) Fixed a bug on dst_rdy_in_n/src_rdy_out_n handshaking
                   in the case when WR_DWIDTH > RD_DWIDTH.
                   When the downstream application halts the
                   dst_rdy_in_n input, the LL_FIFO should latch
                   the src_rdy_out_n until the dst_rdy_in_n is reassert again.
		   Otherwise, a data beat gets lost.  This bug shows up only
		   in the case when WR_DWIDTH > RD_DWIDTH, and appears only
		   on the downstream interface.
               (2) Fixed a bug on generating the minor address on the write
                   port in the case when RD_DWIDTH > WR_DWIDTH.
                   When the data beat happens to be the EOF, and data write
                   is paused, this bug makes the write minor address continue
                   to advance for one more cycle so that a previous data is
                   overwritten by an invalid value.
               (3) Fixed a bug on generating SOF/EOF/REM when
                   BRAM_MACRO_NUM = 16. Such bug makes these control data not
                   being latched properly when user halts the read on the FIFO.
               (4) Fixed a bug regarding generating the Length FIFO error
                   output (len_err_out).
               (5) Updated the testbench to increase test coverage.
1.2  06/16/05  Bugs Fixed:
               (1) Fixed a bug that will concatenates two frames together when
                   FIFO oscillates between empty and non-empty and an EOF is
                   read out from the FIFO. 
               (2) Fixed a bug regarding passing the REM value through the FIFO
                   when BRAM depth is equal to or greater than 16. This bug occurs
                   when the FIFO switches between two BRAMs for the REM values 
                   crossing the address boundary.
