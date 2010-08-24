##=============================================================================
##
##      context.S
##
##      MicroBlaze context switch code
##
##=============================================================================
#####ECOSGPLCOPYRIGHTBEGIN####
## -------------------------------------------
## This file is part of eCos, the Embedded Configurable Operating System.
## Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
##
## eCos is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 or (at your option) any later version.
##
## eCos is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with eCos; if not, write to the Free Software Foundation, Inc.,
## 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
##
## As a special exception, if other files instantiate templates or use macros
## or inline functions from this file, or you compile this file and link it
## with other works to produce a work based on this file, this file does not
## by itself cause the resulting work to be covered by the GNU General Public
## License. However the source code for this file must still be made available
## in accordance with section (3) of the GNU General Public License.
##
## This exception does not invalidate any other reasons why a work based on
## this file might be covered by the GNU General Public License.
##
## Alternative licenses for eCos may be arranged by contacting Red Hat, Inc.
## at http://sources.redhat.com/ecos/ecos-license/
## -------------------------------------------
#####ECOSGPLCOPYRIGHTEND####
##=============================================================================
#######DESCRIPTIONBEGIN####
##
## Author(s):      Michal Pfeifer
## Original data:  PowerPC
## Contributors: 
## Date:        1998-04-27
## Purpose:     MicroBlaze context switch code
## Description: This file contains implementations of the thread context 
##              switch routines. It also contains the longjmp() and setjmp()
##              routines.
##
######DESCRIPTIONEND####
##
##=============================================================================

#include <pkgconf/hal.h>
#include <cyg/hal/arch.inc>
#include <cyg/hal/mb_offsets.inc>

#------------------------------------------------------------------------------
# hal_thread_switch_context
# Switch thread contexts
# R5 = address of sp of next thread to execute
# R6 = address of sp save location of current thread


FUNC_START(hal_thread_switch_context)
	add	r4, r0, r1				# R4 = saved stack pointer
	addi	r1, r1, -CYGARC_MB_CONTEXT_SIZE		# space for state

	swi	r3, r1, (CYGARC_MBREG_REGS+(3-1)*4)	# R3
	swi	r7, r1, (CYGARC_MBREG_REGS+(7-1)*4)
	swi	r8, r1, (CYGARC_MBREG_REGS+(8-1)*4)
	swi	r9, r1, (CYGARC_MBREG_REGS+(9-1)*4)
	swi	r10, r1, (CYGARC_MBREG_REGS+(10-1)*4)
	swi	r11, r1, (CYGARC_MBREG_REGS+(11-1)*4)
	swi	r12, r1, (CYGARC_MBREG_REGS+(12-1)*4)
	swi	r13, r1, (CYGARC_MBREG_REGS+(13-1)*4)
	swi	r14, r1, (CYGARC_MBREG_REGS+(14-1)*4)
	swi	r15, r1, (CYGARC_MBREG_REGS+(15-1)*4)
	swi	r16, r1, (CYGARC_MBREG_REGS+(16-1)*4)
	swi	r17, r1, (CYGARC_MBREG_REGS+(17-1)*4)
	swi	r18, r1, (CYGARC_MBREG_REGS+(18-1)*4)
	swi	r19, r1, (CYGARC_MBREG_REGS+(19-1)*4)
	swi	r20, r1, (CYGARC_MBREG_REGS+(20-1)*4)
	swi	r21, r1, (CYGARC_MBREG_REGS+(21-1)*4)
	swi	r22, r1, (CYGARC_MBREG_REGS+(22-1)*4)
	swi	r23, r1, (CYGARC_MBREG_REGS+(23-1)*4)
	swi	r24, r1, (CYGARC_MBREG_REGS+(24-1)*4)
	swi	r25, r1, (CYGARC_MBREG_REGS+(25-1)*4)
	swi	r26, r1, (CYGARC_MBREG_REGS+(26-1)*4)
	swi	r27, r1, (CYGARC_MBREG_REGS+(27-1)*4)
	swi	r28, r1, (CYGARC_MBREG_REGS+(28-1)*4)
	swi	r29, r1, (CYGARC_MBREG_REGS+(29-1)*4)
	swi	r30, r1, (CYGARC_MBREG_REGS+(30-1)*4)
	swi	r31, r1, (CYGARC_MBREG_REGS+(31-1)*4)

	swi	r4, r1, (CYGARC_MBREG_REGS+(1-1)*4)	# R4 = real SP, save in R1 slot
	swi	r2, r1, (CYGARC_MBREG_REGS+(2-1)*4)	# R2 = TOC

#ifdef CYGDBG_HAL_DEBUG_GDB_THREAD_SUPPORT
	# Make the thread context look like an exception context if thread-
	# aware debugging is required. This state does not need restoring.
	swi	r15, r1, CYGARC_MBREG_PC # pc of caller
#endif
		
	mfs	r4, rmsr
	swi	r4, r1, CYGARC_MBREG_MSR # msr

	##save_special			# save special regs
	swi	r1, r6, 0		# save SP into save location

	# Now load the destination thread by dropping through
	# to hal_thread_load_context

#------------------------------------------------------------------------------
# hal_thread_load_context
# Load thread context
# R5 = address of sp of next thread to execute
# Note that this function is also the second half of hal_thread_switch_context
# and is simply dropped into from it.

FUNC_START(hal_thread_load_context)
        lwi     r1, r5, 0                # load state directly into SP
	##load_special                    # load special registers
	lwi	r3, r1, CYGARC_MBREG_REGS+(3-1)*4
	lwi	r7, r1, (CYGARC_MBREG_REGS+(7-1)*4)
	lwi	r8, r1, (CYGARC_MBREG_REGS+(8-1)*4)
	lwi	r9, r1, (CYGARC_MBREG_REGS+(9-1)*4)
	lwi	r10, r1, (CYGARC_MBREG_REGS+(10-1)*4)
	lwi	r11, r1, (CYGARC_MBREG_REGS+(11-1)*4)
	lwi	r12, r1, (CYGARC_MBREG_REGS+(12-1)*4)
	lwi	r13, r1, (CYGARC_MBREG_REGS+(13-1)*4)
	lwi	r14, r1, (CYGARC_MBREG_REGS+(14-1)*4)
	lwi	r15, r1, (CYGARC_MBREG_REGS+(15-1)*4)
	lwi	r16, r1, (CYGARC_MBREG_REGS+(16-1)*4)
	lwi	r17, r1, (CYGARC_MBREG_REGS+(17-1)*4)
	lwi	r18, r1, (CYGARC_MBREG_REGS+(18-1)*4)
	lwi	r19, r1, (CYGARC_MBREG_REGS+(19-1)*4)
	lwi	r20, r1, (CYGARC_MBREG_REGS+(20-1)*4)
	lwi	r21, r1, (CYGARC_MBREG_REGS+(21-1)*4)
	lwi	r22, r1, (CYGARC_MBREG_REGS+(22-1)*4)
	lwi	r23, r1, (CYGARC_MBREG_REGS+(23-1)*4)
	lwi	r24, r1, (CYGARC_MBREG_REGS+(24-1)*4)
	lwi	r25, r1, (CYGARC_MBREG_REGS+(25-1)*4)
	lwi	r26, r1, (CYGARC_MBREG_REGS+(26-1)*4)
	lwi	r27, r1, (CYGARC_MBREG_REGS+(27-1)*4)
	lwi	r28, r1, (CYGARC_MBREG_REGS+(28-1)*4)
	lwi	r29, r1, (CYGARC_MBREG_REGS+(29-1)*4)
	lwi	r30, r1, (CYGARC_MBREG_REGS+(30-1)*4)
	lwi	r31, r1, (CYGARC_MBREG_REGS+(31-1)*4)

	lwi     r5, r1, CYGARC_MBREG_MSR       # merge interrupt state
	hal_cpu_int_merge r5

	lwi     r2, r1, CYGARC_MBREG_REGS+(2-1)*4  # R2 = TOC

	lwi     r5, r1, CYGARC_MBREG_REGS+(5-1)*4  # load r5

	lwi     r1, r1, CYGARC_MBREG_REGS+(1-1)*4  # finally restore true SP

	rtsd	r15, 8                             # jump to LR
	nop

#------------------------------------------------------------------------------
# HAL longjmp, setjmp implementations
# hal_setjmp saves only to callee save registers 13-31, r1[sp],r2, cr[2-4]
# and lr into buffer supplied in r3[arg0]

FUNC_START(hal_setjmp)
	swi	r31, r5, CYGARC_JMPBUF_R31
	swi	r30, r5, CYGARC_JMPBUF_R30
	swi	r29, r5, CYGARC_JMPBUF_R29
	swi	r28, r5, CYGARC_JMPBUF_R28
	swi	r27, r5, CYGARC_JMPBUF_R27
	swi	r26, r5, CYGARC_JMPBUF_R26
	swi	r25, r5, CYGARC_JMPBUF_R25
	swi	r24, r5, CYGARC_JMPBUF_R24
	swi	r23, r5, CYGARC_JMPBUF_R23
	swi	r22, r5, CYGARC_JMPBUF_R22
	swi	r21, r5, CYGARC_JMPBUF_R21
	swi	r20, r5, CYGARC_JMPBUF_R20
	swi	r19, r5, CYGARC_JMPBUF_R19
	swi	r18, r5, CYGARC_JMPBUF_R18
	swi	r17, r5, CYGARC_JMPBUF_R17
	swi	r16, r5, CYGARC_JMPBUF_R16
	swi	r15, r5, CYGARC_JMPBUF_R15
	swi	r14, r5, CYGARC_JMPBUF_R14
	swi	r13, r5, CYGARC_JMPBUF_R13
	swi	r2,  r5, CYGARC_JMPBUF_R2	# TOC, optimize out?
	swi	r1,  r5, CYGARC_JMPBUF_SP
	xor	r3, r3, r3			# return 0
	rtsd	r15, 8
	nop
	
# hal_longjmp loads state from r3[arg0] and returns
# to the setjmp caller with r4[arg1] as return value 

FUNC_START(hal_longjmp)
	lwi	r31, r5, CYGARC_JMPBUF_R31
	lwi	r30, r5, CYGARC_JMPBUF_R30
	lwi	r29, r5, CYGARC_JMPBUF_R29
	lwi	r28, r5, CYGARC_JMPBUF_R28
	lwi	r27, r5, CYGARC_JMPBUF_R27
	lwi	r26, r5, CYGARC_JMPBUF_R26
	lwi	r25, r5, CYGARC_JMPBUF_R25
	lwi	r24, r5, CYGARC_JMPBUF_R24
	lwi	r23, r5, CYGARC_JMPBUF_R23
	lwi	r22, r5, CYGARC_JMPBUF_R22
	lwi	r21, r5, CYGARC_JMPBUF_R21
	lwi	r20, r5, CYGARC_JMPBUF_R20
	lwi	r19, r5, CYGARC_JMPBUF_R19
	lwi	r18, r5, CYGARC_JMPBUF_R18
	lwi	r17, r5, CYGARC_JMPBUF_R17
	lwi	r16, r5, CYGARC_JMPBUF_R16
	lwi	r15, r5, CYGARC_JMPBUF_R15
	lwi	r14, r5, CYGARC_JMPBUF_R14
	lwi	r13, r5, CYGARC_JMPBUF_R13
	lwi	r2,  r5, CYGARC_JMPBUF_R2
	lwi	r1,  r5, CYGARC_JMPBUF_SP
	or	r3, r6, r6			# return r6[arg1]
	rtsd	r15, 8
	nop

#------------------------------------------------------------------------------
# end of context.S
