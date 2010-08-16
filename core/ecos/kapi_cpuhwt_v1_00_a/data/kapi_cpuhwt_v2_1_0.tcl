#
# \file kapi_cpuhwt_v2_1_0.tcl
#
# \author Robert Meiche
# \date   27.8.2009
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

proc kapi_cpuhwt_drc {lib_handle} {
}

proc generate {lib_handle} {

	set confhdr  [ xopen_include_file "xparameters.h" ]

	set cputype    [ xget_value $lib_handle "PARAMETER" "CPU_TYPE" ]
	
	if {$cputype == "PPC405"} {
	   puts $confhdr "#define CPU_HWT_LIB_PPC405 1"	
		
	}
	
	close $confhdr	
}
