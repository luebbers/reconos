#!/usr/bin/env python
#
# \file mkCPUhwthread.py
#
# create a cpuhw_task pcore
#
# \author     Robert Meiche <rmeiche@gmx.de>
# \date       05.08.2009
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

import sys
import os
import os.path
import reconos
import reconos.pcore
import reconos.mhs
import reconos.mss
import reconos.tools
import datetime
import getopt
import string
import shutil
import getopt
import ctypes
from ctypes import c_uint32

task_name = "hw_task"

##global vars:
# sys_clk   : is set in function setGlbl_vars
# sys_reset : is set in function setGlbl_vars
# main_plb  : is set in function setGlbl_vars
# baseaddr  : the baseaddr of the bram_ctrl which has highaddr = 0xffffffff. is needed for bootcode calculation. is set in getBramLogicPort()


def exitUsage():
    sys.stderr.write("Usage: %s -n thread_num -t cpu_type [-i include dir] [-a address -s size] [-e ecos_size] source_file(s) ] \n" % os.path.basename(sys.argv[0]))
    sys.stderr.write("          -n threadnum        the number of the hw-task\n")
    sys.stderr.write("          -t cpu_type         which kind of CPU (PPC405|MICROBLAZE) \n")
    sys.stderr.write("          -i include dir      if there is another include dir except of the sw-dir use this option\n")
    sys.stderr.write("          -a address -s size      With these args you can specifiy the location in RAM and the size reserved in RAM \n")
    sys.stderr.write("                                  for the CPU_HWTHREAD program(HEX-VALS: e.g. 0x02000000). By default the first 32MB are\n")
    sys.stderr.write("                                  for ecos and 4MB for each CPU_HWTHREAD program are reserved. If you add\n") 
    sys.stderr.write("                                  these args, you have to check manually for overlapping regions with other programs!!!\n")
    sys.stderr.write("          -e ecos_size          if eCos should be greater than 32MB define the size in HEX\n")
    sys.stderr.write("          -p platform           Which FPGA: virtex4 or virtex2\n")
    sys.stderr.write("          source_file(s)   the sourcefile(s)(only the c file(s)) which are used by the cpu-hwt\n")
    sys.stderr.write("\nNOTE: thread numbers start at 1!\n")
    sys.exit(1)

def createXMDOptsFile(pcore_name):
    #checkif the opt file already exists
    if os.path.isfile("../../../sw/xmdopts"):
        #in this case add file to existing opt file
        #TODO: add code for appending elf to opt file
        xmdopts = None
    else:
        #create file
        xmdopts = open("../../../sw/xmdopts", "w")
        xmdopts.write("connect ppc hw\n")
        xmdopts.write("dow " + pcore_name + ".elf \n")
        xmdopts.close()

def createLinkerscript(pcore_name, bram_logic_port, thread_addr, thread_size):
    cpu_nr = (bram_logic_port.split("_"))[4] # BRAM_LOGIC_CPU_PORT_[nr] is the naming of the cpu ports
    boot0addr = int(baseaddr, 16) + (int(cpu_nr) * 0x100) #baseaddr is global
    if thread_addr == None:
        thread_size = int("0x00400000", 16)
        thread_addr = int("0x03800000", 16) + (int(cpu_nr) * thread_size)
        
                
    # set up substitutions for linkerscript template
    subst = [ 
        ('\$template:bootaddr\$', "0x%X" % boot0addr),
        ('\$template:thread_addr\$', "0x%X" % thread_addr),
        ('\$template:thread_size\$', "0x%X" % thread_size)
    ]
    templ_name = os.environ['RECONOS'] + '/sw/templates/cpuhwt_linkerscript.template'
    ls_name = '../../../sw/'+ pcore_name +'.ld' 
    reconos.tools.make_file_from_template(templ_name, ls_name, subst)

def createSWMakefile(pcore_name, bram_logic_port, cpuhwt_type, files, ecos_size):
    linkerscript = pcore_name + '.ld'
    libpath = '../hw/edk-static/' + pcore_name + '/lib'
    output = pcore_name + '.elf'
    include = '-I../hw/edk-static/'+ pcore_name + '/include'
    
    # set up substitutions for Makefile template
    subst = [ 
        ('\$template:sourcefiles\$', string.join([ os.path.basename(f) for f in files ], ' ')),
        ('\$template:linkerscript\$', linkerscript),
        ('\$template:libpath\$', libpath),
        ('\$template:output\$', output),
        ('\$template:include\$', include)
    ]
    templ_name = os.environ['RECONOS'] + '/tools/makefiles/templates/Makefile_cpuhwt_sw_ppc405.template'
    makefile_name = '../../../sw/'+ pcore_name +'.make' 
    reconos.tools.make_file_from_template(templ_name, makefile_name, subst)
    #now check if this is first CPU_HWT
    cpu_nr = (bram_logic_port.split("_"))[4] # BRAM_LOGIC_CPU_PORT_[nr] is the naming of the cpu ports
    if int(cpu_nr) == 0:
        #this is the first, so the main makefile has to be created
        main_templ = os.environ['RECONOS'] + '/tools/makefiles/templates/Makefile_cpuhwt_main.template'
        main_mkf = '../../../sw/cpuhwt.make'
        if ecos_size != None:
            optargs = "-e " + ecos_size
        else:
        #    sys.stderr.write("ERROR thread_size= None!\n")
            optargs = ""
            
        subst = [('\$template:target\$', pcore_name + '.make'), 
                        ('\$template:elf\$', pcore_name + '.elf'), 
                        ('\$template:optargs\$', optargs)
                    ]
        reconos.tools.make_file_from_template(main_templ, main_mkf, subst)
    #else:
        #otherwise the TARGETS has to be updated

#This function sets the global variables like sys_clk
def setGlbl_vars(mhs):
    global sys_clk
    global sys_reset
    global main_plb
    global lib_name
    global lib_dir_name
    
    lib_dir_name = "kapi_cpuhwt_v1_00_a"
    lib_name = "kapi_cpuhwt"
    instances = mhs.getPcores("plb_v34")
    xps_instances = mhs.getPcores("plb_v46")
    
    if len(xps_instances) > 0:
        #instances.append(xps_instances)
        if len(instances) == 0:
            instances = xps_instances
        else:
            instances.append(xps_instances)
    
    if len(instances) <= 0:
        sys.stderr.write("ERROR, no PLB bus in system!\n")
        sys.exit(1)
           
    found = 0
    for pcore in instances:
        if pcore.instance_name == "plb":
            sys.stderr.write("pcore: %s" % pcore.instance_name) 
            found = 1
            main_plb = "plb"
            sys_clk = pcore.getValue("PLB_Clk")
            sys_reset = pcore.getValue("SYS_Rst")
    
    #if no plb with instance_name "plb" found just take the first plb instance as main_plb
    if found == 0:
        sys.stderr.write("ERROR found == 0!\n")
        main_plb = instances[0].instance_name
        sys_clk = instances[0].getValue("PLB_Clk")
        sys_reset = instances[0].getValue("SYS_Rst")  

def insert_cpuhwt(pcore, cpuhwt_type, pcore_name, task_number, bram_logic_port, c_boot_sect_data,  platform):
    if cpuhwt_type == "PPC405":
        pcore.instance_name = pcore_name
        if (platform =="virtex2"):
            pcore.setValue("HW_VER","2.00.d")
        elif (platform =="virtex4"):
            pcore.setValue("HW_VER","1.01.d")
        pcore.addEntry("BUS_INTERFACE", "IPLB", main_plb)
        pcore.addEntry("BUS_INTERFACE", "DPLB", main_plb)
        pcore.addEntry("BUS_INTERFACE", "OSIF", "osif_"+str(task_number - 1)+"_OSIF")
        pcore.addEntry("BUS_INTERFACE", "BRAM_LOGIC", bram_logic_port)
        pcore.addEntry("PARAMETER", "C_BOOT_SECT_DATA", c_boot_sect_data)
        sys.stderr.write("\n!!!CPU_HWT for \"%s\" was successfully connected. The cpu_clk was connected to \"OSIF-CLK\". \nIf you wish a higher frequency connect it manually to another clock!!!\n\n" % (pcore_name))

def set_cpuhwt_lib():
    lib_path = os.environ["RECONOS"] + "/core/ecos/" + lib_dir_name
    lib_dir = "../../edk-static/sw_services"
    #create dir sw_services
    os.mkdir(lib_dir)
    #now create link to library
    os.symlink(lib_path, "../../edk-static/sw_services/"+lib_dir_name)
    
def getBootSectData(bram_logic_port):
    cpu_nr = (bram_logic_port.split("_"))[4] # BRAM_LOGIC_CPU_PORT_[nr] is the naming of the cpu ports
    start_addr_boot0 = int(baseaddr, 16) + (int(cpu_nr) * 0x100)
    #now calculate the opcode
    branchrel_command = c_uint32(0x12).value # 10010 is the opcode for 'b' (branch relativ)
    addr = c_uint32(start_addr_boot0).value #the desired address
    #Start after CPU reset is 0xFFFFFFFC
    #From there a relative branch is taken to the .boot0 section
    #If this section is for example at 0xFFFFD000 you have to add 0xFFFFD004 to 0xFFFFFFFC
    #to get address 0xFFFFD000 
    result1 = c_uint32(addr + 0x4).value
    #But for the opcode we need the firs 6 bits and the last 2 bits
    #the ppc afterwards set the bits 1 to 6 to SIGN EXTENDING and zeros the last two bits
    #because only the bits 6 to 29 are used for calculating the address
    #The opcode for the relativ branch has the following structure
    # bit 0 - 5 : there we add the opcode 010010
    # bit 6 - 29: LI: this is used for calculating the branch address
    # bit 30    : has to be 0 for relative addressmode
    # bit 31    : has to be 0 so that the LR isn't updated
    mask = c_uint32(0x03FFFFFC).value  #The mask so that the first 6bits are 0 and the last 2bits are 0
    opcode_li = c_uint32(result1 & mask).value #'extract' the LI from the result1
    opcode_mask = c_uint32(branchrel_command << 26).value 
    opcode = c_uint32(opcode_li | opcode_mask).value  #set bit 0-5 and bit 30-31 with the opcode_mask 
       
    return "0x%X" % opcode
                                            
#This function checks, if a cpu_hwt_bram_logic is already instantiated
#if not it will instantiate this logic
# return value is an free CPU-Port of the cpu_hwt_bram_logic
def getBramLogicPort(mhs):
    global baseaddr  #this is used also by another function
    instance = mhs.getPcore("cpu_hwt_bram_logic")
    if instance == None:
        bram_logic = reconos.mhs.MHSPCore("cpu_hwt_bram_logic")
        bram_logic.instance_name = "CPUHWT_BRAM_LOGIC"
        bram_logic.addEntry("PARAMETER","HW_VER","1.00.a")
        
        instances = mhs.getPcores("plb_bram_if_cntlr")
        xps_instances = mhs.getPcores("xps_bram_if_cntlr")
        #instances.append(xps_instances)
        if len(instances) == 0:
            instances = xps_instances
        else:
            instances.append(xps_instances)
    
        if len(instances) > 0:
            bus_interface_porta = ""
            found = 0
            for bc in instances:
                if (bc.getValue("C_HIGHADDR") == "0xffffffff") or (bc.getValue("C_HIGHADDR") == "0xFFFFFFFF"):
                    #this is the right bram_ctrl
                    #now get Value of PortB and start searching for right BRAM_BLOCK
                    found = 1       
                    bus_interface_porta = bc.getValue("PORTA")
                    baseaddr = bc.getValue("C_BASEADDR")
                    break
            
            if found == 0:
                sys.stderr.write("ERROR, no BRAM-CTRL which ends at Address 0xFFFFFFFF!\n")
                sys.exit(1)
            #if bramctrl was found check if via baseaddr if the bramsize is big enough
            #it should be > 16kb because we leave 8kb for ecos
            bram_size = 0xffffffff - int(baseaddr, 16)
            if bram_size < 0x3fff:
                sys.stderr.write("Size of bram_ctrl with C_HIGHADDR=0xFFFFFFFF is too small. It has to be minimum 16kb!!!!\n")
                sys.exit(1) 
            #now manipulate the eCos linkerscript (target.ld) to reduce the bram-space used by eCos
            #this is done because the eCos executable is loaded last and if the whole bramspace is added in target.ld
            #all the boot0 sections of the CPU-HW-Threads will be zeroed
            
            #get all BRAM_BLOCK instances
            instances = mhs.getPcores("bram_block")
            
            if len(instances) <= 0:
               sys.stderr.write("ERROR, no BRAM-BLOCKS in system!\n")
               sys.exit(1) 
           
            #search all instances for the right bram_block (the bram which is connected to the right bram_ctrl)
            for bb in instances:
                if bb.getValue("PORTA") == bus_interface_porta:
                    #set PORTB to bram_ctrl_logic
                    ##check if PORTB is already used
                    portb_val = bb.getValue("PORTB")
                    if portb_val != None:
                        sys.stderr.write("ERROR, PORTB of %s is not free! \n" % bb.instance_name)
                        sys.exit(1)
                    #connect cpu_hwt_bram_logic with bram_block    
                    bb.addEntry("BUS_INTERFACE", "PORTB", "CPU_HWT_BRAM_LOGIC_PORT")
                    bram_logic.addEntry("BUS_INTERFACE", "PORTB", "CPU_HWT_BRAM_LOGIC_PORT")
                    #now connect clk and rst
                    bram_logic.addEntry("PORT", "clk", sys_clk)
                    bram_logic.addEntry("PORT", "reset", sys_reset)
                    #This is the first instantiation of the cpu_hwt_bram_logic so we return the CPU0 Port
                    ret_val = "BRAM_LOGIC_CPU_PORT_0"
                    bram_logic.addEntry("BUS_INTERFACE", "CPU0", ret_val)
                    #Because this is the first CPUHWT the library has to be linked to the edk dir
                    set_cpuhwt_lib()
                    break
            
            mhs.pcores.append(bram_logic)
            return ret_val
               
        else:
            sys.stderr.write("ERROR, no BRAM-CTRL Instance!\n")
            sys.exit(1)
     
    else:
       sys.stderr.write("ERROR. This toolchain can only manage 1 CPU-HW-Thread!\n")  
       sys.exit(1)
     
def main(args):

    if os.environ["RECONOS"] == "":
        sys.stderr.write("RECONOS environment variable not set.\n")
        sys.exit(1)
    
    #parsing args
    try:
        opts, args = getopt.getopt(args, "n:t:i:a:s:e:p:")
    except getopt.GetoptError, err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        exitUsage()

    task_number = None
    cpuhwt_type = None
    files = args
    #optional args
    include_dir = None
    thread_addr = None
    thread_size = None
    ecos_size = None
    platform = None
    for o, a in opts:
        if o == "-n":
            task_number = int(a)
        elif o in ("-h", "--help"):
            exitUsage()
        elif o == "-t":
            cpuhwt_type = a
        elif o == "-i":
            include_dir = a
        elif o == "-a":
            thread_addr = a
        elif o == "-s":
            thread_size = a
        elif o == "-e":
            ecos_size = a
        elif o == "-p":
            platform = a
    
    #check if needed args are set
    if task_number == None:
        sys.stderr.write("No tasknumber!\n")
        exitUsage()
    if cpuhwt_type == None:
        sys.stderr.write("No CPU_TYPE!\n")
        exitUsage()
    if (files == None) or (len(files) == 0):
        sys.stderr.write("No Sourcefile!\n")
        exitUsage()
    #check if size AND addr arg are set. If only one arg is set throw an error
    if ( (thread_addr == None) ^ (thread_size == None) ):
       sys.stderr.write("Arguments for thread_size and address are not set correctly\n")
       exitUsage() 
    #check platform arg
    if (platform == None):
        platform="virtex2"
    elif ( (platform != "virtex2") and (platform !="virtex4")):
        sys.stderr.write("Wrong platform\n")
        exitUsage() 
    
    pcore_name = task_name + "_v1_%02i_b" % task_number    
    readme_text = """
This HW-Task is a CPU-HW-Task!
HW_TASK_%s is using the CPU Pcore %s
The HW_INSTANCE is %s""" % (task_number, cpuhwt_type, pcore_name)
    
    #create the hw_task directory and create a readme to inform the user that this is a CPU-HWT
    readme_file = pcore_name + "/readme.txt"
    os.mkdir(pcore_name)
    open(readme_file, "w").write(readme_text)
    
    #Now check which cpu_type and begin scanning/modifiing the mhs file
    mhs_file = "../../edk-static/system.mhs"
    mhs_new  = "../../edk-static/system.mhsnew"
    mss_file = "../../edk-static/system.mss"
    mss_new  = "../../edk-static/system.mssnew"
    mhs = reconos.mhs.MHS(mhs_file)
    mss = reconos.mss.MSS(mss_file)
    #before scanning, set the global vars
    setGlbl_vars(mhs)
    
    if cpuhwt_type == "PPC405":
        if (platform == "virtex2"):
            ppc_instances = mhs.getPcores("ppc405")
        elif (platform =="virtex4"):
            ppc_instances = mhs.getPcores("ppc405_virtex4")
        
        if (len(ppc_instances)) <= 1:
            #the toolchain requires that the reference design has already instantiated the processors
            sys.stderr.write("Only one PowerPC in system!\n")
            sys.exit(1)
        else:
            found = 0
            ppc_core = None
            #search for ppc instance which is not used
            for pcore in ppc_instances:
                #ppc405_0 is the ecos cpu
                if pcore.instance_name != "ppc405_0":
                    #make a simple check if ppc is already used (if the IPLB is connected the PPC could be in use)
                    if pcore.getValue("IPLB") == None:
                        #delete hw_task which was initialy instantiated
                        hw_task_name = "hw_task_" + str(task_number - 1) #the instance_name begin with 0
                        mhs.delPcore(hw_task_name)
                        ppc_core = pcore        
                        found = 1
                        break;
            
            if found == 0:
                sys.stderr.write("ERROR: All PPCs are in use!!!\n")
                sys.exit(1)
            
            #now check, if the bram_logic is already instantiated and get the port
            #sys.stderr.write(mhs.__str__())

            bram_logic_port = getBramLogicPort(mhs)
            c_boot_sect_data = getBootSectData(bram_logic_port)
            mss_change_proc_inst = pcore.instance_name #the instance_name is needed for the changes in mss
            insert_cpuhwt(pcore, cpuhwt_type, pcore_name, task_number, bram_logic_port, c_boot_sect_data,  platform)
            #now update the mss file
            #first change instance of the OS and the PROCESSOR
            os_element = mss.getOS(mss_change_proc_inst)
            os_element.setValue("PROC_INSTANCE", pcore_name)
            proc_element = mss.getElement(mss_change_proc_inst)
            proc_element.instance_name = pcore_name
            #now check the other OS for stdin/stdout
            stdin = None
            stdout = None
            os_elements = mss.getElements("OS")
            for el in os_elements:
                if el.getValue("PROC_INSTANCE") != pcore_name:
                    if el.getValue("STDOUT") != None:
                        stdout = el.getValue("STDOUT")
                        stdin  = el.getValue("STDOUT")
            if (stdin != None) and (stdout != None):
                os_element.addEntry("STDOUT", stdout)
                os_element.addEntry("STDIN", stdin)
            #set the library
            lib_element = reconos.mss.MSSElement("LIBRARY")
            lib_element.addEntry("LIBRARY_NAME", lib_name)
            lib_element.addEntry("LIBRARY_VER", "1.00.a")
            lib_element.addEntry("PROC_INSTANCE", pcore_name)
            lib_element.addEntry("CPU_TYPE", cpuhwt_type)
            mss.elements.append(lib_element)            
            #write mhs file
            open(mhs_new, "w").write(str(mhs))
            shutil.move(mhs_new, mhs_file)
            #write mss file                                        
            open(mss_new, "w").write(str(mss))
            shutil.move(mss_new, mss_file)
            #create linkerscript
            createLinkerscript(pcore_name, bram_logic_port, thread_addr, thread_size)
            #now create the Makefile in sw directory
            createSWMakefile(pcore_name, bram_logic_port, cpuhwt_type, files, ecos_size)
            #createthe opt file for xmd 
            createXMDOptsFile(pcore_name)
            
    else:
       sys.stderr.write("This verion of the toolchain is only configured for the PPC405 CPU-TYPE!!!!\n")
       sys.exit(1) 
    
if __name__ == "__main__":
    main(sys.argv[1:])
    
