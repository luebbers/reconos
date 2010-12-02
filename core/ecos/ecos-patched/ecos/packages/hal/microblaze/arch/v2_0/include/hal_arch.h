#ifndef CYGONCE_HAL_ARCH_H
#define CYGONCE_HAL_ARCH_H

//=============================================================================
//
//      hal_arch.h
//
//      Architecture specific abstractions
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
//
// eCos is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 or (at your option) any later version.
//
// eCos is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with eCos; if not, write to the Free Software Foundation, Inc.,
// 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
//
// As a special exception, if other files instantiate templates or use macros
// or inline functions from this file, or you compile this file and link it
// with other works to produce a work based on this file, this file does not
// by itself cause the resulting work to be covered by the GNU General Public
// License. However the source code for this file must still be made available
// in accordance with section (3) of the GNU General Public License.
//
// This exception does not invalidate any other reasons why a work based on
// this file might be covered by the GNU General Public License.
//
// Alternative licenses for eCos may be arranged by contacting Red Hat, Inc.
// at http://sources.redhat.com/ecos/ecos-license/
// -------------------------------------------
//####ECOSGPLCOPYRIGHTEND####
//=============================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):      Michal Pfeifer
// Original data:  PowerPC
// Contributors: 
// Date:        1997-09-08
// Purpose:     Define architecture abstractions
// Usage:       #include <cyg/hal/hal_arch.h>

//              
//####DESCRIPTIONEND####
//
//=============================================================================

#include <pkgconf/hal.h>
#include <cyg/infra/cyg_type.h>

#include <cyg/hal/mb_regs.h>           // CYGARC_REG_MSR_EE

//-----------------------------------------------------------------------------
// Processor saved states:

typedef struct 
{
    // These are common to all saved states
    cyg_uint32   d[31];                 // General Purpose Regs without R0 (always is 0)
										// R1 = stack pointer
										// R2 = small data area pointer - for read only
										// R13 - small data area pointer - for read-write
										// R14 - return address for interrupt
										// R15 - return address for sub-routine
										// R16 - return address for trap
										// R17 - return address for exceptions
										// R18 - reserved for assembler
	

    // These are saved for exceptions and interrupts, but may also
    // be saved in a context switch if thread-aware debugging is enabled.
    cyg_uint32   msr;                   // Machine State Reg
    cyg_uint32   pc;                    // Program Counter

	// Variant additional special purpose registers
	CYGARC_VAR_ADDITIONAL_SAVEDREGS

    // This marks the limit of state saved during a context switch and
    // is used to calculate necessary stack allocation for context switches.
    // It would probably be better to have a union instead...
    //cyg_uint32   context_size[0];

    // These are only saved for exceptions and interrupts
    cyg_uint32   vector;                // Vector number
    
	
} HAL_SavedRegisters;

#define CYGARC_MB_CONTEXT_SIZE (34 + CYGARC_VAR_ADDITIONAL_CONTEXT_SIZE) * 4

//-----------------------------------------------------------------------------
// Exception handling function.
// This function is defined by the kernel according to this prototype. It is
// invoked from the HAL to deal with any CPU exceptions that the HAL does
// not want to deal with itself. It usually invokes the kernel's exception
// delivery mechanism.

externC void cyg_hal_deliver_exception( CYG_WORD code, CYG_ADDRWORD data );

//-----------------------------------------------------------------------------
// Bit manipulation macros

externC cyg_uint32 hal_lsbit_index(cyg_uint32 mask);
externC cyg_uint32 hal_msbit_index(cyg_uint32 mask);

#define HAL_LSBIT_INDEX(index, mask) index = hal_lsbit_index(mask);

#define HAL_MSBIT_INDEX(index, mask) index = hal_msbit_index(mask);

//-----------------------------------------------------------------------------
// ABI
#define CYGARC_MB_STACK_FRAME_SIZE     48      // size of a stack frame

//-----------------------------------------------------------------------------
// Context Initialization
// Initialize the context of a thread.
// Arguments:
// _sparg_ name of variable containing current sp, will be written with new sp
// _thread_ thread object address, passed as argument to entry point
// _entry_ entry point address.
// _id_ bit pattern used in initializing registers, for debugging.

#define HAL_THREAD_INIT_CONTEXT( _sparg_, _thread_, _entry_, _id_ )         \
    CYG_MACRO_START                                                         \
    register CYG_WORD* _sp_ = ((CYG_WORD*)((_sparg_) &~15));            	\
    register HAL_SavedRegisters *_regs_;                                    \
    int _i_;                                                                \
    _regs_ = (HAL_SavedRegisters *)((_sp_) - ((sizeof(HAL_SavedRegisters) + CYGARC_MB_STACK_FRAME_SIZE) / 4));    \
    for( _i_ = 1; _i_ < 32; _i_++ ) (_regs_)->d[_i_ - 1] = (_id_)|_i_;      \
    (_regs_)->d[CYGARC_GPR_SP] = (CYG_WORD)(_sp_);     /* SP = top of stack */		\
	(_regs_)->d[04] = (CYG_WORD)(_thread_);    		   /* R5 = arg1 = thread ptr */   	\
    (_regs_)->d[CYGARC_GPR_LR] = (CYG_WORD)(_entry_) - 8;  /* LR = entry point */   \
    (_regs_)->pc = (CYG_WORD)(_entry_);        		   /* set PC for thread dbg  */   	\
    (_regs_)->msr = CYGARC_REG_MSR_IE;         		   /* MSR = enable irqs      */   	\
	CYGARC_VAR_ADDITIONAL_THREAD_INIT_CONTEXT								\
   _sparg_ = (CYG_ADDRESS)_regs_;                                          	\
    CYG_MACRO_END

//-----------------------------------------------------------------------------
// Context switch macros.
// The arguments are pointers to locations where the stack pointer
// of the current thread is to be stored, and from where the sp of the
// next thread is to be fetched.

externC void hal_thread_switch_context( CYG_ADDRESS to, CYG_ADDRESS from );
externC void hal_thread_load_context( CYG_ADDRESS to )
    __attribute__ ((noreturn));

#define HAL_THREAD_SWITCH_CONTEXT(_fspptr_,_tspptr_)                    \
        hal_thread_switch_context((CYG_ADDRESS)_tspptr_,(CYG_ADDRESS)_fspptr_);

#define HAL_THREAD_LOAD_CONTEXT(_tspptr_)                               \
        hal_thread_load_context( (CYG_ADDRESS)_tspptr_ );

//-----------------------------------------------------------------------------
// Execution reorder barrier.
// When optimizing the compiler can reorder code. In multithreaded systems
// where the order of actions is vital, this can sometimes cause problems.
// This macro may be inserted into places where reordering should not happen.

#define HAL_REORDER_BARRIER() asm volatile ( "" : : : "memory" )

//-----------------------------------------------------------------------------
// Breakpoint support
// HAL_BREAKPOINT() is a code sequence that will cause a breakpoint to happen
// if executed.
// HAL_BREAKINST is the value of the breakpoint instruction and 
// HAL_BREAKINST_SIZE is its size in bytes.

#define HAL_BREAKPOINT(_label_)                 \
asm volatile (" .globl  " #_label_ ";"          \
              #_label_":"                       \
              " brki r16, 0x18"                 \
    );

#define HAL_BREAKINST           0xBA0C0018

#define HAL_BREAKINST_SIZE      4

//-----------------------------------------------------------------------------
// Thread register state manipulation for GDB support.

// Translate a stack pointer as saved by the thread context macros above into
// a pointer to a HAL_SavedRegisters structure.
#define HAL_THREAD_GET_SAVED_REGISTERS( _sp_, _regs_ )  \
        (_regs_) = (HAL_SavedRegisters *)(_sp_)

// Copy a set of registers from a HAL_SavedRegisters structure into a
// GDB ordered array.    
#define HAL_GET_GDB_REGISTERS( _aregval_, _regs_ )              \
    CYG_MACRO_START                                             \
    CYG_ADDRWORD *_regval_ = (CYG_ADDRWORD *)(_aregval_);       \
    int _i_;                                                    \
                                                                \
    for( _i_ = 1; _i_ < 32; _i_++ )                             \
        _regval_[_i_] = (_regs_)->d[_i_ - 1];                   \
                                                                \
    _regval_[32] = (_regs_)->pc;                                \
    _regval_[33] = (_regs_)->msr;                               \
	HAL_GET_ADDITIONAL_GDB_REGISTERS							\
    CYG_MACRO_END

// Copy a GDB ordered array into a HAL_SavedRegisters structure.
#define HAL_SET_GDB_REGISTERS( _regs_ , _aregval_ )             \
    CYG_MACRO_START                                             \
    CYG_ADDRWORD *_regval_ = (CYG_ADDRWORD *)(_aregval_);       \
    int _i_;                                                    \
                                                                \
    for( _i_ = 1; _i_ < 32; _i_++ )                             \
        (_regs_)->d[_i_ - 1] = _regval_[_i_];                   \
                                                                \
    (_regs_)->pc  = _regval_[32];                               \
    (_regs_)->msr = _regval_[33];                               \
	HAL_SET_ADDITIONAL_GDB_REGISTERS							\
    CYG_MACRO_END

//-----------------------------------------------------------------------------
// HAL setjmp

typedef struct {
    cyg_uint32 sp;
    cyg_uint32 r2;
    cyg_uint32 r13;
    cyg_uint32 r14;
    cyg_uint32 r15;
    cyg_uint32 r16;
    cyg_uint32 r17;
    cyg_uint32 r18;
    cyg_uint32 r19;
    cyg_uint32 r20;
    cyg_uint32 r21;
    cyg_uint32 r22;
    cyg_uint32 r23;
    cyg_uint32 r24;
    cyg_uint32 r25;
    cyg_uint32 r26;
    cyg_uint32 r27;
    cyg_uint32 r28;
    cyg_uint32 r29;
    cyg_uint32 r30;
    cyg_uint32 r31;
} hal_jmp_buf_t;

#define CYGARC_JMP_BUF_SIZE      (sizeof(hal_jmp_buf_t) / sizeof(cyg_uint32))

typedef cyg_uint32 hal_jmp_buf[ CYGARC_JMP_BUF_SIZE ];

externC int hal_setjmp(hal_jmp_buf env);
externC void hal_longjmp(hal_jmp_buf env, int val);

//-----------------------------------------------------------------------------
// Idle thread code.
// This macro is called in the idle thread loop, and gives the HAL the
// chance to insert code. Typical idle thread behaviour might be to halt the
// processor.

externC void hal_idle_thread_action(cyg_uint32 loop_count);

#define HAL_IDLE_THREAD_ACTION(_count_) hal_idle_thread_action(_count_)

//-----------------------------------------------------------------------------
// Minimal and sensible stack sizes: the intention is that applications
// will use these to provide a stack size in the first instance prior to
// proper analysis.  Idle thread stack should be this big.

//    THESE ARE NOT INTENDED TO BE MICROMETRICALLY ACCURATE FIGURES.
//           THEY ARE HOWEVER ENOUGH TO START PROGRAMMING.
// YOU MUST MAKE YOUR STACKS LARGER IF YOU HAVE LARGE "AUTO" VARIABLES!
 
// This is not a config option because it should not be adjusted except
// under "enough rope" sort of disclaimers.
 
// Stack frame overhead per call. The PPC ABI defines regs 13..31 as callee
// saved. callee saved variables are irrelevant for us as they would contain
// automatic variables, so we only count the caller-saved regs here
// So that makes r0..r12 + cr, xer, lr, ctr:
//r1 .. r18
#define CYGNUM_HAL_STACK_FRAME_SIZE (4 * 18)

// Stack needed for a context switch
#define CYGNUM_HAL_STACK_CONTEXT_SIZE \
    ((33+CYGARC_VAR_ADDITIONAL_CONTEXT_SIZE)*4 /* offsetof(HAL_SavedRegisters, context_size) */)

// Interrupt + call to ISR, interrupt_end() and the DSR
#define CYGNUM_HAL_STACK_INTERRUPT_SIZE \
    (((33+CYGARC_VAR_ADDITIONAL_CONTEXT_SIZE)*4 /* sizeof(HAL_SavedRegisters) */) + 5 * CYGNUM_HAL_STACK_FRAME_SIZE)

// We have lots of registers so no particular amount is added in for
// typical local variable usage.

// We define a minimum stack size as the minimum any thread could ever
// legitimately get away with. We can throw asserts if users ask for less
// than this. Allow enough for three interrupt sources - clock, serial and
// one other

#ifdef CYGIMP_HAL_COMMON_INTERRUPTS_USE_INTERRUPT_STACK 

// An interrupt stack which is large enough for all possible interrupt
// conditions (and only used for that purpose) exists.  "User" stacks
// can therefore be much smaller

# define CYGNUM_HAL_STACK_SIZE_MINIMUM \
         (16*CYGNUM_HAL_STACK_FRAME_SIZE + 2*CYGNUM_HAL_STACK_INTERRUPT_SIZE)

#else

// No separate interrupt stack exists.  Make sure all threads contain
// a stack sufficiently large
# define CYGNUM_HAL_STACK_SIZE_MINIMUM                  \
        (((2+3)*CYGNUM_HAL_STACK_INTERRUPT_SIZE) +      \
         (16*CYGNUM_HAL_STACK_FRAME_SIZE))
#endif

// Now make a reasonable choice for a typical thread size. Pluck figures
// from thin air and say 30 call frames with an average of 16 words of
// automatic variables per call frame
#define CYGNUM_HAL_STACK_SIZE_TYPICAL                \
        (CYGNUM_HAL_STACK_SIZE_MINIMUM +             \
         30 * (CYGNUM_HAL_STACK_FRAME_SIZE+(16*4)))

//--------------------------------------------------------------------------
// Macros for switching context between two eCos instances (jump from
// code in ROM to code in RAM or vice versa).

// Should be defined like for MIPS, saving/restoring R2 - but is it
// actually used? I've never seen app code use R2. Something to investigate.
#define CYGARC_HAL_SAVE_GP()
#define CYGARC_HAL_RESTORE_GP()

//--------------------------------------------------------------------------
// Artificially increas stack size to account for the data saved by the
// compiler on function calls (e.g. return address, among others). These
// are saved by the compiler in memory addresses _before_ the stack pointer,
// which causes trouble when calling the entry function of a thread
#define HAL_THREAD_STACK_OFFSET 64
#define HAL_THREAD_ATTACH_STACK(stack_ptr, stack_base, stack_size) \
    stack_ptr = stack_base + stack_size - HAL_THREAD_STACK_OFFSET;                          


//-----------------------------------------------------------------------------
#endif // CYGONCE_HAL_ARCH_H
// End of hal_arch.h
