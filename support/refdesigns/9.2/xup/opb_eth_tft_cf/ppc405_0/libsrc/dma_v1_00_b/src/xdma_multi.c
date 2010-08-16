/* $Id: xdma_multi.c,v 1.1 2005/11/28 19:08:13 meinelte Exp $ */
/******************************************************************************
*
*       XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
*       AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND
*       SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,
*       OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
*       APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION
*       THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
*       AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
*       FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
*       WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
*       IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
*       REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
*       INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*       FOR A PARTICULAR PURPOSE.
*
*       (c) Copyright 2003-2004 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xdma_multi.c
*
* <b>Description</b>
*
* This file contains the multichannel DMA component. This component
* supports a multichannel DMA design in which each device can have it's own
* dedicated multiple channel DMA, as opposed to a centralized DMA design. This
* component performs processing for multichannel DMA on all devices.
*
* See xdma_multi.h for more information about this component.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- --------------------------------------------------------
* 1.00a ecm  09/16/03 First release
* 1.00a xd   10/27/04 Doxygenated for inclusion in API documentation
* 1.00b ecm  10/31/05 Updated for the check sum offload changes.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xdma_multi.h"
#include "xbasic_types.h"
#include "xio.h"

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

/*****************************************************************************/
/**
*
* This function initializes the multichannel DMA.  This function must be called
* prior to using the multichannel DMA.  Initialization of the instance includes
* setting up the registers base address, register access tables, and resetting
* the channels such that they are in a known state.  Interrupts for the
* channels are disabled when the channels are reset.
*
* @param InstancePtr contains a pointer to the multichannel DMA to operate on.
*
* @param BaseAddress contains the base address of the registers for the
*        multichannel DMA.
*
* @param UserMemoryPtr is a pointer to user allocated memory for the register
*        access tables and the buffer descriptor tables. The
*        XDmaMulti_mSizeNeeded() macro returns the amount of memory needed
*        for the number of channels configured.
*
* @param ChannelCount is the total number of transmit and receive channels
*        associated with the device
*
* @return
*   - XST_SUCCESS indicating initialization was successful.
*
*
* @note
*
* None.
*
******************************************************************************/
XStatus XDmaMulti_Initialize(XDmaMulti *InstancePtr,
                             Xuint32 BaseAddress,
                             Xuint32 *UserMemoryPtr,
                             Xuint16 ChannelCount)
{
    Xuint32 Channel;
    Xuint32 Register;

    /*
     * Assert to verify input arguments, don't assert base address
     * since the Hardware could be located there and the vectors
     * in high memory depending on processor used.
     */

    XASSERT_NONVOID(InstancePtr != XNULL);

    /*
     * Setup the base address of the registers for the multichannel DMA such
     * that register accesses can be done.
     */
    InstancePtr->BaseAddress = BaseAddress;

    /*
     * Initialize the register table in the user memory to contain
     * the addresses of each channels registers in the hardware such
     * that access to the registers is not too slow
     */
    InstancePtr->AddrTablePtr = UserMemoryPtr;

    for (Channel = 0; Channel < ChannelCount; Channel++)
    {
        InstancePtr->AddrTablePtr[Channel] = BaseAddress +
                                             XDM_CHANNEL_BASE_OFFSET +
                                             (XDM_CHANNEL_OFFSET * Channel);
    }

    InstancePtr->IsReady = XCOMPONENT_IS_READY;

    InstancePtr->ChannelCount = ChannelCount;

    /*
     * Set up pointer to the SG data structures
     */
    InstancePtr->SgDataTablePtr =
        (XDmaMulti_SgData *)((Xuint32)UserMemoryPtr +
                             (ChannelCount * sizeof(Xuint32)));

    for (Channel = 0; Channel < ChannelCount; Channel++)
    {
        /*
         * Initialize each scatter gather list such that it indicates
         * it has not been created yet and the multichannel DMA is ready
         * to use (initialized).
         */
        CHANNEL_DATA.GetPtr =    (XBufDescriptor *)XNULL;
        CHANNEL_DATA.PutPtr =    (XBufDescriptor *)XNULL;
        CHANNEL_DATA.CommitPtr = (XBufDescriptor *)XNULL;
        CHANNEL_DATA.LastPtr =   (XBufDescriptor *)XNULL;

        CHANNEL_DATA.TotalDescriptorCount = 0;
        CHANNEL_DATA.ActiveDescriptorCount = 0;

        /*
         * Reset each channel of the DMA such that it's in a known state and ready
         * and indicate the initialization occurred with no errors, note that
         * the is ready variable must be set before this call or reset will assert.
         */

        XDmaMulti_Reset(InstancePtr, Channel);
    }

    /* Enable the DMA Hardware using the Global Enable */
    Register = XDmaMulti_mGetGlobalControl(InstancePtr);

    XDmaMulti_mSetGlobalControl(InstancePtr,
                                Register | XDM_GCSR_GLOBAL_ENABLE_MASK);

    return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function performs a self test on the multichannel DMA.  This self test
* is destructive in that channel 0 of the DMA is reset and DMACR defaults
* are verified.
*
* @param InstancePtr is a pointer to the multichannel DMA to be operated on.
*
* @return
*   - XST_SUCCESS   is returned if the self test is successful, or one of the
*                   following errors.
*                   <br><br>
*   - XST_FAILURE   Indicates the test failed
*
* @note
*
* This test does not perform a DMA transfer to test the channel because the
* DMA hardware will not currently allow a non-local memory transfer to non-local
* memory (memory copy), but only allows a non-local memory to or from the device
* memory (typically a FIFO).
*
******************************************************************************/
XStatus XDmaMulti_SelfTest(XDmaMulti *InstancePtr)
{
    Xuint32 ControlReg;
    unsigned Channel = 0;

    /* Assert to verify input arguments. */

    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /*
     * Reset channel 0 of the DMA such that it's in a known state before the test
     * it resets to no interrupts enabled, the desired state for the test.
     */
    XDmaMulti_Reset(InstancePtr, Channel);

    /*
     * This should cause the DMACR to be set to 0, check the reset value of the
     * DMA control register to make sure it's correct, return with an error if
     * not.
     */
    ControlReg = XDmaMulti_mGetControl(InstancePtr, Channel);
    if (ControlReg != 0x00000000)
    {
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function resets a particular channel of the multichannel DMA. This is a
* destructive operation such that it should not be done while a channel is being
* used.  If the channel of the DMA is transferring data into other blocks, such as
* a FIFO, it may be necessary to reset other blocks.  This function does not
* modify the contents of the scatter gather list for the specified channel such
* that the user is responsible for getting buffer descriptors from the list if
* necessary.
*
* @param InstancePtr contains a pointer to the multichannel DMA to operate on.
*
* @param Channel is the particular channel that is to be reset.
*
* @return
*
* None.
*
* @note
*
* The registers are set to zero because they are in BRAM in this device. There
* is no initial state for BRAM and therefore it must be initialized to actually
* accomplish the reset state for the device..
*
******************************************************************************/
void XDmaMulti_Reset(XDmaMulti *InstancePtr, unsigned Channel)
{
    Xuint32 Register;

    /* Assert to verify input arguments. */

    XASSERT_VOID(InstancePtr != XNULL);
    XASSERT_VOID(InstancePtr->ChannelCount > Channel);
    XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /*
     * Set the Enable to 0 to allow the reset to occur
     */
    Register = XDmaMulti_mGetGlobalControl(InstancePtr);

    XDmaMulti_mSetGlobalControl(InstancePtr, 0);
    /*
     * The SWCR contains the Disable bit which is set here for completeness
     */
    XIo_Out32(CHANNEL_REGS + XDM_SWCR_REG_OFFSET, XDM_SWCR_SGD_MASK);

    /*
     * Reset the multichannel DMA such that it's in a known state,
     * with the default values for each register.
     * The following registers default to 0
     */
    XIo_Out32(CHANNEL_REGS + XDM_SYS_REG_OFFSET, 0x00000000);

    XIo_Out32(CHANNEL_REGS + XDM_DMACR_REG_OFFSET, 0x00000000);

    XIo_Out32(CHANNEL_REGS + XDM_SA_REG_OFFSET, 0x00000000);

    XIo_Out32(CHANNEL_REGS + XDM_DA_REG_OFFSET, 0x00000000);

    XIo_Out32(CHANNEL_REGS + XDM_LEN_REG_OFFSET, 0x00000000);

    XIo_Out32(CHANNEL_REGS + XDM_BDA_REG_OFFSET, 0x00000000);

    /*
     * The DMASR needs the L bit to be set as a result of Reset
     */

    XIo_Out32(CHANNEL_REGS + XDM_DMAS_REG_OFFSET, XDM_DMASR_LAST_BD_MASK);

    /*
     * Re-enable the hardware
     */
    XDmaMulti_mSetGlobalControl(InstancePtr, Register);

}

/*****************************************************************************/
/**
*
* This function starts the specified channel of DMA transferring data from a
* memory source to a memory destination. This function only starts the
* operation and returns before the operation may be complete.  If the interrupt
* is enabled, an interrupt will be generated when the operation is complete,
* otherwise it is necessary to poll the channel status to determine when it's
* complete.  It is the responsibility of the caller to determine when the
* operation is complete by handling the generated interrupt or polling the
* status.  It is also the responsibility of the caller to ensure that the
* DMA channel specified is not busy with another transfer before calling this
* function.
*
* @param InstancePtr contains a pointer to the multichannel DMA to operate on.
*
* @param Channel is the particular channel of interest.
*
* @param SourcePtr contains a pointer to the source memory where the data is to
*        be transferred from and must be 32 bit aligned.
*
* @param DestinationPtr contains a pointer to the destination memory where the
*        data is to be transferred and must be 32 bit aligned.
*
* @param ByteCount contains the number of bytes to transfer during the DMA
*        operation.
*
* @return
*
* None.
*
* @note
*
* The DMA hw will not currently allow a non-local memory transfer to non-local
* memory (memory copy), but only allows a non-local memory to or from the device
* memory (typically a FIFO).
* <br><br>
* It is the responsibility of the caller to ensure that the cache is
* flushed and invalidated both before and after the DMA operation completes
* if the memory pointed to is cached. The caller must also ensure that the
* pointers contain a physical address rather than a virtual address
* if address translation is being used.
*
******************************************************************************/
void XDmaMulti_Transfer(XDmaMulti *InstancePtr,
                        unsigned Channel,
                        Xuint32 *SourcePtr,
                        Xuint32 *DestinationPtr,
                        Xuint32 ByteCount)
{
    /*
     * Assert to verify input arguments and the alignment of any arguments
     * which have expected alignments
     */
    XASSERT_VOID(InstancePtr != XNULL);
    XASSERT_VOID(InstancePtr->ChannelCount > Channel);
    XASSERT_VOID(SourcePtr != XNULL);
    XASSERT_VOID(DestinationPtr != XNULL);
    XASSERT_VOID(ByteCount != 0);
    XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /* Setup the source and destination address registers for the transfer */

    XIo_Out32(CHANNEL_REGS + XDM_SA_REG_OFFSET, (Xuint32)SourcePtr);

    XIo_Out32(CHANNEL_REGS + XDM_DA_REG_OFFSET, (Xuint32)DestinationPtr);

    /*
     * Start the DMA transfer to copy from the source buffer to the
     * destination buffer by writing the length to the length register
     */
    XIo_Out32(CHANNEL_REGS + XDM_LEN_REG_OFFSET, ByteCount);
}
