#ifndef CYGONCE_HAL_INTR_H
#define CYGONCE_HAL_INTR_H

//==========================================================================
//
//      hal_intr.h
//
//      HAL Interrupt and clock support
//
//==========================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2002 Gary Thomas
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
//==========================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):      Michal Pfeifer
// Original data:  PowerPC
// Contributors: 
// Date:         1999-02-19
// Purpose:      Define Interrupt support
// Description:  The macros defined here provide the HAL APIs for handling
//               interrupts and the clock.
//              
// Usage:
//               #include <cyg/hal/hal_intr.h>
//               ...
//              
//
//####DESCRIPTIONEND####
//
//==========================================================================

#include <pkgconf/hal.h>

#include <cyg/infra/cyg_type.h>         // types

#include <cyg/hal/mb_regs.h>           // register definitions

#include <cyg/hal/var_intr.h>           // variant extensions

//--------------------------------------------------------------------------
// MicroBlaze exception vectors. These correspond to VSRs and are the values
// to use for HAL_VSR_GET/SET

#define CYGNUM_HAL_VECTOR_RESET             0
#define CYGNUM_HAL_VECTOR_USER_EXCEPTION    1
#define CYGNUM_HAL_VECTOR_INTERRUPT         2
#define CYGNUM_HAL_VECTOR_BREAK		        3
#define CYGNUM_HAL_VECTOR_HW_EXCEPTION      4
#define CYGNUM_HAL_VECTOR_RESERVED_A        5
#define CYGNUM_HAL_VECTOR_RESERVED_B        6
#define CYGNUM_HAL_VECTOR_RESERVED_C        7
#define CYGNUM_HAL_VECTOR_RESERVED_D        8
#define CYGNUM_HAL_VECTOR_RESERVED_E        9

#define CYGNUM_HAL_VSR_MIN                   CYGNUM_HAL_VECTOR_RESET
#ifndef CYGNUM_HAL_VSR_MAX
# define CYGNUM_HAL_VSR_MAX                  CYGNUM_HAL_VECTOR_RESERVED_E
#endif
#define CYGNUM_HAL_VSR_COUNT                 ( CYGNUM_HAL_VSR_MAX - CYGNUM_HAL_VSR_MIN + 1 )

#ifndef CYG_VECTOR_IS_INTERRUPT
# define CYG_VECTOR_IS_INTERRUPT(v)   \
     (CYGNUM_HAL_VECTOR_INTERRUPT == (v))
#endif

// The decoded interrupts.
// Define decrementer as the first interrupt since it is guaranteed to
// be defined on all MicroBlazes. External may expand into several interrupts
// depending on interrupt controller capabilities.
#define CYGNUM_HAL_INTERRUPT_EXTERNAL        1

#define CYGNUM_HAL_ISR_MIN                   CYGNUM_HAL_INTERRUPT_EXTERNAL
#ifndef CYGNUM_HAL_ISR_MAX
# define CYGNUM_HAL_ISR_MAX                  CYGNUM_HAL_INTERRUPT_EXTERNAL
#endif
#define CYGNUM_HAL_ISR_COUNT                 ( CYGNUM_HAL_ISR_MAX - CYGNUM_HAL_ISR_MIN + 1 )

#ifndef CYGHWR_HAL_EXCEPTION_VECTORS_DEFINED
// Exception vectors. These are the values used when passed out to an
// external exception handler using cyg_hal_deliver_exception()

#define CYGNUM_HAL_EXCEPTION_USER_EXCEPTION		CYGNUM_HAL_VECTOR_USER_EXCEPTION
#define CYGNUM_HAL_EXCEPTION_HW_EXCEPTION		CYGNUM_HAL_VECTOR_HW_EXCEPTION
#define CYGNUM_HAL_EXCEPTION_RESERVED_A			CYGNUM_HAL_VECTOR_RESERVED_A
#define CYGNUM_HAL_EXCEPTION_RESERVED_B			CYGNUM_HAL_VECTOR_RESERVED_B
#define CYGNUM_HAL_EXCEPTION_RESERVED_C			CYGNUM_HAL_VECTOR_RESERVED_C
#define CYGNUM_HAL_EXCEPTION_RESERVED_D			CYGNUM_HAL_VECTOR_RESERVED_D
#define CYGNUM_HAL_EXCEPTION_RESERVED_E			CYGNUM_HAL_VECTOR_RESERVED_E

#define CYGNUM_HAL_EXCEPTION_MIN             CYGNUM_HAL_VECTOR_USER_EXCEPTION
#ifndef CYGNUM_HAL_EXCEPTION_MAX
#define CYGNUM_HAL_EXCEPTION_MAX             CYGNUM_HAL_VECTOR_RESERVED_E
#endif

#define CYGHWR_HAL_EXCEPTION_VECTORS_DEFINED

#endif // CYGHWR_HAL_EXCEPTION_VECTORS_DEFINED

#define CYGNUM_HAL_EXCEPTION_COUNT           \
                 ( CYGNUM_HAL_EXCEPTION_MAX - CYGNUM_HAL_EXCEPTION_MIN + 1 )

//--------------------------------------------------------------------------
// Static data used by HAL

// ISR tables
externC volatile CYG_ADDRESS    hal_interrupt_handlers[CYGNUM_HAL_ISR_COUNT];
externC volatile CYG_ADDRWORD   hal_interrupt_data[CYGNUM_HAL_ISR_COUNT];
externC volatile CYG_ADDRESS    hal_interrupt_objects[CYGNUM_HAL_ISR_COUNT];
// VSR table
externC volatile CYG_ADDRESS    hal_vsr_table[CYGNUM_HAL_VSR_COUNT];

//--------------------------------------------------------------------------
// Default ISRs
// The #define is used to test whether this routine exists, and to allow
// us to call it.

externC cyg_uint32 hal_default_isr(CYG_ADDRWORD vector, CYG_ADDRWORD data);

#define HAL_DEFAULT_ISR hal_default_isr

//--------------------------------------------------------------------------
// Interrupt state storage

typedef cyg_uint32 CYG_INTERRUPT_STATE;

//--------------------------------------------------------------------------
// Interrupt control macros

#define HAL_DISABLE_INTERRUPTS(_old_)                   \
    CYG_MACRO_START                                     \
    asm volatile (                                      \
        "msrclr %0, 0x0002;"                            \
        : "=r"(_old_));       							\
    CYG_MACRO_END

#define HAL_ENABLE_INTERRUPTS()         				\
    CYG_MACRO_START                                     \
    asm volatile (                                      \
        "msrset r0, 0x0002;");       					\
    CYG_MACRO_END

#define HAL_RESTORE_INTERRUPTS(_old_)   \
    CYG_MACRO_START                     \
    cyg_uint32 tmp1, tmp2;              \
    asm volatile (                      \
        "mfs  	%0, rmsr;"              \
        "andni	%0, %0, 0x0002;"        \
        "andi	%1, %2, 0x0002;"        \
        "or		%0, %0, %1;"            \
        "mts	rmsr, %0;"              \
        : "=&r" (tmp1), "=&r" (tmp2)    \
        : "r" (_old_));                 \
    CYG_MACRO_END

#define HAL_QUERY_INTERRUPTS(_old_)     \
    CYG_MACRO_START                     \
    asm volatile (                      \
        "mfs  %0;"                    	\
        "andni	%0, %0, 0x0002;"        \
        : "=&r"(_old_));     					\
    CYG_MACRO_END

//--------------------------------------------------------------------------
// Vector translation.

#ifndef HAL_TRANSLATE_VECTOR
// Basic MicroBlaze configuration only has two vectors; decrementer and
// external. Isr tables/chaining use same vector decoder.
#define HAL_TRANSLATE_VECTOR(_vector_,_index_) \
    (_index_) = (_vector_ - CYGNUM_HAL_ISR_MIN)
#endif

//--------------------------------------------------------------------------
#ifdef CYGIMP_HAL_COMMON_INTERRUPTS_USE_INTERRUPT_STACK

externC void hal_interrupt_stack_call_pending_DSRs(void);
#define HAL_INTERRUPT_STACK_CALL_PENDING_DSRS() \
    hal_interrupt_stack_call_pending_DSRs()

// these are offered solely for stack usage testing
// if they are not defined, then there is no interrupt stack.
#define HAL_INTERRUPT_STACK_BASE cyg_interrupt_stack_base
#define HAL_INTERRUPT_STACK_TOP  cyg_interrupt_stack
// use them to declare these extern however you want:
//       extern char HAL_INTERRUPT_STACK_BASE[];
//       extern char HAL_INTERRUPT_STACK_TOP[];
// is recommended
#endif

//--------------------------------------------------------------------------
// Interrupt and VSR attachment macros

#define HAL_INTERRUPT_IN_USE( _vector_, _state_)                             \
    CYG_MACRO_START                                                          \
    cyg_uint32 _index_;                                                      \
    HAL_TRANSLATE_VECTOR ((_vector_), _index_);                              \
                                                                             \
    if(hal_interrupt_handlers[_index_] == (CYG_ADDRESS)hal_default_isr) 	 \
        (_state_) = 0;                                                       \
    else                                                                     \
        (_state_) = 1;                                                       \
    CYG_MACRO_END

#define HAL_INTERRUPT_ATTACH( _vector_, _isr_, _data_, _object_ )            \
    CYG_MACRO_START                                                          \
    cyg_uint32 _index_;                                                      \
    HAL_TRANSLATE_VECTOR ((_vector_), _index_);                              \
                                                                             \
    if(hal_interrupt_handlers[_index_] == (CYG_ADDRESS)hal_default_isr)		 \
    {                                                                        \
        hal_interrupt_handlers[_index_] = (CYG_ADDRESS)_isr_;                \
        hal_interrupt_data[_index_] = (CYG_ADDRWORD) _data_;                 \
        hal_interrupt_objects[_index_] = (CYG_ADDRESS)_object_;              \
    }                                                                        \
    CYG_MACRO_END

#define HAL_INTERRUPT_DETACH( _vector_, _isr_ )                             \
    CYG_MACRO_START                                                         \
    cyg_uint32 _index_;                                                     \
    HAL_TRANSLATE_VECTOR ((_vector_), _index_);                             \
                                                                            \
    if( hal_interrupt_handlers[_index_] == (CYG_ADDRESS)_isr_ )             \
    {                                                                       \
        hal_interrupt_handlers[_index_] = (CYG_ADDRESS)hal_default_isr;		\
        hal_interrupt_data[_index_] = 0;                                    \
        hal_interrupt_objects[_index_] = 0;                                 \
    }                                                                       \
    CYG_MACRO_END

#define HAL_VSR_GET( _vector_, _pvsr_ )                                 \
    *(CYG_ADDRESS *)(_pvsr_) = hal_vsr_table[_vector_];
    

#define HAL_VSR_SET( _vector_, _vsr_, _poldvsr_ )               \
    CYG_MACRO_START                                             \
    if( _poldvsr_ != NULL )                                     \
        *(CYG_ADDRESS *)_poldvsr_ = hal_vsr_table[_vector_];    \
    hal_vsr_table[_vector_] = (CYG_ADDRESS)_vsr_;               \
    CYG_MACRO_END

// This is an ugly name, but what it means is: grab the VSR back to eCos
// internal handling, or if you like, the default handler.  But if
// cooperating with GDB and CygMon, the default behaviour is to pass most
// exceptions to CygMon.  This macro undoes that so that eCos handles the
// exception.  So use it with care.
externC void cyg_hal_default_interrupt_vsr( void );
externC void cyg_hal_default_exception_vsr( void );
#define HAL_VSR_SET_TO_ECOS_HANDLER( _vector_, _poldvsr_ )                    \
    CYG_MACRO_START                                                           \
    if( (void*)_poldvsr_ != (void*)NULL )                                     \
        *(CYG_ADDRESS *)_poldvsr_ = hal_vsr_table[_vector_];                  \
    hal_vsr_table[_vector_] = ( CYG_VECTOR_IS_INTERRUPT( _vector_ )           \
                               ? (CYG_ADDRESS)cyg_hal_default_interrupt_vsr   \
                              : (CYG_ADDRESS)cyg_hal_default_exception_vsr ); \
    CYG_MACRO_END


#ifndef CYGHWR_HAL_INTERRUPT_CONTROLLER_ACCESS_DEFINED

#define HAL_INTERRUPT_MASK( _vector_ )

#define HAL_INTERRUPT_UNMASK( _vector_ )

#define HAL_INTERRUPT_ACKNOWLEDGE( _vector_ )

#define HAL_INTERRUPT_CONFIGURE( _vector_, _level_, _up_ )

#define HAL_INTERRUPT_SET_LEVEL( _vector_, _level_ )

#endif

//--------------------------------------------------------------------------
// Clock control

externC void hal_clock_initialize(cyg_uint32);
externC void hal_clock_read(cyg_uint32 *);
externC void hal_clock_reset(cyg_uint32, cyg_uint32);


#define HAL_CLOCK_INITIALIZE( _period_ )   hal_clock_initialize( _period_ )
#define HAL_CLOCK_RESET( _vec_, _period_ ) hal_clock_reset( _vec_, _period_ )
#define HAL_CLOCK_READ( _pvalue_ )         hal_clock_read( _pvalue_ )
#ifdef CYGVAR_KERNEL_COUNTERS_CLOCK_LATENCY
# ifndef HAL_CLOCK_LATENCY
#  define HAL_CLOCK_LATENCY( _pvalue_ )    HAL_CLOCK_READ( (cyg_uint32 *)_pvalue_ )
# endif
#endif




#ifndef HAL_DELAY_US
extern void hal_delay_us(cyg_uint32 us);
#define HAL_DELAY_US(n) hal_delay_us(n)
#endif

//--------------------------------------------------------------------------
// Variant functions
externC void hal_variant_IRQ_init(void);

//--------------------------------------------------------------------------
#endif // ifndef CYGONCE_HAL_INTR_H
// End of hal_intr.h
