///
/// \file _mcount.S
///
/// Fixed interval timer and gprof profiling TODO
///
/// \author     Andreas Agne <agne@upb.de>
/// \date       09.05.2008
//
//---------------------------------------------------------------------------
//
// Copyright (c) 2002 Xilinx, Inc.  All rights reserved. 
// Xilinx, Inc. 
//
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
// AND FITNESS FOR A PARTICULAR PURPOSE. 
//
// $Id: profile_mcount_ppc.S,v 1.1.6.6 2005/11/15 23:40:59 salindac Exp $
//
	.globl _mcount
			
	.section .text 
	.align 2
	.type _mcount@function


_mcount:

	stwu    1,-48(1)
	stw     3,12(1)
	stw     4,16(1)
	stw     5,20(1)
	stw     6,24(1)
	mflr    4
	lwz     3,52(1)
	mfcr    5
	stw     7,28(1)
	stw     8,32(1)
	stw     9,36(1)
	stw     10,40(1)
	stw     4,44(1)
	stw     5,8(1)
	bl      __profile_mcount
	nop
	lwz     6,8(1)
	lwz     0,44(1)
	lwz     3,12(1)
	mtctr   0
	lwz     4,16(1)
	mtcr    6
	lwz     5,20(1)
	lwz     6,24(1)
	lwz     0,52(1)
	lwz     7,28(1)
	lwz     8,32(1)
	mtlr    0
	lwz     9,36(1)
	lwz     10,40(1)
	addi    1,1,48
	bctr
	
