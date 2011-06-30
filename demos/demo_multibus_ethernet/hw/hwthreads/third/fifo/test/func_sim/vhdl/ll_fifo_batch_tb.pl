#!xilperl

##-----------------------------------------------------------------------------
##
##    File Name:  ll_fifo_batch_tb.pl
##
##      Version:  1.2
##         Date:  2005-06-29
##      Project:  Parameterizable LocalLink FIFO
##        Model:  Perl script to run automated exhaustive tests on the LocalLink
##                FIFO using all possible configuration combinations.
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


##-----------------------------------------------------------------------------
## Note:
## (1) A Perl program comes with Xilinx tools, named as xilperl.
## (2) Call the following script to setup the environment first
##      source ../../../config.csh
## (3) DUT_PATH points to the design under test, e.g. ll_fifo_v_1_1
## (4) MTI_LIBS points to pre-compiled MTI libraries, e.g. unisim
## (5) MODEL_TECH  points to the installation of ModelSim
##-----------------------------------------------------------------------------

## Check Environment and MTI unisim libraries...
if ($ENV{MTI_LIBS} eq "")
{ 
  print "\nYou have not set the environment variable: MTI_LIBS.\n";
  print "Please first run config.csh at the root directory of this project.\n";
  exit 1;
}

$mti_libs_unisim = $ENV{MTI_LIBS}."/unisim";
$mti_libs_unisim_ver = $ENV{MTI_LIBS}."/unisims_ver";

if (!(-e $mti_libs_unisim && -d $mti_libs_unisim))
{ 
  print "\nDirectory $mti_libs_unisim does not exist.\n";
  print "Please first use ModelSim to compile Unisim VHDL library into this directory.\n";
  exit 1;
}

if (!(-e $mti_libs_unisim_ver && -d $mti_libs_unisim_ver))
{ 
  print "\nDirectory $mti_libs_unisim_ver does not exist.\n";
  print "Please first use ModelSim to compile Unisim Verilog library into this directory.\n";
  exit 1;
}


@bramdepths = ("1","2","4", "8", "16");
$bramdepthnum = 5;

@dramdepths = ("16","32","64", "128", "256","512");
$dramdepthnum = 6;
@testerwidths = ("8","16","32", "64", "128");


$memorytype = 0;
$memorydepthnum = 0;
$memorydepth = 0;
$tester_freq = 0;
$loopback_freq = 0;
$testerwidth = 0;
$testvec = 0;
$loopbackwidth = 0;
$log = "";

if(!open (LOG_FILE, ">batch_test.log"))
           { print "Cannot open file batch_test.log: $!\n"; 
             close LOG_FILE;      
             exit 1;
           }

print LOG_FILE "Batch Test Results (", scalar localtime, ")\n";
close LOG_FILE;

for ($memorytype = 0; $memorytype <2; $memorytype = $memorytype +1)
{

  if ($memorytype == 0) { $memorydepthnum = $bramdepthnum;} else { $memorydepthnum = $dramdepthnum;}
  
  for ($memorydepthidx = 0; $memorydepthidx < $memorydepthnum; $memorydepthidx = $memorydepthidx + 1)
  {
   
     if ($memorytype == 0) { $memorydepth = $bramdepths[$memorydepthidx];} else { $memorydepth = $dramdepths[$memorydepthidx];}

   
    for ($tester_freq = 80; $tester_freq <=200; $tester_freq=$tester_freq+110)
    
    {
    
      for ($loopback_freq = 80; $loopback_freq <=200; $loopback_freq=$loopback_freq+110)
    
      {


        foreach $testerwidth (@testerwidths)
         {
             
             
             $testvec = "user_data_packets".$testerwidth.".vec";
             
             foreach $loopbackwidth (@testerwidths)
              { 

                $log = "mtype_".$memorytype."_mdep_".$memorydepth."_tfrq_".$tester_freq."_lfrq_".$loopback_freq."_tw_".$testerwidth."_lw_".$loopbackwidth;
                

                ## modify the parameters in the test bench source
                modify_tb_source();


                system ("cp $ENV{TESTER}/test/test_vec/$testvec user_data_packets.vec");        
                system ("rm -r -f work");

                open DO_FILE, ">test.do";
                print DO_FILE "vlib work\n";
                print DO_FILE "vmap work work\n";
                print DO_FILE "vlib unisim\n";
                print DO_FILE "vmap unisim ", $mti_libs_unisim,"\n";
                print DO_FILE "vlib unisim_ver\n";
                print DO_FILE "vmap unisim_ver ", $mti_libs_unisim_ver,"\n";

                print DO_FILE "vlib fifo_utils\n";
                print DO_FILE "vmap fifo_utils fifo_utils\n";
                print DO_FILE "vlib TESTER_pkg\n";
                print DO_FILE "vmap TESTER_pkg\n";

                print DO_FILE "vlog -work work +libext+.v -L unisim_ver $ENV{TESTER}/src/verilog/FILEREAD_TESTER.v\n";
                print DO_FILE "vlog -work work +libext+.v -L unisim_ver $ENV{TESTER}/src/verilog/OUTPUT_TESTER.v\n";
                print DO_FILE "vlog -work work +libext+.v -L unisim_ver $ENV{TESTER}/src/verilog/OUTPUT_TESTER_8_BIT.v\n";

                my $DUT_FILES="$ENV{DUT_PATH}/src/vhdl/fifo_utils.vhd ".
                "$ENV{TESTER}/src/verilog/TESTER_pkg.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_fifo_pkg.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S8_S72.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S18_S72.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S36_S72.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S72_S72.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S8_S144.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S16_S144.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S36_S144.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S72_S144.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_S144_S144.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_macro.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/BRAM/BRAM_fifo.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/DRAM/DRAM_fifo_pkg.vhd ".
                "$ENV{DUT_PATH}/src/vhdl/DRAM/RAM_64nX1.vhd ".
                "$ENV{DUT_PATH}/src/vhdl/DRAM/DRAM_macro.vhd ".
                "$ENV{DUT_PATH}/src/vhdl/DRAM/DRAM_fifo.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/ll_fifo_pkg.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/ll_fifo_BRAM.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/ll_fifo_DRAM.vhd ". 
                "$ENV{DUT_PATH}/src/vhdl/ll_fifo.vhd ". 
                "$ENV{DUT_PATH}/test/testbench/vhdl/ll_fifo_tb.vhd";

                print DO_FILE "vcom -93 -work work ", $DUT_FILES, "\n";
                print DO_FILE "vsim -lic_noqueue -L unisim work.ll_fifo_tb\n";

                print DO_FILE "run 500 us\n";
                
                print DO_FILE "quit -f\n";

                close DO_FILE;
 
                print "==================================================================\n";
                print "Simulating $log ...\n";
                print "==================================================================\n";
                
                system ("vsim -t ps -c -do test.do -wlf ".$log.".wlf -l ".$log.".log");  ## run in command line mode

                if(!open (LOG_FILE, ">>batch_test.log"))
                   { print "Cannot open file batch_test.log: $!\n"; 
                     close LOG_FILE;      
                     exit 1;
                   }

                if (chk_log () == 0)
                 {
                   print LOG_FILE "pass: $log\n";
                 }
                else
                 {
                   print LOG_FILE "FAIL: $log\n";
                 }
                 
                 close LOG_FILE;

                }
                
              }
              
          }
          
       }
       
    }
    
    
 }


if(!open (LOG_FILE, ">>batch_test.log"))
    { print "Cannot open file batch_test.log: $!\n"; 
      close LOG_FILE;      
      exit 1;
    }

print LOG_FILE "=======DONE\n";
                
close LOG_FILE;

sub modify_tb_source {

  $filename = "$ENV{DUT_PATH}/test/testbench/vhdl/ll_fifo_tb.vhd";

          if(!open (FILEHANDLE_IN, "$filename"))
           { print "Cannot open file $filename: $!\n"; 
             close FILEHANDLE_IN;      
             exit 1;
           }

          if(!open (FILEHANDLE_OUT, ">$filename".".tmp"))
           { print "Cannot open file $filename.tmp: $!\n"; 
             close FILEHANDLE_OUT;      
             exit 1;
           }


          while (my $line = <FILEHANDLE_IN>)
           {
               my $line1 = $line;
               $line1 =~ s/^\s+//;

              if ($line1 =~ /^\-\-/) 
               {
                #skip comment
                print FILEHANDLE_OUT $line;
               }
              elsif (not $line1 =~ /\:=/)
               {
                print FILEHANDLE_OUT $line;
               }
              elsif ($line1 =~ /MEM_TYPE/) 
               {
                 print FILEHANDLE_OUT "        MEM_TYPE                : integer   :=$memorytype;      -- Select memory type(0: BRAM, 1: Distributed RAM)\n";
               }
               elsif (($memorytype eq "0") and ($line1 =~ /BRAM_MACRO_NUM/) )
               {
                 print FILEHANDLE_OUT "        BRAM_MACRO_NUM          : integer   :=$memorydepth;      -- Set memory depth if use BRAM\n";
               }
               elsif (($memorytype eq "1") and ($line1 =~ /DRAM_DEPTH/) )
               {
                 print FILEHANDLE_OUT "        DRAM_DEPTH              : integer   :=$memorydepth;      -- Set memory depth if use Distributed RAM\n";
               }

              elsif ($line1 =~ /TESTER_CLK_HALF_PERIOD/) 
               {
                 print FILEHANDLE_OUT "        TESTER_CLK_HALF_PERIOD  : time      :=",sprintf("%.2f", 1000.0/$tester_freq)," ns; -- Set Tester clock speed\n";
               }
              elsif ($line1 =~ /LOOPBACK_CLK_HALF_PERIOD/) 
               {
                 print FILEHANDLE_OUT "        LOOPBACK_CLK_HALF_PERIOD: time      :=",sprintf("%.2f", 1000.0/$loopback_freq)," ns; -- Set Loopback clock speed\n";
               }
              elsif ($line1 =~ /TESTER_DWIDTH/) 
               {
                 print FILEHANDLE_OUT "        TESTER_DWIDTH           : integer   :=$testerwidth;     -- Set Tester data width:8, 16, 32, 64, 128\n";
               }
              elsif ($line1 =~ /TESTER_REM_WIDTH/) 
               {
                 print FILEHANDLE_OUT "        TESTER_REM_WIDTH        : integer   :=", calulate_rem($testerwidth),";      -- Set Tester remainder width:1, 1, 2, 3, 4\n";
               }
              elsif ($line1 =~ /TESTER_REM_VECTOR_WIDTH/) 
               {
                 print FILEHANDLE_OUT "        TESTER_REM_VECTOR_WIDTH : integer   :=", calulate_rem_vector($testerwidth),";      -- Set rem width in test vector file\n";
               }
              elsif ($line1 =~ /LOOPBACK_REM_WIDTH/) 
               {
                 print FILEHANDLE_OUT "        LOOPBACK_REM_WIDTH      : integer   :=", calulate_rem($loopbackwidth),";      -- Set Loopback remainder width:1, 1, 2, 3, 4\n";
               }
              elsif ($line1 =~ /LOOPBACK_DWIDTH/) 
               {
                 print FILEHANDLE_OUT "        LOOPBACK_DWIDTH         : integer   :=$loopbackwidth;     -- Set Tester data width:8, 16, 32, 64, 128\n";
               }
              else
               {
                  print FILEHANDLE_OUT $line;
               }
             }


          close FILEHANDLE_IN;   
          close FILEHANDLE_OUT;   

          
          system ("cp $filename.tmp $filename");


          print "\nGenerate VHDL parameters as follows:\n";
          print "MEM_TYPE                : integer   :=$memorytype\n";
          if ($memorytype eq "0")  
          {
          print "BRAM_MACRO_NUM          : integer   :=$memorydepth\n";
          }
          else
          {
          print "DRAM_DEPTH              : integer   :=$memorydepth\n";
          }
          
          print "TESTER_CLK_HALF_PERIOD  : time      :=",sprintf("%.2f", 1000.0/$tester_freq)," ns\n";
          print "TESTER_DWIDTH           : integer   :=$testerwidth\n";
          print "TESTER_REM_WIDTH        : integer   :=", calulate_rem($testerwidth),"\n";
          print "TESTER_REM_VECTOR_WIDTH : integer   :=", calulate_rem_vector($testerwidth),"\n";
          print "LOOPBACK_CLK_HALF_PERIOD: time      :=",sprintf("%.2f", 1000.0/$loopback_freq)," ns\n";
          print "LOOPBACK_DWIDTH         : integer   :=$loopbackwidth\n";
          print "LOOPBACK_REM_WIDTH      : integer   :=", calulate_rem($loopbackwidth),"\n\n";



}


sub chk_log {

        $filename = "$ENV{DUT_PATH}/test/func_sim/vhdl/$log\.log";

          if(!open (FILEHANDLE_IN, "$filename"))
           { print "Cannot open file $filename: $!\n"; 
             close FILEHANDLE_IN;      
             exit 1;
           }

         $ok = 1;
        
          while (my $line = <FILEHANDLE_IN>)
           {

              if ($line =~ /ERROR\s+DETECTED/) 
               {
                 $ok = 0;
               }
           }


          close FILEHANDLE_IN;   
          
          if ($ok == 1)
          {
            system ("rm -f $filename");
            return 0;
          }
          else
          {
            return 1;
          }

}

sub calulate_rem {

  my $width = shift() + 0;
  
  if ($width >=8 and $width <= 16) {return 1;}
  if ($width == 32) {return 2;}
  if ($width == 64) {return 3;}
  return 4;


}

sub calulate_rem_vector {

  my $width = shift() + 0;

  if ($width ==128) {return 7;}
  return 3;

}