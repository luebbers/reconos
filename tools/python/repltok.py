#!/usr/bin/env python
#
# \file repltok.py
#
# Replaces tokens with text.
#
# Usually, a token is some placeholder text inside a text file, e.g.
# %%%THIS_IS_A_TEST%%%. This script can replace this token with specified text
# from the command line or from a text file. Optionally, it can also replace
# text BETWEEN two tokens, leaving the tokens intact. This can be useful to
# *change* text within text files, e.g. a test bench, or the license
# specification in text file headers (such as this one). 
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       27.10.2008
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

import sys, os
import re
import slop

def replace_token_with_text( lines, pattern, text ):
    '''In "lines", replace the token "pattern" with the text "text". Returns
    the output text.'''
    exp = re.compile( pattern )
    return [ exp.sub( text, l ) for l in lines ]


def replace_between_with_text( lines, start_pattern, end_pattern, text,
        with_prefix, keep_tokens ):
    '''In "lines", replace the text between "start_pattern" and "end_pattern"
    with "text".  Returns the output text.'''
    retval = []
    found = 0
    expstart = re.compile( '(^.*)' + start_pattern )
    expend = re.compile( '^.*' + end_pattern )
    for l in lines:
        if not found:
            m = expstart.match( l )
            if m:
                if keep_tokens:
                    retval.append( l )  # retain the start token in the output
                found = True
                prefix = m.group(1)
                if with_prefix:
                    # prepend prefix to every line in 'text'
                    textlist = [ prefix + x for x in text.splitlines( True ) ]
                else:
                    textlist = text.splitlines( True )
                # add text to the output
                retval = retval + textlist
            else:
                retval.append( l )      # retain the source line in the output
        else:       # found
            m = expend.match( l )
            if m:
                found = False
                if keep_tokens:
                    retval.append( l )  # retain the end token in the output

    return retval


#-----------------------------------------------------------------------------
# main program
#-----------------------------------------------------------------------------

if __name__ == '__main__':

    # parse options
    mode = None

    optlist, rem_args = slop.parse([
        ("i", "infile", "input file (stdin if not specified)", True),
        ("o", "outfile", "output file (stdout if not specified). "
                         "'infile' and 'outfile' can be the same.", True),
        ("t", "token", "token to replace (token will vanish)", True),
        ("s", "start", "replace between this and end token"
            "(tokens may remain in output with -k)", True),
        ("e", "end", "replace between start token and this"
            "(tokens may remain in output with -k)", True),
        ("r", "text", "text to replace tokens with", True),
        ("f", "file", "file to replace tokens with. "
            "If neither text nor file are specified, replacement text "
            "is read from stdin.", True),
        ("k", "keep", "keep 'start' and 'end' tokens in output"),
        ("P", "prefix", "when replacing between 'start' and 'end' tokens, "
            "do not retain the prefix in the line before 'start'. "
            "This is useful for C-style commented start/end tokens. "
            "Ignored when using '-t'."),
        ], banner="%prog [options] <-t token | -s start -e end> ")

    infilename = optlist["infile"]
    outfilename = optlist["outfile"]
    keep_tokens = optlist["keep"]
    with_prefix = not optlist["prefix"]
    textfilename = optlist["file"]
    text = optlist["text"]
    start_token = optlist["start"]
    end_token = optlist["end"]
    token = optlist["token"]
    if optlist.start:
        mode = "between"
    if optlist.end:
        mode = "between"
    if optlist.token:
        mode = "token"

    # check options for plausability
    if ( 
         ( not mode ) or 
         ( mode == "between" and ( token or not start_token or not end_token ) ) or
         ( mode == "token" and ( start_token or end_token ) ) or
         ( text and textfilename ) or
         ( not infilename and ( not text and not textfilename ) ) 
       ):
           optlist.help()
           sys.exit( 2 )

    try:
        # read input files
        if infilename:
            infilename = os.path.abspath( infilename )
            infile = open( infilename )
        else:
            infile = sys.stdin

        inlines = infile.readlines()
        if infilename:
            infile.close()


        # read replacement text from file or stdin, if necessary
        if not text:
            if not textfilename:
                textfile = sys.stdin
            else:
                textfilename = os.path.abspath( textfilename )
                textfile = open( textfilename )

            text = textfile.read()
            if textfilename: 
                textfile.close()
    except IOError, e: 
        print >>sys.stderr, str(e)
        sys.exit(1)

    if mode == "token":
        outlines = replace_token_with_text( inlines, token, text )
    elif mode == "between":
        outlines = replace_between_with_text( inlines, start_token,
                end_token, text, with_prefix, keep_tokens )

    try:
        # write output
        if outfilename:
            outfilename = os.path.abspath( outfilename )
            outfile = open( outfilename, mode = 'w' )
            if not outfile:
                print >>sys.stderr, 'could not open output file'
                sys.exit(1)
        else:
            outfile = sys.stdout

        for l in outlines:
            outfile.write(l)
        if outfilename:
            outfile.close()
    except IOError, e:
        print >>sys.stderr, str(e)
        sys.exit(1)

