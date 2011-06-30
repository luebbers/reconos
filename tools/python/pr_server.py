#!/usr/bin/env python
#
# \file pr_server.py
#
# Server for external partial reconfiguration (ECAP)
#
# This program waits for an incoming TCP-IP connections and performs
# JTAG loads of (possibly partial) bitstreams via JTAG.
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       16.06.2009
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

import socket, sys, subprocess, slop
import atexit, signal

### GLOBAL VARIABLES ###
conn = None
s = None

#
# usage(): print usage
#
def usage():
	print "USAGE:", os.path.basename(sys.argv[0]), "[-p port] [-c JTAG chain position]"


#
# cleanup(): cleans up on termination
#
def cleanup():
    global conn, s

    print "cleaning up..."
    if conn:
        conn.close()
    if s:
        s.close()


### MAIN PROGRAM ###

# set cleanup handler
atexit.register(cleanup)

# exit normally when killed, thanks to
# http://code.activestate.com/recipes/533117/
signal.signal(signal.SIGTERM, lambda signum, stack_frame: sys.exit(1))


# parse command line arguments
opts, args = slop.parse([
    ("p", "port", "port to listen on (default: 42424)", True, {"default" :
        42424}),
    ("c", "chainpos", "JTAG chain position (default: 2)", True, {"default" :
        2})])

port = int(opts["port"])
chainpos = int(opts["chainpos"])
	
print "using JTAG chain position", chainpos

# create socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# allow address reuse (thanks to peter@engcorp.com on python-list)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

# associate with port
host = ''
s.bind((host, port))

# accept incoming connection
data = ''

try:    # catch Keyboard interrupts from here
    s.listen(1)
    while True:
            print 'listening on port', port
            conn, addr = s.accept()
            print 'incoming connection from', addr

            while True:
                    # receive bitstream name
                    data = conn.recv(1024)	# 1024 should be short enough
                    if not data:
                            conn.close()
                            break
                    print 'received:', data
                    if data.strip().lower() == 'quit':
                            conn.send("Server quitting. Byebye.\n")
                            sys.exit(0)
                    if data.strip().lower() == 'exit':
                            conn.send("Closing connection. See you later.\n")
                            conn.close()
                            break
                    print 'executing:', "dow", data.strip(), str(chainpos)
                    output = subprocess.Popen(["dow", data.strip(), str(chainpos)], stdout=subprocess.PIPE).communicate()[0]
                    print output
                    conn.send("OK\n")
except KeyboardInterrupt:
    sys.exit(3)
