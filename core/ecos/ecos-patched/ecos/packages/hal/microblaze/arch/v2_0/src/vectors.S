##==========================================================================
##
##      vectors.S
##
##      MicroBlaze exception vectors
##
##==========================================================================
#####ECOSGPLCOPYRIGHTBEGIN####
## -------------------------------------------
## This file is part of eCos, the Embedded Configurable Operating System.
## Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
## Copyright (C) 2002 Gary Thomas
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
##==========================================================================
#######DESCRIPTIONBEGIN####
##
## Author(s):      Michal Pfeifer
## Original data:  PowerPC
## Contributors: 
## Date:         1999-02-20
## Purpose:      MicroBlaze exception vectors
## Description:  This file defines the code placed into the exception
##               vectors. It also contains the first level default VSRs
##               that save and restore state for both exceptions and
##               interrupts.
##
######DESCRIPTIONEND####
##
##==========================================================================

#===========================================================================
#
#       The MicroBlaze exception handling has changed as of version 1.3.1.
#       The primary motivation for rewriting the code was to bring it more
#       in line with the other HALs, in particular to allow a RAM application
#       to cleanly take over only a subset of vectors from a running ROM
#	monitor.
#
#       GDB stubs (and CygMon, should it be ported to PPC) copies
#       exception vector entry handler code to address 0. These vector entry
#       handlers (defined by the exception_vector macro below) compute
#       a vector index into the hal_vsr_table, fetch the pointer, and
#       jump to the HAL vector service routine (VSR).
#
#       The hal_vsr_table is located immediately after the vector
#       handlers (at address 0x3000), allowing RAM applications to
#       change VSRs as necessary, while still keeping desired ROM
#       monitor functionality available for debugging.
#
#       ROM applications can still be configured to leave the vector entry
#       handlers at 0xff000000, but there is at the moment no
#       provision for reclaiming the reserved vector space in RAM to
#       application usage.
#
#       RAM applications can also be configured to provide exception
#       handlers which are copied to address 0 on startup, thus taking
#       full control of the target.
#
#
#       Default configuration is for RAM applications to rely on an
#       existing ROM monitor to provide debugging functionality, and
#       for ROM applications to copy vectors to address 0.
#
#
#       Unfortunately the new exception scheme is not compatible with the
#       old scheme. Stubs and applications must be compiled using the same
#       scheme (i.e., old binaries will not run with new stubs, and new
#       binaries will not run with old stubs).
#
#===========================================================================

#include <pkgconf/hal.h>

#ifdef CYGPKG_KERNEL
#include <pkgconf/kernel.h>     // CYGPKG_KERNEL_INSTRUMENT
#endif

#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
#include <cyg/hal/mb_regs.h>
#include <xparameters.h>

#include <cyg/hal/arch.inc>


#===========================================================================

//        .file   "vectors.S"

        .extern hal_interrupt_data
        .extern hal_interrupt_handlers
        .extern hal_interrupt_objects
        .extern hal_vsr_table

        .extern cyg_hal_invoke_constructors
        .extern cyg_instrument
        .extern cyg_start
        .extern hal_IRQ_init
//        .extern hal_MMU_init
        .extern hal_enable_caches
        .extern hal_hardware_init
        .extern initialize_stub

        .extern __bss_start
        .extern __bss_end
        .extern __sbss_start
        .extern __sbss_end

#===========================================================================
# MSR initialization value

#define CYG_MSR 0

# Include variant macros after MSR definition.
#include <cyg/hal/arch.inc>
#include <cyg/hal/mb_offsets.inc>


#===========================================================================
# Start by defining the exceptions vectors that must be placed at
# location 0x00000000.

        .section ".vectors","ax"

#---------------------------------------------------------------------------
# Macros for generating an VSRs service routine

# Generic vector macros


rom_vectors:
	.global	__vcr_vector_reset
__vcr_vector_reset:
		brai		_start

#	.p2align 3
	.global	__vcr_vector_user_exception
__vcr_vector_user_exception:
		bri		__call_vcr_user_exception
		nop
#	.p2align 3

	.global	__vcr_vector_interrupt
__vcr_vector_interrupt:
		bri		__call_vcr_interrupt
		nop
#	.p2align 3

	.global	__vcr_vector_break
__vcr_vector_break:
		bri		__call_vcr_break
		nop
#	.p2align 3

	.global	__vcr_vector_hw_exception
__vcr_vector_hw_exception:
		bri		__call_vcr_hw_exception
		nop
#	.p2align 3
	.global	__vcr_vector_reserved_a
__vcr_vector_reserved_a:
		bri		__call_vcr_reserved_a
		nop
#	.p2align 3
	.global	__vcr_vector_reserved_b
__vcr_vector_reserved_b:
		bri		__call_vcr_reserved_b
		nop
#	.p2align 3
	.global	__vcr_vector_reserved_c
__vcr_vector_reserved_c:
		bri		__call_vcr_reserved_c
		nop
#	.p2align 3
	.global	__vcr_vector_reserved_d
__vcr_vector_reserved_d:
		bri		__call_vcr_reserved_d
		nop
#	.p2align 3
	.global	__vcr_vector_reserved_e
__vcr_vector_reserved_e:
		bri		__call_vcr_reserved_e
		nop

# Variants may define extra vectors.
        hal_extra_vectors


rom_vectors_end:




#		.macro	vcr_vector name addr
#		.p2align 3
#		.global	__vcr_vector_\name
#__vcr_vector_\name:
#			bri		\addr
#		.endm

        .macro  call_vector index
			swi		r3, r1, -4
			addi	r3, r0, \index
			swi		r3, r1, -8
			swi		r1, r1, -12
			addi	r1, r1, (-1 * 3 * 4)
			addi	r3, r0, hal_vsr_table
			lwi		r3, r3, \index * 4
			bra		r3
		.endm
        
#---------------------------------------------------------------------------
# Define the exception vectors.

// Some platforms won't let us put the vector code just where we want
// This macro introduces some lattitude in vector placement

        .global  __call_vcr_user_exception
__call_vcr_user_exception:
		call_vector		1
        .global  __call_vcr_interrupt
__call_vcr_interrupt:
		call_vector		2
        .global  __call_vcr_break
__call_vcr_break:
		call_vector		3
        .global  __call_vcr_hw_exception
__call_vcr_hw_exception:
		call_vector		4
        .global  __call_vcr_reserved_a
__call_vcr_reserved_a:
		call_vector		5
        .global  __call_vcr_reserved_b
__call_vcr_reserved_b:
		call_vector		6
        .global  __call_vcr_reserved_c
__call_vcr_reserved_c:
		call_vector		7
        .global  __call_vcr_reserved_d
__call_vcr_reserved_d:
		call_vector		8
        .global  __call_vcr_reserved_e
__call_vcr_reserved_e:
		call_vector		9

        # Variants may define extra vectors.		
		hal_call_extra_vectors
		
#rom_vectors:
        # These are the architecture defined vectors that
        # are always present.
 
#		.p2align 3
#		.global	__vcr_vector_reset
#__vcr_vector_reset:
#			bri		_start
#        vcr_reset       _start
#        vcr_vector      user_exception, __call_vcr_user_exception
#        vcr_vector      interrupt, __call_vcr_interrupt
#        vcr_vector      break, __call_vcr_break
#        vcr_vector      hw_exception, __call_vcr_hw_exception
#        vcr_vector      reserved_a, __call_vcr_reserved_a
#        vcr_vector      reserved_b, __call_vcr_reserved_b
#        vcr_vector      reserved_c, __call_vcr_reserved_c
#        vcr_vector      reserved_d, __call_vcr_reserved_d
#        vcr_vector      reserved_e, __call_vcr_reserved_e


#rom_vectors_end:   

		



#===========================================================================
# Real startup code. We jump here from the various reset vectors to set up
# the world.

	.text
	.globl	_start
_start:
	# Initialize CPU to a post-reset state, ensuring the ground doesn't
	# shift under us while we try to set things up.
	hal_cpu_init

	# Set up global offset table
	addi	r2, r0, _GLOBAL_OFFSET_TABLE_

	# Call platform specific hardware initialization
	# This may include memory controller initialization. It is not
	# safe to access RAM until after this point.
	bralid	r15, hal_hardware_init	# this is platform dependent
	nop

        .globl	_hal_hardware_init_done
_hal_hardware_init_done:

# setup vectors
#if defined(CYG_HAL_STARTUP_ROM) || (!defined(CYG_HAL_STARTUP_ROM) && defined(CYGSEM_HAL_MICROBLAZE_COPY_VECTORS))
	addi	r3, r0, rom_vectors
	xor	r4, r4, r4
	addi	r5, r0, rom_vectors_end
	rsub	r6, r3, r5
	beqi	r6, 1f
0:      lwi	r6, r3, 0
	addi	r3, r3, 4
	swi	r6, r4, 0
	addi	r4, r4, 4
	pcmpeq	r6, r3, r5
        beqi	r6, 0b
1:
#endif

	# set up stack
	addi	r1, r0, __interrupt_stack

	# Set up exception handlers and VSR table, taking care not to
	# step on any ROM monitor''s toes.
	hal_mon_init

#if defined(CYG_HAL_STARTUP_ROM)
	# Copy data from ROM to ram
	addi	r3, r0, __rom_data_start	# r3 = rom start
	addi	r4, r0, __ram_data_start	# r4 = ram start
	addi	r5, r0, __ram_data_end		# r5 = ram end

	rsub    r6, r4, r5                   # skip if no data
	beqi    r6, 2f
1:
	lwi     r6, r3, 0               # get word from ROM
	swi     r6, r4, 0               # store in RAM
	addi    r3, r3, 4               # increment by 1 word
	addi    r4, r4, 4               # increment by 1 word
	rsub    r6, r4, r5              # compare
	bgti    r6, 1b                  # loop if not yet done
2:
#endif

        # clear BSS
        addi	r3, r0, __bss_start  # r3 = start
        addi	r4, r0, __bss_end    # r4 = end
        rsub	r5, r3, r4           # skip if no bss
        beqi	r5, 2f

1:      swi     r0, r3, 0       # store zero
        addi    r3, r3, 4       # increment by 1 word
        rsub   	r5, r3, r4      # compare
        bgti    r5, 1b          # loop if not yet done
2:

        # clear SBSS
        addi    r3, r0, __sbss_start # r3 = start
        addi    r4, r0, __sbss_end   # r4 = end
        rsub   	r5, r3, r4           # skip if no sbss
        beqi    r5, 2f

1:      swi     r0, r3, 0       # store zero
        addi    r3, r3, 4       # increment by 1 word
        rsub   	r5, r3, r4      # compare
        bgti    r5, 1b          # loop if not yet done
2:

        # It is now safe to call C functions which may rely on initialized
        # data.

        # Set up stack for calls to C code.
        addi    r1, r1, -12                     # make space on stack
        swi     r0, r1, 0                       # clear back chain
        swi     r0, r1, 8                       # zero return pc
		swi		r1, r1, -CYGARC_MB_STACK_FRAME_SIZE # create new stack frame
		addi	r1, r1, -CYGARC_MB_STACK_FRAME_SIZE

	# Variant HALs may need to do something special before we continue
	bralid	r15, hal_variant_init
	nop

	# Platform initialization
	bralid	r15, hal_platform_init
	nop

	# Enable caches
	bralid	r15, hal_enable_caches
	nop

	# set up platform specific interrupt environment
	bralid	r15, hal_IRQ_init
	nop

	# call c++ constructors
	bralid	r15, cyg_hal_invoke_constructors
	nop

#ifdef CYGDBG_HAL_DEBUG_GDB_INCLUDE_STUBS
	bralid	r15, initialize_stub
	nop
#endif
#if defined(CYGDBG_HAL_DEBUG_GDB_CTRLC_SUPPORT) || defined(CYGDBG_HAL_DEBUG_GDB_BREAK_SUPPORT)
	.extern hal_ctrlc_isr_init
	bralid	r15, hal_ctrlc_isr_init
	nop
#endif
	#hal_cpu_int_enable

        bralid	r15, cyg_start		# call cyg_start
	nop

	bri	0			# jump forever when our program ends

#---------------------------------------------------------------------------
# This code handles the common part of all exception handlers.
# It saves the machine state onto the stack  and then calls
# a "C" routine to do the rest of the work. This work may result
# in thread switches, and changes to the saved state. When we return
# here the saved state is restored and execution is continued.

        .text
        .globl cyg_hal_default_exception_vsr
cyg_hal_default_exception_vsr:
        
        # We come here with all register containing their
        # pre-exception values except:
		# SP + 0	= old SP
		# SP + 4	= vector adress
		# SP + 8	= old R3
		# R3 		= VSR adress

        addi    r1, r1, -CYGARC_MB_EXCEPTION_DECREMENT
                                        # leave space for registers and
                                        # a safety margin

        swi     r2, r1, CYGARC_MBREG_REGS+(2-1)*4
        swi     r4, r1, CYGARC_MBREG_REGS+(4-1)*4
        swi     r5, r1, CYGARC_MBREG_REGS+(5-1)*4
        swi     r6, r1, CYGARC_MBREG_REGS+(6-1)*4
        swi     r7, r1, CYGARC_MBREG_REGS+(7-1)*4
        swi     r8, r1, CYGARC_MBREG_REGS+(8-1)*4
        swi     r9, r1, CYGARC_MBREG_REGS+(9-1)*4
        swi     r10, r1, CYGARC_MBREG_REGS+(10-1)*4
        swi     r11, r1, CYGARC_MBREG_REGS+(11-1)*4
        swi     r12, r1, CYGARC_MBREG_REGS+(12-1)*4
        swi     r13, r1, CYGARC_MBREG_REGS+(13-1)*4
        swi     r14, r1, CYGARC_MBREG_REGS+(14-1)*4
        swi     r15, r1, CYGARC_MBREG_REGS+(15-1)*4
        swi     r16, r1, CYGARC_MBREG_REGS+(16-1)*4
        swi     r17, r1, CYGARC_MBREG_REGS+(17-1)*4
        swi     r18, r1, CYGARC_MBREG_REGS+(18-1)*4
        swi     r19, r1, CYGARC_MBREG_REGS+(19-1)*4
        swi     r20, r1, CYGARC_MBREG_REGS+(20-1)*4
        swi     r21, r1, CYGARC_MBREG_REGS+(21-1)*4
        swi     r22, r1, CYGARC_MBREG_REGS+(22-1)*4
        swi     r23, r1, CYGARC_MBREG_REGS+(23-1)*4
        swi     r24, r1, CYGARC_MBREG_REGS+(24-1)*4
        swi     r25, r1, CYGARC_MBREG_REGS+(25-1)*4
        swi     r26, r1, CYGARC_MBREG_REGS+(26-1)*4
        swi     r27, r1, CYGARC_MBREG_REGS+(27-1)*4
        swi     r28, r1, CYGARC_MBREG_REGS+(28-1)*4
        swi     r29, r1, CYGARC_MBREG_REGS+(29-1)*4
        swi     r30, r1, CYGARC_MBREG_REGS+(30-1)*4
        swi     r31, r1, CYGARC_MBREG_REGS+(31-1)*4
		
        addi    r20, r1, CYGARC_MB_EXCEPTION_DECREMENT					#recreate and save sp
		lwi		r3, r20, 0
		swi     r3, r1, CYGARC_MBREG_REGS+(1-1)*4						#save old sp
		lwi		r3, r20, 8
		swi		r3, r1, CYGARC_MBREG_REGS+(3-1)*4

				
		# vector address from index
		lwi		r3, r20, 4
		bslli	r3, r3, 3
		swi		r3, r1, CYGARC_MBREG_VECTOR
		
        # get remaining family CPU registers
        mfs   r3, rpc
        mfs   r4, rmsr

        # and store them
        swi     r3, r1, CYGARC_MBREG_PC
        swi     r4, r1, CYGARC_MBREG_MSR
                
        # Save variant registers
        hal_variant_save r1

        # Save FPU registers
        //hal_fpu_save r1

        # The entire CPU state is now stashed on the stack,
        # call into C to do something with it.

        add     r5, r0, r1                           # R5 = register dump
        //bslli	r6, r20, 2							 # R6 = vector (vsr_num * 4)
		lwi		r6, r20, 4
		bslli	r6, r6, 2
		
        addi    r1, r1, -CYGARC_MB_STACK_FRAME_SIZE  # make a null frame

        swi     r0, r1, 0                            # backchain = 0
        swi     r0, r1, 8                            # return pc = 0
        
        swi     r1, r1, -CYGARC_MB_STACK_FRAME_SIZE # create new stack frame
        addi	r1, r1, -CYGARC_MB_STACK_FRAME_SIZE # where C code can save LR

        //addi    r15, r0, restore_state                # get return link

        .extern cyg_hal_exception_handler
        //brai     cyg_hal_exception_handler            # call C code, r5 = registers, r6 = vector
		bralid   r15, cyg_hal_exception_handler              # call C code, r5 = registers, r6 = vector
		nop

		# When the call returns it will go to restore_state below.
		
		# retrieve CPU state pointer
        addi    r1, r1, CYGARC_MB_STACK_FRAME_SIZE*2

        # Restore FPU registers
        //hal_fpu_load r1

        # Restore variant registers
        hal_variant_load r1

        # restore registers r5..r31
        //lwi     r4, r1, CYGARC_MBREG_REGS+(4-1)*4
        lwi     r5, r1, CYGARC_MBREG_REGS+(5-1)*4
        lwi     r6, r1, CYGARC_MBREG_REGS+(6-1)*4
        lwi     r7, r1, CYGARC_MBREG_REGS+(7-1)*4
        lwi     r8, r1, CYGARC_MBREG_REGS+(8-1)*4
        lwi     r9, r1, CYGARC_MBREG_REGS+(9-1)*4
        lwi     r10, r1, CYGARC_MBREG_REGS+(10-1)*4
        lwi     r11, r1, CYGARC_MBREG_REGS+(11-1)*4
        lwi     r12, r1, CYGARC_MBREG_REGS+(12-1)*4
        lwi     r13, r1, CYGARC_MBREG_REGS+(13-1)*4
        lwi     r14, r1, CYGARC_MBREG_REGS+(14-1)*4
        lwi     r15, r1, CYGARC_MBREG_REGS+(15-1)*4
        lwi     r16, r1, CYGARC_MBREG_REGS+(16-1)*4
        lwi     r17, r1, CYGARC_MBREG_REGS+(17-1)*4
        lwi     r18, r1, CYGARC_MBREG_REGS+(18-1)*4
        lwi     r19, r1, CYGARC_MBREG_REGS+(19-1)*4
        lwi     r20, r1, CYGARC_MBREG_REGS+(20-1)*4
        lwi     r21, r1, CYGARC_MBREG_REGS+(21-1)*4
        lwi     r22, r1, CYGARC_MBREG_REGS+(22-1)*4
        lwi     r23, r1, CYGARC_MBREG_REGS+(23-1)*4
        lwi     r24, r1, CYGARC_MBREG_REGS+(24-1)*4
        lwi     r25, r1, CYGARC_MBREG_REGS+(25-1)*4
        lwi     r26, r1, CYGARC_MBREG_REGS+(26-1)*4
        lwi     r27, r1, CYGARC_MBREG_REGS+(27-1)*4
        lwi     r28, r1, CYGARC_MBREG_REGS+(28-1)*4
        lwi     r29, r1, CYGARC_MBREG_REGS+(29-1)*4
        lwi     r30, r1, CYGARC_MBREG_REGS+(30-1)*4
        lwi     r31, r1, CYGARC_MBREG_REGS+(31-1)*4

        //hal_cpu_int_disable
        
        # restore R2
        lwi     r2, r1, CYGARC_MBREG_REGS+(2-1)*4

		# load msr
        lwi     r3, r1, CYGARC_MBREG_MSR
		//andni	r3, r3, 0x0100
		mts		rmsr, r3
		
		# load vcr vector id
		addi    r3, r1, CYGARC_MB_EXCEPTION_DECREMENT
		lwi		r3, r3, 4
		
		# iff vcr id <= 3 -> 0
		addi	r4, r3, -3
		blei	r4, 0f

		#vcr id > 3
		#iff vcr id == 4 -> 1
		addi	r4, r3, -4
		beqi	r4, 1f

		#vcr id == 5, 6, 7, 8 or 9 (reserved)
		# restore r3, r4 a sp
		lwi     r4, r1, CYGARC_MBREG_REGS+(4-1)*4
        lwi     r3, r1, CYGARC_MBREG_REGS+(3-1)*4  # load r3 value
        lwi     r1, r1, CYGARC_MBREG_REGS+(1-1)*4  # restore sp
        rtsd	r15, 8                             # and return
		nop
		
		
1:		#vcr id == 4 (hw exception)
		# restore r3, r4 a sp
		lwi     r4, r1, CYGARC_MBREG_REGS+(4-1)*4
        lwi     r3, r1, CYGARC_MBREG_REGS+(3-1)*4  # load r3 value
        lwi     r1, r1, CYGARC_MBREG_REGS+(1-1)*4  # restore sp
        rted	r17, 0                             # and return
		nop
		
0:		#vcr id <= 3
		#iff vcr id == 3 -> 2
		beqi	r4, 2f

		#vcr id == 1 (user exception)
		# restore r3, r4 a sp
		lwi     r4, r1, CYGARC_MBREG_REGS+(4-1)*4
        lwi     r3, r1, CYGARC_MBREG_REGS+(3-1)*4  # load r3 value
        lwi     r1, r1, CYGARC_MBREG_REGS+(1-1)*4  # restore sp
        rtsd	r15, 8                             # and return
		nop
		
2:		#vcr id == 3 (break)
		# restore r3, r4 a sp
		lwi     r4, r1, CYGARC_MBREG_REGS+(4-1)*4
        lwi     r3, r1, CYGARC_MBREG_REGS+(3-1)*4  # load r3 value
        lwi     r1, r1, CYGARC_MBREG_REGS+(1-1)*4  # restore sp
        rtbd	r16, 0                             # and return
		nop
		



##--------------------------------------------------------------------------
## The following macros are defined depending on whether the Interrupt
## system is using isr tables or chaining, and depending on the interrupt
## controller in the system.

#ifndef CYGPKG_HAL_MB_INTC_DEFINED

## This is the simple version. No interrupt controller, CYGARC_PPCREG_VECTOR 
## is updated with the decoded interrupt vector. Isr tables/chaining
## use same interrupt decoder.
## Bit 21 biffers between decrementer (0) and external (1).

        # decode the interrupt
	.macro  hal_intc_decode dreg,state
		swi     r0, \state, 4					   # vector in state frame.
        xor    \dreg, \dreg, \dreg                 # word offset.
    .endm                              

#endif // CYGPKG_HAL_MB_INTC_DEFINED

#---------------------------------------------------------------------------
# Common interrupt handling code.

        .globl cyg_hal_default_interrupt_vsr
cyg_hal_default_interrupt_vsr:

        # We come here with all register containing their
        # pre-exception values except:
		# SP + 0	= old SP
		# SP + 4	= index of vector adress
		# SP + 8	= old R3
		# R3 		= VSR adress

        addi    r1, r1, -CYGARC_MB_EXCEPTION_DECREMENT
                                        # leave space for registers and
                                        # a safety margin

        swi     r2, r1, CYGARC_MBREG_REGS+(2-1)*4
        swi     r4, r1, CYGARC_MBREG_REGS+(4-1)*4
        swi     r5, r1, CYGARC_MBREG_REGS+(5-1)*4
        swi     r6, r1, CYGARC_MBREG_REGS+(6-1)*4
        swi     r7, r1, CYGARC_MBREG_REGS+(7-1)*4
        swi     r8, r1, CYGARC_MBREG_REGS+(8-1)*4
        swi     r9, r1, CYGARC_MBREG_REGS+(9-1)*4
        swi     r10, r1, CYGARC_MBREG_REGS+(10-1)*4
        swi     r11, r1, CYGARC_MBREG_REGS+(11-1)*4
        swi     r12, r1, CYGARC_MBREG_REGS+(12-1)*4
        swi     r13, r1, CYGARC_MBREG_REGS+(13-1)*4
        swi     r14, r1, CYGARC_MBREG_REGS+(14-1)*4
        swi     r15, r1, CYGARC_MBREG_REGS+(15-1)*4
        swi     r16, r1, CYGARC_MBREG_REGS+(16-1)*4
        swi     r17, r1, CYGARC_MBREG_REGS+(17-1)*4
        swi     r18, r1, CYGARC_MBREG_REGS+(18-1)*4
        swi     r19, r1, CYGARC_MBREG_REGS+(19-1)*4
        swi     r20, r1, CYGARC_MBREG_REGS+(20-1)*4
        swi     r21, r1, CYGARC_MBREG_REGS+(21-1)*4
        swi     r22, r1, CYGARC_MBREG_REGS+(22-1)*4
        swi     r23, r1, CYGARC_MBREG_REGS+(23-1)*4
        swi     r24, r1, CYGARC_MBREG_REGS+(24-1)*4
        swi     r25, r1, CYGARC_MBREG_REGS+(25-1)*4
        swi     r26, r1, CYGARC_MBREG_REGS+(26-1)*4
        swi     r27, r1, CYGARC_MBREG_REGS+(27-1)*4
        swi     r28, r1, CYGARC_MBREG_REGS+(28-1)*4
        swi     r29, r1, CYGARC_MBREG_REGS+(29-1)*4
        swi     r30, r1, CYGARC_MBREG_REGS+(30-1)*4
        swi     r31, r1, CYGARC_MBREG_REGS+(31-1)*4
		
        addi    r20, r1, CYGARC_MB_EXCEPTION_DECREMENT					#recreate and save sp
		lwi		r3, r20, 0
		swi     r3, r1, CYGARC_MBREG_REGS+(1-1)*4						#save old sp
		lwi		r3, r20, 8
		swi		r3, r1, CYGARC_MBREG_REGS+(3-1)*4
		
		# vector address from index
		lwi		r3, r20, 4
		bslli	r3, r3, 3
		swi		r3, r1, CYGARC_MBREG_VECTOR

        # get remaining family CPU registers
        mfs   r3, rpc
        mfs   r4, rmsr

        # and store them
        swi     r3, r1, CYGARC_MBREG_PC
        swi     r4, r1, CYGARC_MBREG_MSR
                
        # Save variant registers
        hal_variant_save r1

        # Save FPU registers
//        hal_fpu_save r1

        # The entire CPU state is now stashed on the stack,
        # increment the scheduler lock and call the ISR
        # for this vector.

#ifdef CYGFUN_HAL_COMMON_KERNEL_SUPPORT                 
        .extern cyg_scheduler_sched_lock
		lwi     r4, r0, cyg_scheduler_sched_lock
        addi    r4, r4, 1
        swi     r4, r0, cyg_scheduler_sched_lock
#endif
        
        add     r19, r0, r1                          # r19 = register dump
        
#ifdef CYGIMP_HAL_COMMON_INTERRUPTS_USE_INTERRUPT_STACK 
        addi    r3, r0, __interrupt_stack       # stack top
        addi    r4, r0, __interrupt_stack_base  # stack base
        rsub    r5, r4, r1                      # sp - base
        blti    r5, 1f	    	                # if < 0 - not on istack
        rsub    r5, r1, r3                      # top - sp
        bgti    r5, 2f		                    # if > 0 - already on istack

1: 		add     r1, r0, r3                      # switch to istack

2: 		addi	r1, r1, -4						# save old SP on stack
		swi     r19, r1, 0                     
#endif
        
        addi    r1, r1, -CYGARC_MB_STACK_FRAME_SIZE # make a null frame

        swi     r0, r1, 0                        # backchain = 0
        swi     r0, r1, 8                        # return pc = 0
        
        swi     r1, r1, -CYGARC_MB_STACK_FRAME_SIZE # create new stack frame
		addi	r1, r1, -CYGARC_MB_STACK_FRAME_SIZE  # where C code can save LR
        
#if defined(CYGPKG_KERNEL_INSTRUMENT) && defined(CYGDBG_KERNEL_INSTRUMENT_INTR)

        addi    r5, r0, 0x0301                  # r3 = type = INTR,RAISE
        lwi     r6, r20, 4				        # arg1 = vector address
        xor     r7,r7,r7                        # arg2 = 0
        bralid   cyg_instrument                  # call instrument function
		nop
        
#endif

        hal_intc_decode r21,r20                # get table index

#if defined(CYGDBG_HAL_DEBUG_GDB_CTRLC_SUPPORT) \
    || defined(CYGDBG_HAL_DEBUG_GDB_BREAK_SUPPORT)
	# If we are supporting Ctrl-C interrupts from GDB, we must squirrel
	# away a pointer to the save interrupt state here so that we can
	# plant a breakpoint at some later time.
	
	.extern	hal_saved_interrupt_state
	swi		r19, r0, hal_saved_interrupt_state
	
#endif

#ifdef CYGSEM_HAL_COMMON_INTERRUPTS_ALLOW_NESTING

#endif

        lwi     r5, r20, 4					    # retrieve decoded vector #

        lwi     r8, r21, hal_interrupt_handlers # load routine pointer

        lwi     r6, r21, hal_interrupt_data     # load data pointer
                                                # R6 = data argument
        add     r7, r0, r19                     # R7 = saved registers        
        
        brald 	r15, r8                         # branch to ctr reg and link
		nop

#ifdef CYGIMP_HAL_COMMON_INTERRUPTS_USE_INTERRUPT_STACK

        # If we are returning from the last nested interrupt, move back
        # to the thread stack. interrupt_end() must be called on the
        # thread stack since it potentially causes a context switch.
        # Since we have arranged for the top of stack location to
        # contain the sp we need to go back to here, just pop it off
        # and put it in SP.

        
        lwi     r1, r1, CYGARC_MB_STACK_FRAME_SIZE*2	 # sp = *sp

        addi    r1, r1, -CYGARC_MB_STACK_FRAME_SIZE # make a null frame

        swi     r0, r1, 0     			                 # backchain = 0
        swi     r0, r1, 8		                         # return pc = 0
        
        swi		r1, r1, -CYGARC_MB_STACK_FRAME_SIZE
		addi    r1, r1, -CYGARC_MB_STACK_FRAME_SIZE 	 # create new stack frame
														 # where C code can save LR
#endif  

#ifdef CYGFUN_HAL_COMMON_KERNEL_SUPPORT

        # We only need to call _interrupt_end() when there is a kernel
        # present to do any tidying up.
        
        # on return r3 bit 1 will indicate whether a DSR is
        # to be posted. Pass this together with a pointer to
        # the interrupt object we have just used to the
        # interrupt tidy up routine.

        # Note that r14 and r15 are defined to be preserved across
        # calls by the calling convention, so they still contain
        # the register dump and the vector number respectively.

		add		r5, r0, r3
        lwi     r6, r21, hal_interrupt_objects  # load object pointer
        add     r7, r0, r19                     # arg3 = saved register dump

        .extern interrupt_end
        bralid   r15, interrupt_end              # call into C to finish off 
		nop
#endif

//restore_state:  
        # All done, restore CPU state and continue

        # retrieve CPU state pointer
        addi    r1, r1, CYGARC_MB_STACK_FRAME_SIZE*2

        # Restore FPU registers
        //hal_fpu_load r1

        # Restore variant registers
        hal_variant_load r1

        # restore registers r4..r31
        lwi     r4, r1, CYGARC_MBREG_REGS+(4-1)*4
        lwi     r5, r1, CYGARC_MBREG_REGS+(5-1)*4
        lwi     r6, r1, CYGARC_MBREG_REGS+(6-1)*4
        lwi     r7, r1, CYGARC_MBREG_REGS+(7-1)*4
        lwi     r8, r1, CYGARC_MBREG_REGS+(8-1)*4
        lwi     r9, r1, CYGARC_MBREG_REGS+(9-1)*4
        lwi     r10, r1, CYGARC_MBREG_REGS+(10-1)*4
        lwi     r11, r1, CYGARC_MBREG_REGS+(11-1)*4
        lwi     r12, r1, CYGARC_MBREG_REGS+(12-1)*4
        lwi     r13, r1, CYGARC_MBREG_REGS+(13-1)*4
        lwi     r14, r1, CYGARC_MBREG_REGS+(14-1)*4
        lwi     r15, r1, CYGARC_MBREG_REGS+(15-1)*4
        lwi     r16, r1, CYGARC_MBREG_REGS+(16-1)*4
        lwi     r17, r1, CYGARC_MBREG_REGS+(17-1)*4
        lwi     r18, r1, CYGARC_MBREG_REGS+(18-1)*4
        lwi     r19, r1, CYGARC_MBREG_REGS+(19-1)*4
        lwi     r20, r1, CYGARC_MBREG_REGS+(20-1)*4
        lwi     r21, r1, CYGARC_MBREG_REGS+(21-1)*4
        lwi     r22, r1, CYGARC_MBREG_REGS+(22-1)*4
        lwi     r23, r1, CYGARC_MBREG_REGS+(23-1)*4
        lwi     r24, r1, CYGARC_MBREG_REGS+(24-1)*4
        lwi     r25, r1, CYGARC_MBREG_REGS+(25-1)*4
        lwi     r26, r1, CYGARC_MBREG_REGS+(26-1)*4
        lwi     r27, r1, CYGARC_MBREG_REGS+(27-1)*4
        lwi     r28, r1, CYGARC_MBREG_REGS+(28-1)*4
        lwi     r29, r1, CYGARC_MBREG_REGS+(29-1)*4
        lwi     r30, r1, CYGARC_MBREG_REGS+(30-1)*4
        lwi     r31, r1, CYGARC_MBREG_REGS+(31-1)*4

        hal_cpu_int_disable

        # restore R0 and R2
        lwi     r2, r1, CYGARC_MBREG_REGS+(2-1)*4

		#load msr but with disabled interrupts (will be enable with return instruction)
        lwi     r3, r1, CYGARC_MBREG_MSR
		andni	r3, r3, 0x0002
		mts		rmsr, r3
		
        lwi     r3, r1, CYGARC_MBREG_REGS+(3-1)*4  # load r3 value
        lwi     r1, r1, CYGARC_MBREG_REGS+(1-1)*4  # restore sp

        rtid	r14, 0                             # and return
		nop



##-----------------------------------------------------------------------------
## Execute pending DSRs on the interrupt stack with interrupts enabled.
## Note: this can only be called from code running on a thread stack

#ifdef CYGIMP_HAL_COMMON_INTERRUPTS_USE_INTERRUPT_STACK
	.extern cyg_interrupt_call_pending_DSRs

FUNC_START(hal_interrupt_stack_call_pending_DSRs)
        # Change to interrupt stack, save state and set up stack for
        # calls to C code.
        add     r3, r0, r1
        addi    r4, r0,  __interrupt_stack
		
        addi    r4, r4, -24                      # make space on stack
        
		add     r1, r0, r4
        swi     r3, r1, 12                      # save old sp
		mfs   	r3, rmsr
        swi     r3, r1, 16                      # save old MSR
        swi     r15, r1, 20                     # save old LR

        swi     r0, r1, 0                       # clear back chain
        swi     r0, r1, 8                       # zero return pc

        hal_cpu_int_enable

        # Call into kernel which will execute DSRs
        swi		r1, r1, -CYGARC_MB_STACK_FRAME_SIZE
		addi	r1, r1, -CYGARC_MB_STACK_FRAME_SIZE
		
		
        #ppc instr bl      cyg_interrupt_call_pending_DSRs
		bralid	r15, cyg_interrupt_call_pending_DSRs
		nop

        addi    r1,r1,CYGARC_MB_STACK_FRAME_SIZE

        lwi     r15, r1, 20                     # restore LR
        lwi     r5, r1, 12                      # get SP from saved state
        lwi     r3, r1, 16                      # restore interrupt setting
        hal_cpu_int_merge r3
		
	add	r1, r0, r5

	rtsd	r15, 8                          # and return to caller
	nop
#endif

#---------------------------------------------------------------------------
## Temporary interrupt stack

	.section ".bss"
	.balign 16
	.global cyg_interrupt_stack_base
cyg_interrupt_stack_base:
__interrupt_stack_base:
	.rept CYGNUM_HAL_COMMON_INTERRUPTS_STACK_SIZE
	.byte 0
	.endr
	.balign 16
	.global cyg_interrupt_stack
cyg_interrupt_stack:
__interrupt_stack:
        .long   0,0,0,0,0,0,0,0 

#---------------------------------------------------------------------------
# end of vectors.S
