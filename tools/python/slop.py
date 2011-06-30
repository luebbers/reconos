#!/usr/bin/env python
#
# \file slop.py
#
# Simplified parsing of command line options.
#
# Inspired by the ruby option parser "Slop" by Lee Jarvis
# (http://lee.jarvis.co/slop).
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       30.06.2011
#
#---------------------------------------------------------------------------
# %%%RECONOS_COPYRIGHT_BEGIN%%%
# 
# This file is part of ReconOS (http://www.reconos.de).
# Copyright (c) 2006-2011 The ReconOS Project and contributors (see AUTHORS).
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
# Uses optparse to keep Python 2.4 compatibility
#

import sys, os, optparse

class Options:

    optDict = {}

    def _initOpt(self, name, letter, description, argRequired, optional, default = None, as = "string"):
        self.optDict[name] = { "letter" : letter,
                          "description" : description,
                          "argRequired" : argRequired,
                          "optional"    : optional,
                          "present"     : False,
                          "as"          : as,
                          "value"       : default}

    def __init__(self, optDef, banner=None):
        self.parser = optparse.OptionParser(usage=banner)
        # optDef entry: (letter, name, description, [argRequired,] [options dictionary] )
        for d in optDef:
            assert len(d) < 6
            letter, name, description = d[0:3]
            default = None
            as = "string"
            if letter != None:
                letterStr = "-" + letter
            else:
                letterStr = None
            if name != None:
                nameStr = "--" + name
            else:
                nameStr = None
                name = letter
            argRequired = False
            optional = True
            if len(d) > 3:
                for x in d[3:]:
                    if type(x).__name__ == "bool":
                        argRequired = x
                    elif type(x).__name__ == "dict":
                        if "optional" in x.keys():
                            optional = x["optional"]
                            if not optional:        # non-optional arguments always need a value
                                argRequired = True
                        if "default" in x.keys():
                            default = x["default"]
                        if "as" in x.keys():
                            as = x["as"]
            # add option to internal optDict
            self._initOpt(name, letter, description, argRequired, optional,
                    default, as)
            # add options to parser
            if argRequired:
                if as in ("array", "list"):
                    action = "append"
                else:
                    action = "store"
            else:
                action = "store_true"
                default = False
            assert (letterStr != None) or (nameStr != None), "Letter and name cannot both be 'None'!"
            if letterStr == None:
                self.parser.add_option( nameStr,
                                        action=action, dest=name,
                                        help=description)
            elif nameStr == None:
                self.parser.add_option( letterStr,
                                        action=action, dest=name,
                                        help=description)

            else:
                self.parser.add_option( letterStr,
                                        nameStr,
                                        action=action, dest=name,
                                        help=description)


    def __getitem__(self, key):
        if key in self.optDict.keys():
            return self.optDict[key]["value"]
        else:
            raise IndexError

    def __contains__(self, item):
        if item in self.optDict.keys():
            return self.optDict[name]["present"]
        return False

    def __getattr__(self, name):
        if name in self.optDict.keys():
            return self.optDict[name]["present"]
        else:
            raise AttributeError

    def parse(self, args=sys.argv[1:]):
        # parse args with optparse
        (options, args) = self.parser.parse_args(args=args)

        # transfer values into parsedOpts
        for o in self.optDict:
            if options.__dict__[o] != None:
                self.optDict[o]["value"] = getattr(options, o)
                self.optDict[o]["present"] = True

        # check for missing 'non-optional' arguments
        for o in self.optDict:
            if not self.optDict[o]["optional"] and not self.optDict[o]["present"]:
                print >> sys.stderr, os.path.basename(sys.argv[0]) + ": error: non-optional argument '" + o + "' is missing."
                sys.exit(2)

        return args

    def help(self):
        self.parser.print_help()
        
                               
        
def parse(optDef, args=sys.argv[1:], banner=None):

    # catch invalid input
    assert optDef != None

    # create Options instance and populate it with the options
    parsedOpts = Options(optDef, banner = banner)

    args = parsedOpts.parse(args=args)

    return parsedOpts, args


if __name__ == "__main__":

    opts = parse([
        ("v", "verbose", "Enable verbose mode"),            # boolean value
        ("n", "name", "Your name", True),                   # option requires a compulsory argument
        ("s", "sex", "Your sex", {"optional" : False}),     # the same thing
        ("a", "age", "Your age", {"optional" : True}),      # optional argument
        ("q", None, "be quiet", True),
        (None, "quiet", "be extra quiet")
        ])

    # if sys.argv[1:] is '-v --name "lee jarvis" -s male'
    print opts.verbose    # True
    print opts.name       # True
    print opts["name"]    # "lee jarvis"
    print opts.age        # False
    print opts["age"]     # None

    # alternative syntax
    #"verbose" in opts   # True
    #"name" in opts      # True
    #"age" in opts       # False
