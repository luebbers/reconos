#!/usr/bin/python
"""
Framework for automated execution of ReconOS test cases
"""
#
# \file testing.py
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

import os, time, popen2, sys, threading, readline

# converts a string into an array of lines
def text2lines(text):
    lines = []
    line = ""
    for c in text:
        if c in ['\n','\r']:
            if len(line) > 0:
                lines.append(line)
                line = ""
        else:
            line = line + c
    
    if len(line) > 0: lines.append(line)
    return lines

# Compare input text to a given template
# input text and template are matched word for word, except if one of the following tokens is encountered:
#     $IGNORE      : matches any word in the imput text
#     $IGNORE_LINE : matches a line of input text
#     $i           : matches an integer and appends it to the self.variables array
#     $f           : matches a floating point number and appends it to self.variables
#     $s           : matches a word and appends it to self.variables
class Verifier(object):
    def __init__(self):
        self.lines = []          # the input text (array of lines)
        self.expect_lines = []   # the template
        self.strip = True        # should leading and trailing whitespace be removed?
        self.msg = None          # stores a short message, describing the result of the comparison
        self.variables = []      # stores the extracted variables
        
    def verify(self):
        i = 0
        while i < len(self.expect_lines):
            if i >= len(self.lines):
                self.msg = "expected %d more lines of input." % (len(self.expect_lines) - len(self.lines))
                return False
            
            expect = self.expect_lines[i]
            line   = self.lines[i]
            
            if self.strip:
                expect = strip_junk(expect.strip())
                line   = strip_junk(line.strip())
            
            tokens = filter(lambda x: len(x) > 0, line.split())
            expect_tokens = filter(lambda x: len(x) > 0, expect.split())
            
            for j in range(len(expect_tokens)):
                if j >= len(tokens):
                    self.msg = "expected %d more tokens in line %d\n" % (len(expect_tokens) - len(tokens), i)
                    self.msg += "expected: '" + expect + "'\n"
                    self.msg += "received: '" + line + "'\n"
                    return False
                
                if expect_tokens[j] == "$IGNORE":
                    continue
                elif expect_tokens[j] == "$IGNORE_LINE":
                    break
                elif expect_tokens[j] == "$i":
                    self.variables.append(int(tokens[j]))
                elif expect_tokens[j] == "$f":
                    self.variables.append(float(tokens[j]))
                elif expect_tokens[j] == "$s":
                    self.variables.append(tokens[j])
                elif expect_tokens[j] != tokens[j]:
                    self.msg  = "input mismatch at line %d, token %d: expected '%s', received '%s'\n" % (i,j,expect_tokens[j],tokens[j])
                    self.msg += "expected: '" + expect + "'\n"
                    self.msg += "received: '" + line + "'\n"
                    return False
            i = i + 1
            
        return True
    
    def set_text(self,text):
        self.expect_lines = text.strip().split("\n")

# Helper class for concurrent receiving of data from an input file
class Pipe(threading.Thread):
    def __init__(self, filename, max_lines = None):
        threading.Thread.__init__(self)
        
        self.filename = filename    # input file name (e.g. /dev/ttyS0)
        self.max_lines = max_lines  # maximum number of lines to read
        self.timeout = 0            # timeout in seconds
        self.log = ""               # name of the log file

        self.output_lines = []      # the text read from the file
        self.time = ""              # timestamp
        self.result = None          # indicates timeout

        self.setDaemon(True)
    
    def run(self):
        fin = open(self.filename,"r")
        i = 0
        t0 = time.time()
        self.time = time.asctime()
        self.duration = 0
        self.result = "TIMEOUT"
        
        self.output_lines = readline.readlines(fin,self.timeout,self.max_lines)
        if len(self.output_lines) == self.max_lines:
            self.result = "INPUT_COMPLETE"
        
        if self.log:
            if self.log == "-":
                fout = sys.stdout
            else:
                fout = open(self.log,"w")
            fout.write("file    : " + self.filename + "\n")
            fout.write("result  : " + str(self.result) + "\n")
            fout.write("lines   : " + str(len(self.output_lines)))
            if self.max_lines:
                fout.write(" (expected: " + str(self.max_lines) + ")\n")
            fout.write("time    : " + self.time + "\n")
            fout.write("duration: %0.2f seconds\n" % self.duration)
            fout.write("output  :\n")
            fout.writelines(self.output_lines)
            if fout != sys.stdout:
                fout.close()        
        
    def text(self):
        return reduce(lambda x,y: x + y, self.output_lines,"")

# This class encapsulates the execution of an external process
class Command(object):
    def __init__(self):
        self.cmdline = ""               # the command line (e.g. 'make clean all')
        self.env = {}                   # environment for the process
        self.timeout = 0                # the timeout in seconds
        self.expect_result = 0          # the expected return value
        self.result = 0                 # the return value of the process
        self.working_directory = "."    #
        self.output_lines = []          # contains the output of the process (stderr and stdout)
        self.log = ""                   # the name of the log file
        self.execution_time = ""        # the time the process was started
        self.duration = 0               # number of seconds it took the process to run
        
    def execute(self):
        old_cwd = os.getcwd()
        old_env = dict(os.environ)
        
        os.chdir(self.working_directory)
        for var in self.env:
            os.environ[var] = self.env[var]

        self.execution_time = time.asctime()
        p = popen2.Popen4(self.cmdline)
        
        t0 = time.time()
        
        self.output_lines = readline.readlines(p.fromchild,self.timeout,0)
                
        dt = time.time() - t0
        
        while dt < self.timeout:
            self.result = p.poll()
            if self.result != -1: break
            time.sleep(1)
            dt = time.time() - t0
        
        if (self.timeout != 0 and dt >= self.timeout) or self.result == -1:
            #print "timeout = ",self.timeout," dt = ",dt," result = ",self.result
            self.result = "TIMEOUT"
            os.system("kill " + str(p.pid))
            time.sleep(1)
            os.system("kill -9 " + str(p.pid))
        
        self.duration = time.time() - t0
            
        os.chdir(old_cwd)
        os.environ = old_env
        
        if self.log:
            if self.log == "-":
                fout = sys.stdout
            else:
                fout = open(self.log,"w")
            fout.write("command : " + self.cmdline + "\n")
            fout.write("dir     : " + os.path.abspath(self.working_directory) + "\n")
            fout.write("result  : " + str(self.result) + " (expected: " + str(self.expect_result) + ")\n")
            fout.write("time    : " + self.execution_time + "\n")
            fout.write("duration: %0.2f seconds\n" % self.duration)
            fout.write("output  :\n")
            fout.writelines(self.output_lines)
            if fout != sys.stdout:
                fout.close()
        
        return self.result == self.expect_result

# convenience shortcut function for executing commands
def command(cmd, timeout):
    c = Command()
    c.cmdline = cmd
    c.timeout = timeout
    c.execute()
    return c.result, reduce(lambda x,y: x + y, c.output_lines, "")
    

# download 'bitstream_file' to the FPGA
def download_bitstream(cfg, bitstream_file, timeout = 20.0):
    return command(cfg["download_bitstream"] + " " + bitstream_file, timeout)

# download the elf executable
def download_executable(cfg, elf_file, timeout = 20.0):
    return command(cfg["download_executable"] + " " + elf_file, timeout)

# sets up serial port
def setup_serial_port(cfg, timeout = 5):
    return command(cfg["setup_serial_port"], timeout)

# this kills all threads
def quit():
    os.execvp("/bin/true",["exit the program"])

# strips '\n', '\r' and '\0' from string s and returns the result
def strip_junk(s):
    result = ""
    for c in s:
        if c in ['\n','\r',chr(0)]: continue
        result += c
    return result
    
# tries to download 'bitfile' and 'elffile' to the target board and compares the output
# of the serial port with the (multi-line) string 'expect'
# Returns the tuple (result, why, details).
#     - 'result' is True if everything worked as expected, False otherwise
#     - 'why' contains a short description of the error, in case an error occured, 'why' is None otherwise
#     - 'details' contains the complete output of the command that failed. 'details' is None if no error occured.
#
def download_and_execute(cfg, bitfile, elffile, expect):
    if cfg["verbose"]:
        print "Unlocking cable..."
    
    command(cfg["impact_unlock"],20)
    
    if cfg["verbose"]:
        print "Downloading bitstream '" + bitfile + "'"
    result, output = download_bitstream(cfg, bitfile, cfg["impact_timeout"])
    if result != "TIMEOUT":
        if not result == 0:
            return False, "bitstream download failed", output
    else:
        return False, "bitstream download timed out (> " + str(cfg["impact_timeout"]) + " seconds)", output

        # set serial parameters (baud rate etc.)
        if cfg["verbose"]:
                print "Setting up serial port with '" + cfg["setup_serial_port"] + "'"
        result, output = setup_serial_port(cfg)
        if result != None:
                if not result == 0:
                        return False, "setting serial parameters failed", output
        else:
                return False, "setting serial parameters timed out", output
    
    pipe = Pipe("/dev/ttyS0")
    pipe.timeout = cfg["executable_timeout"]
    pipe.max_lines = len(expect)
    pipe.start()
    
    if cfg["verbose"]:
        print "Downloading executable '" + elffile + "'"
    result, output = download_executable(cfg, elffile, cfg["xmd_timeout"])
    if result != None:
        if not result == 0:
            return False, "executable download failed", output
    else:
        return False, "executable download timed out (> " + str(cfg["xmd_timeout"]) + " seconds)", output
    
    if cfg["verbose"]:
        print "Checking output..."

    pipe.join()
    result = pipe.result
    
    if result == "TIMEOUT":
        return False, "Program timed out", reduce(lambda x,y: x + y,pipe.output_lines,"")
    
    v = Verifier()
    v.lines = pipe.output_lines
    v.expect_lines = expect
    result = v.verify()

    return result, v.msg, pipe.output_lines
    
# the shell equivalent of this function is: cd 'swdir' && HW_DESIGN='hwdir' make 'target'
# returns the tuple (result, why, details) (see above...)
def build_sw(cfg, swdir, target, hwdir, environ):
    if cfg["verbose"]:
        print "make '" + target + "' in '" + swdir + "'"
    
    try:
        os.chdir(swdir)
    except OSError:
        return False,"Cannot chdir to directory '" + swdir + "'", ""
    
    if not "HW_DESIGN" in environ:
        environ["HW_DESIGN"] = hwdir + "/edk-static"

    # FIXME: workaround for possible bug in python
    # sometime, changes to os.environ are not propagated to the
    # child process when started with popen2.Popen4. As a workaround, we
    # include the necessary environment variables on the command line
    if len(environ) > 0:
        envstr = reduce(lambda a, b: a + " " + b, map(lambda x: x + "=" + environ[x], environ.keys()))
    else:
        envstr = ''
    result, output = command(envstr + " make " + target, cfg["swbuild_timeout"])
    
    if result != "TIMEOUT":
        if not result == 0:
            return False, "software build failed (target = " + target + ")", output
    else:
        return False, "software build timed out (target = " + target + ")", output

    return True, None, output

# Unfortunately xps does not generate correct exit values. This function tries to figure out,
# if an error occured based on the program output
def xilinx_error(output):
    return "ERROR:" in output

# executes a shell command. Used e.g. for small test scripts (identifyXUP
# etc.)
# returns the tuple (result, why, details) (see above...)
def execute_shell_cmd(cfg, cmd, dir, environ):
    if cfg["verbose"]:
        print "execute '" + cmd + "' in '" + dir + "'"
    
    try:
        os.chdir(dir)
    except OSError:
        return False,"Cannot chdir to directory '" + dir + "'", ""

    # prepend additional environment (see build_sw for elaboration)
    if len(environ) > 0:
        envstr = reduce(lambda a, b: a + " " + b, map(lambda x: x + "=" + environ[x], environ.keys()))
    else:
        envstr = ''
    result, output = command(envstr + " " + cmd, cfg["shell_cmd_timeout"])
    
    if result != "TIMEOUT":
        if result != 0:
            return False, "shell command failed (cmd = " + cmd + ")", output
    else:
        return False, "shell command timed out (cmd = " + cmd + ")", output

    return True, None, output


# the shell equivalent of this function is: cd 'hwdir' && make 'target'
# returns the tuple (result, why, details) (see above...)
def build_hw(cfg, hwdir, target, environ):
    if cfg["verbose"]:
        print "make '" + target + "' in '" + hwdir + "'"
    
    try:
        os.chdir(hwdir)
    except OSError:
        return False,"Cannot chdir to directory '" + hwdir + "'", None
    
    # prepend additional environment (see build_sw for elaboration)
    if len(environ) > 0:
        envstr = reduce(lambda a, b: a + " " + b, map(lambda x: x + "=" + environ[x], environ.keys()))
    else:
        envstr = ''
    result, output = command(envstr + " make " + target, cfg["hwbuild_timeout"])
    if result != "TIMEOUT":
        if not result == 0 or xilinx_error(output) :
            return False, "hardware build failed (target = " + target + ")", output
    else:
        print output
        return False, "hardware build timed out (target = " + target + ")", output

    return True, None, output

# Tries to perform all tests in the list 'tests'. Automatically resolves dependencies and gives
# a summary feedback about the test results. Detailed logs for the failed tests are stored in 'results_dir'.
def evaluate_tests(tests, results_dir):
    number = 0
    if sys.stdout.isatty():
            PASSED = "\033[70G\033[0;32mPASSED\033[0m"
            FAILED = "\033[70G\033[0;31mFAILED\033[0m"
    else:
            PASSED = "PASSED"
            FAILED = "FAILED"
    check = True
    while check:
        check = False
        for i in range(len(tests)):
            if tests[i].result != None: continue
            
            skip = False
            for d in tests[i].depends:
                if not d.result == True:
                    skip = True
                    break
                
            if skip:
                #print "*** skipping test '" + tests[i].name + "' for now."
                continue
            
            check = True
            number = number + 1
            
            if tests[i].cfg["verbose"]:
                print "*** performing test %3d of %3d: '%s'" % (i + 1, len(tests), tests[i].name)
            
            else:
                sys.stdout.write("test %3d of %3d ('%s') " % (number, len(tests), tests[i].name))
                sys.stdout.flush()
                
            result = tests[i].perform()
            if result:
                if tests[i].cfg["verbose"]:
                    print ("*** test %3d of %3d ('%s')" + PASSED) % (i + 1, len(tests), tests[i].name)
                else:
                    sys.stdout.write(PASSED + "\n")
                fname = results_dir + "/" + tests[i].name + ".passed"
                fout = open(fname,"w")
                fout.write(str(tests[i].details))
                fout.close()
            else:
                fname = results_dir + "/" + tests[i].name + ".failed"
                fout = open(fname,"w")
                fout.write("test '%s' failed: %s\n" % (tests[i].name,tests[i].why))
                if len(tests[i].details) > 0:
                    fout.write("details follow:\n\n")
                    fout.write(str(tests[i].details))
                fout.close()
                if tests[i].cfg["verbose"]:
                    print ("*** test %3d of %3d ('%s') " +  FAILED) % (i + 1, len(tests), tests[i].name)
                    print "*** reason: %s" % tests[i].why
                    print "*** see file '%s' for details" % fname
                else:
                    sys.stdout.write(FAILED + "\n")
                
    remaining = filter(lambda x: x.result == None, tests)
    failed    = filter(lambda x: x.result == False, tests)
    passed    = filter(lambda x: x.result == True, tests)
    
    print "Tests passed: %d of %d" % (len(passed), len(tests))
    if len(failed) > 0:
        print "Tests failed: %d of %d:" % (len(failed), len(tests))
        for t in failed:
            print t.name
    else:
        print "All tests passed"
    
    if len(remaining) > 0:
        print "Could not do the following tests because of failed dependencies."
        for t in remaining:
            print t.name

# The test class stores all data relevant to performing the test and evaluating the test results.
class Test(object):
    def __init__(self, cfg, name):
        self.cfg = cfg          # configuration dictionary (see create_default_config())
        self.name = name        # name of the test
        self.swdir = None       # software source directory
        self.hwdir = None       # hardware source directory
        self.swtargets = []     # software build targets
        self.hwtargets = []     # hardware build targets
        self.bitfile = None     # location of the bitstream file
        self.elffile = None     # location of the elf file
        self.output = []        # expected program output
        self.shellcmd = None    # shell command to execute
        self_shelldir = None    # dir to execute shell cmd in
        self.result = None      # None: Test not performed yet, True: test passed, False: test failed
        self.why = None         # A short message describing why the test failed (only in case of error)
        self.details = None     # A complete log about the test (only in case of error)
        self.depends = []       # List of test cases this test depends on
        self.skip = False       # Used for bookkeeping, not used in this module
        self.time = None        # time of the beginning of this test
        self.duration = 0       # duration of the test
        self.environ = {}       # additional environment variables to pass to all commands in this test
    
    # Tries to perform all tasks necessery to complete the test
    # 1. if hardware build targets and a hardware source directory are given: try to build the hardware
    # 2. if software build targets and a software source directory are given: try to build the software
    # 3. if a bitfile and an elf-file are given: upload both, execute the program and check the output
        # 4. if a command is given: execute that command and check the return value
    def perform(self):
        if self.result != None:
            return self.result

        self.time = time.asctime()
        seconds = time.time()
            
        for t in self.depends:
            if not t.result:
                self.result = False
                self.why = "Connot perform test because test '" + t.name + "' failed."
                return self.result
        
        if self.hwtargets and self.hwdir:
            if self.cfg["verbose"]:
                print "performing hardware build"
            for t in self.hwtargets:
                self.result, self.why, self.details = build_hw(self.cfg,self.hwdir,t,self.environ)
                if not self.result: return self.result
        
        if self.swtargets and self.swdir:
            if self.cfg["verbose"]:
                print "performing software build"
            for t in self.swtargets:
                self.result, self.why, self.details = build_sw(self.cfg,self.swdir,t,self.hwdir,self.environ)
                if not self.result: return self.result
        
        if self.bitfile and self.elffile:
            if self.cfg["verbose"]:
                print "performing program test"
            self.result, self.why, self.details = download_and_execute(self.cfg,self.bitfile,self.elffile,self.output)
            if not self.result: return self.result

        if self.shellcmd:
            if self.cfg["verbose"]:
                print "executing shell command"
            self.result, self.why, self.details = execute_shell_cmd(self.cfg, self.shellcmd, self.shelldir, self.environ)
            if not self.result: return self.result
        
        if self.result == None:
            print "test '" + self.name + "':"
            print "hwtargets = " + str(self.hwtargets)
            print "swtargets = " + str(self.swtargets)
            print "bitfile   = " + str(self.bitfile)
            print "elffile   = " + str(self.elffile)
            if not self.bitfile and not self.swtargets and not self.swtargets and not self.shellcmd:
                self.result = False
                print "Warning: nothing to do for test '" + self.name + "'"
                print "test result set to 'False'"
        
        self.duration = time.time() - seconds
        
        return self.result

    # Set the expected output of the test program
    def set_output(self,text):
        text = text.strip()
        self.output = text2lines(text)


