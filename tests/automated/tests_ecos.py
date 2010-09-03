#!/usr/bin/python
"""
Defines ReconOS test cases for eCos
"""
#
# \file tests_ecos.py
#
# \author Andreas Agne <agne@upb.de>
# \date   08.02.2008
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

from testing import *
import re, os, time

# creates a dictionary of configuration options which gets passed to most of the low-level
# test functions
def create_reconos_config():
    cfg = {}
    # the location of the 'download_bitstream' command:
    cfg["download_bitstream"]  = os.environ["RECONOS"] + "/tools/impact/download_bitstream.sh"
    # the location of the 'download_executable' script:
    cfg["download_executable"] = os.environ["RECONOS"] + "/tools/xmd/download_executable.sh"
    # the location of the 'impact_unlock' script:
    cfg["impact_unlock"]       = os.environ["RECONOS"] + "/tools/impact/impact_unlock.sh"
    # the serial port device file:
    cfg["serial_port"]     = "/dev/ttyS0"
    # the command to set up the serial port:
    cfg["setup_serial_port"]   = "stty -F " + cfg["serial_port"] + " speed 57600 raw"
    # the timeout for downloading the bitstream:
    cfg["impact_timeout"]      = 30.0
    # the timeout for downloading the executable:
    cfg["xmd_timeout"]     = 20.0
    # the timeout for running the executable:
    cfg["executable_timeout"]  = 20.0
    # the timeout for software builds:
    cfg["swbuild_timeout"]     = 120.0
    # the timeout for hardware builds:
    cfg["hwbuild_timeout"]     = 45*60.0
    # the timeout for the execution of shell scripts:
    cfg["shell_cmd_timeout"]   = 10.0
    # verbose output requested?
    cfg["verbose"]         = False
    
    return cfg

supportedBoards = ('xup', 'ml403', 'ml605')
baseDesign = {'xup': os.environ["RECONOS"] + "/support/refdesigns/10.1/xup/xup_light",
              'ml403': os.environ["RECONOS"] + "/support/refdesigns/12.2/ml403/ml403_light",
              'ml605': os.environ["RECONOS"] + "/support/refdesigns/12.2/ml605/ml605_light"}
arch = {'xup': 'ppc',
        'ml403': 'ppc',
        'ml605': 'mb'}
tests = {}
cfg = create_reconos_config()
#cfg["verbose"] = True;
testdir = os.environ["RECONOS"] + "/tests/automated/"

def create_html(mytests, directory):
    FAILED = """<font color="#FF0000"><b>Failed</b></font>"""
    PASSED = """<font color="#00FF00"><b>Passed</b></font>"""
    SKIPPED = """<font color="#0000FF"><b>Skipped</b></font>"""
    
    d = directory + "/" + "html_"# + time.asctime().replace(" ","_").replace(":","")
    os.mkdir(d)
    index = open(d + "/index.html","w")
    index.write("<html>\n<head><title>Test Results " + time.asctime() + "</title></head>\n")
    index.write("<body>\n<table><tr bgcolor=\"#ccccff\"><th>&nbsp;Test name&nbsp;</th><th>&nbsp;Time&nbsp;</th><th>&nbsp;Duration&nbsp;</th><th>&nbsp;Result&nbsp;</th></tr>\n")
    i = 0
    for name in mytests:
        t = mytests[name]
        i = i + 1
        if i % 2 == 0:
            c0 = "#ddddff"
            c1 = "#eeeeff"
        else:
            c1 = "#ddddff"
            c0 = "#eeeeff"
        
        res = ""
        if t.result == True:
            res += PASSED
        elif t.result == False:
            res += FAILED
        else:
            res += SKIPPED
        if t.skip:
            res += ", " + SKIPPED
            
        index.write("""<tr><td bgcolor="%s">%s&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td bgcolor="%s" align="right">%s</td><td bgcolor="%s" align="right">%d</td><td bgcolor="%s" align="center">%s</td></tr>\n""" % (c0,name,c1,t.time,c0,int(t.duration),c1,res))
    p = len(filter(lambda x: x.result == True, mytests.values()))
    f = len(filter(lambda x: x.result == False, mytests.values()))
    s = len(filter(lambda x: x.result == None, mytests.values()))
    total_time = reduce(lambda x,y: y.duration + x,mytests.values(),0) 
    index.write("""<tr><td align="center"><b>total</b></td><td align="right"></td><td align="right">%s</td><td align="center">%d passed, %d failed</td></tr>""" % (total_time,p,f))
    index.write("</table>\n</body>\n</html>\n")
    index.close()

def parse_args(args):
    todo = {}
    board = 'xup'

    # if no "-n" flag given, include all tests by default
    if (not ("-n" in args)):
        for name in tests: todo[name] = tests[name]
    
    for idx in range(len(args)):
        if args[idx] == "--lazy":
            for name in tests:
                t = tests[name]
                if t.swtargets:
                    t.swtargets = filter(lambda x: not x in ["clean","mrproper"], t.swtargets)
                if t.hwtargets:
                    t.hwtargets = filter(lambda x: not x in ["clean","mrproper"], t.hwtargets)
        
        elif args[idx] == "--include":
            rexpr = re.compile(args[idx + 1])
            for name in tests:
                if rexpr.search(name):
                    todo[name] = tests[name]
        
        elif args[idx] == "--exclude":
            rexpr = re.compile(args[idx + 1])
            tmp = {}
            for name in todo:
                if not rexpr.search(name):
                    tmp[name] = todo[name]
            todo = tmp
            
        elif args[idx] == "--pass":
            rexpr = re.compile(args[idx + 1])
            for name in tests:
                if rexpr.search(name):
                    tests[name].skip = True
                    tests[name].result = True
        
        elif args[idx] == "--fail":
            rexpr = re.compile(args[idx + 1])
            for name in tests:
                if rexpr.search(name):
                    tests[name].skip = True
                    tests[name].result = False
        
        elif args[idx] == "--board":
            board = args[idx + 1]
            if board not in supportedBoards:
                print("ERROR: '" + board + "' not supported.")
                print("Use one of " + str(supportedBoards))
                return
                
        elif args[idx] == "--tty":
            tty = args[idx + 1]
            cfg["serial_port"]     = tty
                
        elif args[idx] in ["-v", "--verbose"]:
            cfg["verbose"] = True

        elif args[idx] in ["--help", "-h", "--list", "--html", "-n", "--auto", "-a"]:
            continue

        # not a recognized keyword
        elif args[idx].startswith("-") :
            print "unrecognized option: " + args[idx]
            print "use '--help' for a list of possible options"
            return

    
    if "--help" in args or "-h" in args:
        print "Options:"
        print "-h, --help     display this help message"
        print "-n             do not include all tests by default"
        print "-v, --verbose  be verbose"
        print "-a, --auto     automatically include all dependencies"
        print "--list         do not perform the tests, just list them"
        print "--lazy         do not make 'clean' and 'mrproper' targets"
        print "--include <regex>  include tests that match <regex>"
        print "--exclude <regex>  exclude tests that match <regex>"
        print "--pass <regex>     assume all tests that match <regex> to pass"
        print "--fail <regex>     assume all tests that match <regex> to fail"
        print "--board <xup|ml403>  use specified board for tests (default: XUP)"
        print "--tty <tty_device>   use specified device for serial communications"
        print "                     (default: /dev/ttyS0)"
        print
        print "The default behaviour is to perform all tests inclusive 'clean' and 'mrproper' targets."
        print "This can be overriden with the '-n' option."
        print "Note: The order matters in which --include --exclude --fail and --pass are specified on the command line."
        return
        
    if "--auto" in args or "-a" in args:
        done = False
        while not done:
            done = True
            for t in todo.keys():
                for d in todo[t].depends:
                    if not (d.name in todo.keys()):
                        print "Added " + d.name + " to resolve dependency"
                        todo[d.name] = d
                        done = False

    if "--list" in args:
        names = todo.keys()
        names.sort()
        for name in names:
            print name
        return

    for t in tests:
        # set environments that affect which board to use
        tests[t].environ['EDK_BASE_DIR'] = baseDesign[board]
        tests[t].environ['RECONOS_BOARD'] = board
        tests[t].environ['ARCH'] = arch[board]

    if not os.path.exists("/tmp/test_results"):
        os.mkdir("/tmp/test_results")
    evaluate_tests(todo.values(),"/tmp/test_results")
    
    if "--html" in args:
        create_html(todo,"/tmp/test_results")
    

def create_test(name):
    tests[name] = Test(cfg,name)
    return tests[name]

def build_hardware(basename):
    # Create the hardware
    t = create_test("hw_" + basename)
    t.hwdir     = testdir + basename + "/hw"
    t.hwtargets = ["clean","all"]
    
    
def build_ecos_library(basename):
    # Create the ecos ecos library
    t = create_test("sw_" + basename + "_ecos_library")
    t.depends   = [tests["hw_" + basename]]
    t.swdir     = testdir + basename + "/sw"
    t.hwdir     = testdir + basename + "/hw"
    t.swtargets = ["mrproper","clean","setup"]  

def build_programs(basename,targets):
    # Software
    t = create_test("sw_" + basename)
    t.depends   = [tests["hw_" + basename], tests["sw_" + basename + "_ecos_library"]]
    t.swdir     = testdir + basename + "/sw"
    t.hwdir     = testdir + basename + "/hw"
    t.swtargets = targets

def build_ecos_program(basename):
    # Software (ecos api)
    t = create_test("sw_" + basename + "_ecos")
    t.depends   = [tests["hw_" + basename], tests["sw_" + basename + "_ecos_library"]]
    t.swdir     = testdir + basename + "/sw"
    t.hwdir     = testdir + basename + "/hw"
    t.swtargets = [basename + "_test_ecos.elf"]

def build_posix_program(basename):
    # Software (posix api)
    t = create_test("sw_" + basename + "_posix")
    t.depends   = [tests["hw_" + basename], tests["sw_" + basename + "_ecos_library"]]
    t.swdir     = testdir + basename + "/sw"
    t.hwdir     = testdir + basename + "/hw"
    t.swtargets = [basename + "_test_posix.elf"]

def execute_program(basename, progname, output):
    # Execute program (ecos api)
    t = create_test("exec_" + basename + "_" + progname)
    t.depends   = [tests["hw_" + basename], tests["sw_" + basename], tests["shell_identifyBoard.sh"]]
    t.bitfile   = testdir + basename + "/hw/edk-static/implementation/system.bit"
    t.elffile   = testdir + basename + "/sw/" + progname
    t.set_output(output)
    
def execute_ecos_program(basename, output):
    # Execute program (ecos api)
    t = create_test("exec_" + basename + "_ecos")
    t.depends   = [tests["hw_" + basename], tests["sw_" + basename + "_ecos"], tests["shell_identifyBoard.sh"]]
    t.bitfile   = testdir + basename + "/hw/edk-static/implementation/system.bit"
    t.elffile   = testdir + basename + "/sw/" + basename + "_test_ecos.elf"
    t.set_output(output)

def execute_posix_program(basename, output):
    # Execute program (posix api)
    t = create_test("exec_" + basename + "_posix")
    t.depends   = [tests["hw_" + basename], tests["sw_" + basename + "_posix"], tests["shell_identifyBoard.sh"]]
    t.bitfile   = testdir + basename + "/hw/edk-static/implementation/system.bit"
    t.elffile   = testdir + basename + "/sw/" + basename + "_test_posix.elf"
    t.set_output(output)

def execute_shell_command(dir, cmd):
    # locally execute a shell script 'cmd' in dir 'dir'
    basename = os.path.basename(cmd)
    t = create_test('shell_' + basename)
    t.shellcmd = cmd
    t.shelldir = dir


##############################################################################
# check for correct board connection

execute_shell_command('/tmp', os.environ['RECONOS'] + '/tools/impact/identifyBoard.sh')



##############################################################################
# mbox tests

build_hardware("mbox")
build_ecos_library("mbox")
build_posix_program("mbox")
build_ecos_program("mbox")
execute_posix_program("mbox","""    
begin mbox_test_posix
creating hw thread... ok
sent: 1 (retval 0)
recvd: 2 (retval 4)
sent: 2 (retval 0)
recvd: 3 (retval 4)
sent: 3 (retval 0)
recvd: 4 (retval 4)
sent: 4 (retval 0)
recvd: 5 (retval 4)
sent: 5 (retval 0)
recvd: 6 (retval 4)
sent: 6 (retval 0)
recvd: 7 (retval 4)
sent: 7 (retval 0)
recvd: 8 (retval 4)
sent: 8 (retval 0)
recvd: 9 (retval 4)
sent: 9 (retval 0)
recvd: 10 (retval 4)
sent: 10 (retval 0)
recvd: 11 (retval 4)
mbox_test_posix done.
""")
execute_ecos_program("mbox","""
begin mbox_test_ecos
creating hw thread... ok
sent: 1 (retval 1)
recvd: 2
sent: 2 (retval 1)
recvd: 3
sent: 3 (retval 1)
recvd: 4
sent: 4 (retval 1)
recvd: 5
sent: 5 (retval 1)
recvd: 6
sent: 6 (retval 1)
recvd: 7
sent: 7 (retval 1)
recvd: 8
sent: 8 (retval 1)
recvd: 9
sent: 9 (retval 1)
recvd: 10
sent: 10 (retval 1)
recvd: 11
mbox_test_ecos done.
""")

##############################################################################
# semaphore tests
build_hardware("semaphore")
build_ecos_library("semaphore")
build_posix_program("semaphore")
build_ecos_program("semaphore")
execute_posix_program("semaphore","""   
begin semaphore_test_posix
creating hw thread... ok
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
post semaphore A (retval = 0)
wait for semaphore B
semaphore B aquired (retval = 0)
semaphore_test_posix done.
""")
execute_ecos_program("semaphore","""
begin semaphore_test_ecos
ok
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
post semaphore A
wait for semaphore B
semaphore B aquired (retval = 1)
semaphore_test_ecos done.
""")



##############################################################################
# mutex tests
build_hardware("mutex")
build_ecos_library("mutex")
build_posix_program("mutex")
build_ecos_program("mutex")
execute_posix_program("mutex","""
begin mutex_test_posix
creating hw thread... ok
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex_test_posix done.
""")
execute_ecos_program("mutex","""
begin mutex_test_ecos
creating hw thread... ok
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex lock and release by hwthread: success
mutex_test_ecos done.
""")

##############################################################################
# condvar tests
build_hardware("condvar")
build_ecos_library("condvar")
build_posix_program("condvar")
build_ecos_program("condvar")
execute_posix_program("condvar","""
begin condvar_test_posix
creating hw thread... ok
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
condvar_test_posix done.
""")
execute_ecos_program("condvar","""
begin condvar_test_ecos
creating hw thread... ok
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
signaling condition a
condition b
condvar_test_ecos done.
""")

##############################################################################
# memcopy tests
build_hardware("memcopy")
build_ecos_library("memcopy")

memcopy_tests = [("memcopy_test_4.elf", 4),
         ("memcopy_test_128.elf", 128),
         ("memcopy_test_1024.elf", 1024),
         ("memcopy_test_5000.elf", 5000)]

build_programs("memcopy",[ x[0] for x in memcopy_tests ])

for x in memcopy_tests:
    execute_program("memcopy", x[0], """
begin memcopy_test_posix
creating hw thread... ok
memcopy ok. (%d bytes copied correctly)
memcopy_test_posix done.
""" % x[1] )


##############################################################################
# burstlen tests
build_hardware("burstlen")
build_ecos_library("burstlen")

#          executable             bytes copied
burstlen_tests = [("burstlen_test_1024_16_128.elf", 1024),
          ("burstlen_test_1024_16_256.elf", 512),
          ("burstlen_test_1024_15_128.elf", 960),
          ("burstlen_test_1024_15_256.elf", 480),
          ("burstlen_test_1024_14_128.elf", 896),
          ("burstlen_test_1024_14_256.elf", 448),
          ("burstlen_test_1024_13_128.elf", 832),
          ("burstlen_test_1024_13_256.elf", 416),
          ("burstlen_test_1024_12_128.elf", 768),
          ("burstlen_test_1024_12_256.elf", 384),
          ("burstlen_test_1024_11_128.elf", 704),
          ("burstlen_test_1024_11_256.elf", 352),
          ("burstlen_test_1024_10_128.elf", 640),
          ("burstlen_test_1024_10_256.elf", 320),
          ("burstlen_test_1024_9_128.elf", 576),
          ("burstlen_test_1024_9_256.elf", 288),
          ("burstlen_test_1024_8_64.elf", 1024),
          ("burstlen_test_1024_8_128.elf", 512),
          ("burstlen_test_1024_7_64.elf", 896),
          ("burstlen_test_1024_7_128.elf", 448),
          ("burstlen_test_1024_6_64.elf", 768),
          ("burstlen_test_1024_6_128.elf", 384),
          ("burstlen_test_1024_5_64.elf", 640),
          ("burstlen_test_1024_5_128.elf", 320),
          ("burstlen_test_1024_4_32.elf", 1024),
          ("burstlen_test_1024_4_64.elf", 512),
          ("burstlen_test_1024_3_32.elf", 768),
          ("burstlen_test_1024_3_64.elf", 384),
          ("burstlen_test_1024_2_16.elf", 1024),
          ("burstlen_test_1024_2_32.elf", 512)]

build_programs("burstlen",[ x[0] for x in burstlen_tests ])

for x in burstlen_tests:
    execute_program("burstlen", x[0], """
begin burstlen_test_posix
creating hw thread... ok
memcopy ok. (%d bytes copied correctly)
burstlen_test_posix done.
""" % x[1] )


##############################################################################
# mq test
#build_hardware("mq")
#build_ecos_library("mq")
#build_posix_program("mq")
#execute_posix_program("mq","""
#begin mq_test
#creating hw thread...
#msgsize = 4
#msgsize = 8
#msgsize = 16
#msgsize = 32
#msgsize = 64
#msgsize = 128
#msgsize = 256
#msgsize = 512
#msgsize = 1024
#msgsize = 2048
#msgsize = 4096
#msgsize = 8192
#msgsize = 16384
#mq_test done.
#""")
#
## this test may take some time...
#tests["exec_mq_posix"].cfg = dict(tests["exec_mq_posix"].cfg)
#tests["exec_mq_posix"].cfg["executable_timeout"] = 900.0



#tmp = tests.values()
#tmp = filter(lambda x: "memcopy" in x.name, tmp)
#evaluate_tests(tmp,"/tmp/test_results")

parse_args(sys.argv)

quit()

