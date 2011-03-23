#!/build/sjxfndry/G.24/rtf/bin/sol/xilperl


##-----------------------------------------------------------------------------
##
##      File Name: LL_FIFO_run.pl
##        Version: 
##           Date: 
##
##        Company: Xilinx, Inc.
##    Contributor: Wen Ying Wei, Davy Huang
##
##-----------------------------------------------------------------------------

##-----------------------------------------------------------------------------
## Note:
## This script is used to automatically run XST Synthesis tools on LL_FIFO.vhd 
## and generate a netlist in a configuration according to the parameters,  
## Before running the script, the the desire parameters have to be set in the 
## top level design, e.g. LL_FIFO.vhd. 
## 
## The LL FIFO has the following parameters:
## (1) MEM_TYPE (integer)
## (2) WR_DWIDTH (integer) 
## (3) RD_DWIDTH (integer)
## (4) WR_REM_WIDTH (integer)   
## (5) RD_REM_WIDTH (integer)   
## (6) DRAM_DEPTH (integer, for DRAM only)                              
## (7) BRAM_MACRO_NUM (integer, for BRAM only)
## (8) USE_LENGTH (boolean)                 
##
## The ll_fifo.xst has been provided.  There is no need to regenerate this
## file.
##-----------------------------------------------------------------------------

 
 system ("echo Synthesise LocalLink FIFO Reference design using XST ...");
 system ("xst -ifn ./ll_fifo.xst -ofn xst.log"); 
 system ("XST synthesis complete!");
 

