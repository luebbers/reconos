#!/usr/bin/env python
"""
Parser for *.cmddef files (ReconOS command definitions)
"""
#
# \file cmddef.py
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       29.10.2008
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
# \file cmddef.py

import sys, os
from pyparsing import Word, alphas, alphanums, hexnums, nums, OneOrMore, CaselessLiteral, Literal, Keyword, pythonStyleComment, ZeroOrMore, Each, QuotedString, Optional, Combine, Empty


# GRAMMAR DEFINITION =======================================================

# terminal symbols
IDENT          = Word(alphas, alphanums + '_')
INT            = Word(nums)
HEX8           = Combine( CaselessLiteral('0x') + Word(hexnums, exact = 8) )
HEX2           = Combine( CaselessLiteral('0x') + Word(hexnums, exact = 2) )
COMMAND        = Keyword('COMMAND')
SYMBOL         = Keyword('SYMBOL')
ENCODING       = Keyword('ENCODING')
TYPE           = Keyword('TYPE')
OPTIONS        = Keyword('OPTIONS')
DELEGATE       = Keyword('DELEGATE')
HOST_OS        = Keyword('HOST_OS')
RESTYPE        = Keyword('RESTYPE')
HEADER         = Keyword('HEADER')
END            = Keyword('END')
CODE           = Keyword('CODE')
IFDEF          = Keyword('IFDEF')
COPY_HEADERS   = Keyword('COPY_HEADERS')
COPY_CODE      = Keyword('COPY_CODE')
LT             = Literal('<')
GT             = Literal('>')
QUOTE          = Literal('"')

cmdtype        = Keyword('TASK2OS')  # that's all we support for now
option         = ( Keyword('BLOCKING') ^ Keyword('RETVAL') ^ Keyword('HW_ONLY') )
options        = OneOrMore( option )
header_ldelim  = ( LT ^ QUOTE )
header_rdelim  = ( GT ^ QUOTE )
header         = Combine( header_ldelim + Word( alphanums + '_' + '/' + '.' ) + header_rdelim )
quoted_code    = QuotedString('"') ^ QuotedString("'")
multiline_code = QuotedString("'''", multiline = True)
code           = ( quoted_code ^ multiline_code )

# clauses
command_clause      = COMMAND      + IDENT('command_name')
delegate_clause     = DELEGATE     + IDENT('delegate_name')
symbol_clause       = SYMBOL       + IDENT('symbol')
encoding_clause     = ENCODING     + HEX2('encoding')
type_clause         = TYPE         + cmdtype('type')
options_clause      = OPTIONS      + options('options')
host_os_clause      = HOST_OS      + IDENT('host_os')
restype_clause      = RESTYPE      + IDENT('restype')
ifdef_clause        = IFDEF        + IDENT('ifdef')
header_clause       = HEADER       + header('header')
code_clause         = CODE         + code('code')

# not yet implemented
#copy_code_clause    = COPY_CODE    + IDENT('copy_code')
#copy_headers_clause = COPY_HEADERS + IDENT('copy_headers')

# blocks
delegate_block = delegate_clause + (
        host_os_clause &
        ZeroOrMore( header_clause ) &
        Optional( ifdef_clause ) &
        Optional( restype_clause ) &
        code_clause 
    ) + END
command_block = command_clause + (
        symbol_clause &
        encoding_clause &
        type_clause &
        Optional( options_clause )
    ) + ZeroOrMore( delegate_block ).setResultsName('delegates') + END

# root node
cmddef_file = OneOrMore( command_block )


# CLASS DEFINITIONS ========================================================

# -----------------------------------------
# Command class
# -----------------------------------------
class Command(object):
    '''Represents a ReconOS command'''

    name      = None
    symbol    = None
    encoding  = None
    type      = None
    options   = None
    filename  = None
    delegates = None

    def __init__(self, toks):
        '''Constructs a Command object from a token dictionary.'''
        self.name      = toks.command_name
        self.symbol    = toks.symbol
        self.encoding  = toks.encoding
        self.type      = toks.type
        if toks.options:
            self.options   = toks.options.asList()
        self.delegates = toks.delegates
        # connect all delegates to their command
        for d in self.delegates:
            d.command = self

    def __str__(self):
        '''Prints a command block as it would appear in a *.cmddef file'''
        if self.options:
            s = '''
    COMMAND %s
        SYMBOL      %s
        ENCODING    %s
        TYPE        %s
        OPTIONS     %s

    ''' % (self.name, self.symbol, self.encoding, self.type, reduce(lambda x, y: str(x) + ' ' + str(y), self.options))
        else:
            s = '''
    COMMAND %s
        SYMBOL      %s
        ENCODING    %s
        TYPE        %s

    ''' % (self.name, self.symbol, self.encoding, self.type)
        for d in self.delegates:
            s += str(d) + '\n'
        s += 'END # ' + self.name + '\n'
        return s

# -----------------------------------------
# Delegate class
# -----------------------------------------
class Delegate(object):
    '''Represents a snippet of code for the delegate thread'''

    name     = None
    hostOs   = None
    restype  = None
    headers  = None
    ifdefs   = None
    code     = None
    copyCode = None
    command  = None

    def __init__(self, toks):
        '''Constructs a Delegate object from a token dictionary.'''
        self.name        = toks.delegate_name
        self.hostOs      = toks.host_os
        self.restype     = toks.restype
        self.headers     = toks.header
        self.copyHeaders = toks.copy_headers
        self.ifdef       = toks.ifdef
        self.code        = toks.code
        self.copyCode    = toks.copy_code
        self.command     = None

    def __str__(self):
        '''Prints a delegate block as it would appear in a *.cmddef file'''
        s = '''
    DELEGATE %s
        HOST_OS             %s
        RESTYPE             %s
''' % (self.name, self.hostOs, self.restype)
        if self.headers:
            for h in self.headers:
                s += '        HEADER              ' + str(h) + '\n'
        else:
            s += '        COPY_HEADERS        ' + self.copyHeaders + '\n'
        if self.ifdef:
            s += '        IFDEF               ' + self.ifdef + '\n'
        if self.code:
            s += "        CODE '''" + self.code + "'''\n"
        else:
            s += '        COPY_CODE           ' + self.copyCode + '\n'
        s += '    END # ' + self.name + '\n'
        return s


# FUNCTION DEFINITIONS =====================================================

# actions ------------------------------------------------------------------

def on_command(s, loc, toks):
    c = Command(toks)
    return c

def on_delegate(s, loc, toks):
    d = Delegate(toks)
    return d


# library functions --------------------------------------------------------

def parse_file(filename):
    '''Parse a *.cmddef file. Returns a list with all commands parsed into
    cmddef.Command objects.'''

    fin = open(filename)
    s = fin.read()
    cmddef_file.ignore(pythonStyleComment)
    command_block.setParseAction(on_command)
    delegate_block.setParseAction(on_delegate)
    objs = cmddef_file.parseString(s)
    for c in objs:
        if type(c) == Command:
            c.filename = os.path.basename(filename)
    return objs


def parse_files(filelist):
    '''Pasrse all files given as a list. Returns a list with all commands
    parsed into cmddef.Command objects.'''

    if not filelist:
        return None

    mylist = []
    for f in filelist:
        objs = parse_file(f)
        if objs:
            mylist += objs

    return mylist



if __name__ == '__main__':
    for o in parse_file(sys.argv[1]):
        print o

