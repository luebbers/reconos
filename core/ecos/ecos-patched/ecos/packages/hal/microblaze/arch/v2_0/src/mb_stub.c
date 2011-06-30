//========================================================================
//
//      mb_stub.c
//
//      Helper functions for stub, generic to all MicroBlaze processors
//
//========================================================================
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
//========================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):      Michal Pfeifer
// Original data:  PowerPC
// Contributors: 
// Date:          1998-08-20
// Purpose:       
// Description:   Helper functions for stub, generic to all MicroBlaze processors
// Usage:         
//
//####DESCRIPTIONEND####
//
//========================================================================

#include <stddef.h>

#include <pkgconf/hal.h>

#ifdef CYGDBG_HAL_DEBUG_GDB_INCLUDE_STUBS

#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
#include <cyg/hal/mb_regs.h>

#include <cyg/hal/hal_stub.h>
#include <cyg/hal/hal_arch.h>
#include <cyg/hal/hal_intr.h>

#ifdef CYGNUM_HAL_NO_VECTOR_TRACE
#define USE_BREAKPOINTS_FOR_SINGLE_STEP
#endif

#ifdef CYGDBG_HAL_DEBUG_GDB_THREAD_SUPPORT
#include <cyg/hal/dbg-threads-api.h> // dbg_currthread_id
#endif

/* Given a trap value TRAP, return the corresponding signal. */

int __computeSignal (unsigned int trap_number)
{
    switch (trap_number)
    {
    case CYGNUM_HAL_VECTOR_INTERRUPT:
        /* External interrupt */
      return SIGINT;

    case CYGNUM_HAL_VECTOR_BREAK:
        /* Instruction trace */
        return SIGTRAP;
      
    case CYGNUM_HAL_VECTOR_USER_EXCEPTION:
        // SIGTRAP to allow thread debugging.
        return SIGTRAP;

		case CYGNUM_HAL_VECTOR_HW_EXCEPTION:
        // SIGTRAP to allow thread debugging.
        return SIGTRAP;

	case CYGNUM_HAL_VECTOR_RESERVED_A:
    case CYGNUM_HAL_VECTOR_RESERVED_B:
    case CYGNUM_HAL_VECTOR_RESERVED_C:
    case CYGNUM_HAL_VECTOR_RESERVED_D:
    case CYGNUM_HAL_VECTOR_RESERVED_E:
        return SIGILL;
       
    default:
        return SIGTERM;
    }
}


/* Return the trap number corresponding to the last-taken trap. */

int __get_trap_number (void)
{
    // The vector is not not part of the GDB register set so get it
    // directly from the save context.
    return _hal_registers->vector >> 3;
}

/* Set the currently-saved pc register value to PC. This also updates NPC
   as needed. */

void set_pc (target_register_t pc)
{
    put_register (PC, pc);
}


/*----------------------------------------------------------------------
 * Single-step support
 */

/* Set things up so that the next user resume will execute one instruction.
   This may be done by setting breakpoints or setting a single step flag
   in the saved user registers, for example. */


#if (HAL_BREAKINST_SIZE == 1)
typedef cyg_uint8 t_inst;
#elif (HAL_BREAKINST_SIZE == 2)
typedef cyg_uint16 t_inst;
#elif (HAL_BREAKINST_SIZE == 4)
typedef cyg_uint32 t_inst;
#else
#error "Don't know how to handle that size"
#endif

typedef struct
{
  t_inst *targetAddr;
  t_inst savedInstr;
} instrBuffer;

static instrBuffer sstep_instr[2];
static target_register_t irq_state = 0;

static void 
__insert_break(int indx, target_register_t pc)
{
    sstep_instr[indx].targetAddr = (t_inst *)pc;
    sstep_instr[indx].savedInstr = *(t_inst *)pc;
    *(t_inst*)pc = (t_inst)HAL_BREAKINST;
    __data_cache(CACHE_FLUSH);
    __instruction_cache(CACHE_FLUSH);
}

static void 
__remove_break(int indx)
{
    if (sstep_instr[indx].targetAddr != 0) {
        *(sstep_instr[indx].targetAddr) = sstep_instr[indx].savedInstr;
        sstep_instr[indx].targetAddr = 0;
        __data_cache(CACHE_FLUSH);
        __instruction_cache(CACHE_FLUSH);
    }
}

int
__is_single_step(target_register_t pc)
{
    return (sstep_instr[0].targetAddr == pc) ||
        (sstep_instr[1].targetAddr == pc);
}


// Compute the target address for this instruction, if the instruction
// is some sort of branch/flow change.

struct a_form {
	unsigned int op : 6;
	unsigned int dr : 5;
	unsigned int sra : 5;
	unsigned int srb : 5;
};

struct b_form {
	unsigned int op : 6;
	unsigned int dr : 5;
	unsigned int sra : 5;
	unsigned int imm : 16;
};

union mb_insn {
    unsigned int   word;
    struct a_form  a;
    struct b_form  b;
};

static target_register_t
__branch_pc(target_register_t pc)
{
    union mb_insn insn;

	target_register_t apc = pc;
    insn.word = *(t_inst *)pc;

	long imm = 0;
	
	// if instruction imm is on pc we read imm number and jump to next pc (pc+4)
	if (insn.b.op == 44 && insn.b.dr == 0 && insn.b.sra == 0){
		imm = ((long)(insn.b.imm)) << 16;
		apc +=4;
		insn.word = *(t_inst *)(apc);
		
	}
	
    switch (insn.a.op) {
    case 38:
		if(insn.a.sra == 12) {
			//brk
			return (target_register_t)((long)get_register(insn.a.srb - 1));
		}
		else {
			//br
			if((insn.a.sra & 0x8)!=0)
				return (target_register_t)(((long)get_register(insn.a.srb - 1)));
			else
				return (target_register_t)(((long)get_register(insn.a.srb - 1)) + (long)apc);
		}
    case 39:
		switch (insn.a.dr & 0x0F) {
			case 0:
				// beq
				if(((long)get_register(insn.a.sra - 1)) == 0)
					return (target_register_t)(((long)get_register(insn.a.srb - 1)) + (long)apc);
				else
					break;
			case 1:
				// bne
				if(((long)get_register(insn.a.sra - 1)) != 0)
					return (target_register_t)(((long)get_register(insn.a.srb - 1)) + (long)apc);
				else
					break;
			case 2:
				// blt
				if(((long)get_register(insn.a.sra - 1)) < 0)
					return (target_register_t)(((long)get_register(insn.a.srb - 1)) + (long)apc);
				else
					break;
			case 3:
				// ble
				if(((long)get_register(insn.a.sra - 1)) <= 0)
					return (target_register_t)(((long)get_register(insn.a.srb - 1)) + (long)apc);
				else
					break;
			case 4:
				// bgt
				if(((long)get_register(insn.a.sra - 1)) > 0)
					return (target_register_t)(((long)get_register(insn.a.srb - 1)) + (long)apc);
				else
					break;
			case 5:
				// bge
				if(((long)get_register(insn.a.sra - 1)) >= 0)
					return (target_register_t)(((long)get_register(insn.a.srb - 1)) + (long)apc);
				else
					break;
			default:
				break;
		}
		break;
	case 45:
		switch (insn.b.dr) {
			case 16:
				// rtsd
				return (target_register_t)(((long)get_register(insn.b.sra - 1)) + imm + (long)(insn.b.imm));
			case 17:
				// rtid
				return (target_register_t)(((long)get_register(insn.b.sra - 1)) + imm + (long)(insn.b.imm));
			case 18:
				// rtbd
				return (target_register_t)(((long)get_register(insn.b.sra - 1)) + imm + (long)(insn.b.imm));
			case 20:
				// rted
				return (target_register_t)(((long)get_register(insn.b.sra - 1)) + imm + (long)(insn.b.imm));
			default:
				break;
		}
		break;
    case 46:
		if(insn.b.sra == 12) {
			//brki
			return (target_register_t)((long)(insn.b.imm) + imm);
		}
		else {
			//bri
			if((insn.b.sra & 0x8)!=0)
				return (target_register_t)((long)(insn.b.imm) + imm);
			else
				return (target_register_t)((long)(insn.b.imm) + imm + (long)apc);
		}
    case 47:
		switch (insn.b.dr & 0x0F) {
			case 0:
				// beq
				if(((long)get_register(insn.b.sra - 1)) == 0)
					return (target_register_t)((long)(insn.b.imm) + imm + (long)apc);
				else
					break;
			case 1:
				// bne
				if(((long)get_register(insn.b.sra - 1)) != 0)
					return (target_register_t)((long)(insn.b.imm) + imm + (long)apc);
				else
					break;
			case 2:
				// blt
				if(((long)get_register(insn.b.sra - 1)) < 0)
					return (target_register_t)((long)(insn.b.imm) + imm + (long)apc);
				else
					break;
			case 3:
				// ble
				if(((long)get_register(insn.b.sra - 1)) <= 0)
					return (target_register_t)((long)(insn.b.imm) + imm + (long)apc);
				else
					break;
			case 4:
				// bgt
				if(((long)get_register(insn.b.sra - 1)) > 0)
					return (target_register_t)((long)(insn.b.imm) + imm + (long)apc);
				else
					break;
			case 5:
				// bge
				if(((long)get_register(insn.b.sra - 1)) >= 0)
					return (target_register_t)((long)(insn.b.imm) + imm + (long)apc);
				else
					break;
			default:
				break;
		}
		break;
    default:
		break;
    }
    return (pc+4);
}

void __single_step(void)
{
    target_register_t msr = get_register(MSR);
    target_register_t pc = get_register(PC);
    target_register_t next_pc = __branch_pc(pc);

    // Disable interrupts.
    irq_state = msr & MSR_IE;
    msr &= ~MSR_IE;
    put_register (MSR, msr);

    // Set a breakpoint at the next instruction
    if (next_pc != (pc+4)) {
        __insert_break(1, next_pc);
    }
	else __insert_break(0, pc+4);
}

/* Clear the single-step state. */

void __clear_single_step(void)
{
    target_register_t msr = get_register (MSR);

    // Restore interrupt state.
    // FIXME: Should check whether the executed instruction changed the
    // interrupt state - or single-stepping a MSR changing instruction
    // may result in a wrong EE. Not a very likely scenario though.
    msr |= irq_state;

    // This function is called much more than its counterpart
    // __single_step.  Only re-enable interrupts if they where
    // disabled during the previous cal to __single_step. Otherwise,
    // this function only makes "extra sure" that no trace or branch
    // exception will happen.
    irq_state = 0;

    put_register (MSR, msr);

    // Remove breakpoints
    __remove_break(0);
    __remove_break(1);
}


void __install_breakpoints (void)
{
    /* NOP since single-step HW exceptions are used instead of
       breakpoints. */
}

void __clear_breakpoints (void)
{
}


/* If the breakpoint we hit is in the breakpoint() instruction, return a
   non-zero value. */

int
__is_breakpoint_function ()
{
    return get_register (PC) == (target_register_t)HAL_BREAKINST;
}


/* Skip the current instruction.  Since this is only called by the
   stub when the PC points to a breakpoint or trap instruction,
   we can safely just skip 4. */

void __skipinst (void)
{
    put_register (PC, get_register (PC) + 4);
}

#endif // CYGDBG_HAL_DEBUG_GDB_INCLUDE_STUBS
