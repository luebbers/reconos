///
/// \file debug.h
///
/// Debugging macros
/// 
/// Part of the ReconOS netimage tools to send and receive image
/// data to and from a ReconOS board. 
/// 
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       12.09.2007
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//

#ifndef __DEBUG_H__
#define __DEBUG_H__

// CONSTANTS ===============================================================

// Debug levels
#define DEBUG_NONE	  0 	///< no debugging output
#define DEBUG_NOTE	  1		///< important messages
#define DEBUG_INFO	  2		///< informational messages
#define DEBUG_TRACE	  4		///< trace information
#define DEBUG_ALL	  7		///< all debugging messages

#ifndef DEBUG
#define DEBUG DEBUG_NONE    ///< no debug is the default
#endif

/// prefix for debugging messages
#define DEBUG_PREFIX ":: "

// Macros
#if DEBUG > 0

/// standard printf
#define _PRINTF printf

/// print a debug message with level
#define DEBUG_PRINT(l, x)\
			if (DEBUG & l) _PRINTF(DEBUG_PREFIX __FILE__ ":%d: " x "\n", __LINE__);

// FIXME: we don't need an argument (see assert.h)
/// print an entry message 
#define DEBUG_ENTRY(x)\
			if (DEBUG & DEBUG_TRACE)\
            	_PRINTF(DEBUG_PREFIX __FILE__ ":%d: entering " x "\n", __LINE__);

// FIXME: we don't need an argument (see assert.h)
/// print an exit message
#define DEBUG_EXIT(x)\
			if (DEBUG & DEBUG_TRACE)\
            	_PRINTF(DEBUG_PREFIX __FILE__ ":%d: exiting " x "\n", __LINE__);


#else
#define DEBUG_PRINT(l, x)  ///< no debug, no messages
#define DEBUG_ENTRY(x) ///< no debug, no entry message
#define DEBUG_EXIT(x)  ///< no debug, no exit message
#endif

#endif
