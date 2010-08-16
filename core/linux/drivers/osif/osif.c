///
/// \file osif.c
///
/// OSIF device driver for supporting ReconOS on Linux 2.6.
///
/// This driver provides character devices (e.g. /dev/osifnnn) for
/// accessing ReconOS OSIF registers from user space, in particular
/// from a delegate thread.
///
/// \author     Enno Luebbers <enno.luebbers@upb.de>
/// \date       15.01.2008
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
// Major Changes:
// 
// 15.01.2008   Enno Luebbers   File created
// 18.11.2008   Enno Luebbers   changed to use OF device tree model
//                              and new DCR access infrastructure
// 

#include <linux/autoconf.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/fs.h>       /* everything... */
#include <linux/errno.h>    /* error codes */
#include <linux/types.h>    /* size_t */
#include <linux/proc_fs.h>
#include <linux/fcntl.h>    /* O_ACCMODE */
#include <linux/seq_file.h>
#include <linux/cdev.h>
#include <linux/interrupt.h>
#include <asm/uaccess.h>
#include <asm/io.h>

// open firmware
#include <linux/of_device.h>
#include <linux/of_platform.h>

//#define __uCLinux__
// DCR access not supported in petalinux
#ifndef __uCLinux__
#include <asm/dcr.h>
#else
#define mtdcr(x, y) PDEBUG("mtdcr() not supported in uCLinux!\n")
#define mfdcr(x)    PDEBUG("mfdcr() not supported in uCLinux!\n")
#endif

#include "osif.h"

// TYPE DEFINITIONS ========================================

struct osif_dev {
    unsigned int slot_num;                  // slot number (for debugging)
    unsigned int read_buffer[OSIF_DCR_READSIZE];  // buffer for DCR reads
    unsigned int write_buffer[OSIF_DCR_WRITESIZE]; // buffer for DCR writes
    loff_t next_read;                       // next expected read offset
    loff_t next_write;                      // next expected write offset
    dcr_host_t dcr_host;                    // dcr access structure
    unsigned int dcr_len;                   // length of DCR address space (4)
    unsigned int irq;                       // interrupt number of OSIF
    struct semaphore sem;                   // mutual exclusion semaphore
    wait_queue_head_t read_queue;           // queue for blocking reads
    volatile unsigned short irq_count;      // number of occurred interrupts, should never exceed 1!
    struct cdev cdev;                       // characted device structure
};

// GLOBAL VARIABLES ========================================

int osif_major = OSIF_MAJOR;
int osif_minor = 0;
int osif_numslots = OSIF_NUMSLOTS;

module_param(osif_major, int, S_IRUGO);
module_param(osif_numslots, int, S_IRUGO);

MODULE_AUTHOR("Enno Luebbers <enno.luebbers@upb.de>");
MODULE_LICENSE("GPL");   // since we use DCR infrastructure


// MACROS ==================================================

// for debugging
#define DCR_ADDR(dcrhost) (dcrhost.type == DCR_HOST_MMIO ? \
                           dcrhost.host.mmio.base :        \
                           dcrhost.host.native.base)

// FILE OPERATIONS =============================================

///
/// Open OSIF device.
///
/// This function also looks up the osif_dev associated with the inode,
/// an makes it available for other methods.
///
int osif_open(struct inode *inode, struct file *filp)
{
    struct osif_dev *dev; /* device information */

    dev = container_of(inode->i_cdev, struct osif_dev, cdev);
    filp->private_data = dev; /* for other methods */

    PDEBUG("opening slot %d at 0x%08X\n", 
            dev->slot_num, DCR_ADDR(dev->dcr_host));

    // report any unhandled IRQs in the meantime
    if (dev->irq_count > 0) {
        printk(KERN_WARNING "osif: there have been %d IRQs\n", dev->irq_count);
    }

    // TODO: Reset OSIF and hardware thread?
    // If so, also reset the next_read and next_write variables!

    return 0;          /* success */
}


///
/// Read data from OSIF.
///
/// This function performs DCR reads on the OSIF registers. Every registers has
/// 32 bits.
/// Although all OSIF registers should be read at once (in the correct order),
/// we allow for shorter reads (down to single bytes), in case the user application 
/// wants to read the register contents one by one.
/// Reads that exceed the last OSIF registers are truncated. The application can
/// detect this condition by examining the number of read bytes. This, though,
/// should not really happen.
/// A warning is printed if the file position jumps unexpectedly (e.g. when not
/// reading the registers consecutively).
///
///
/// \param filp     Pointer to kernel file structure
/// \param buf      Pointer to _user-space_ buffer
/// \param count    Number of bytes to read
/// \param f_pos    Offset into the DCR registers in bytes
///
/// \return         The number of written bytes
///
ssize_t osif_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos) {
    struct osif_dev *dev = filp->private_data;
    size_t to_copy = 0, remaining = 0;
    ssize_t retval;
    int i;

    PDEBUG("trying to read %d bytes from pos %ld\n",
            count, (unsigned long int)*f_pos);

    // block if there is no new data
    // (i.e. there have been no interrupts)
    while (dev->irq_count == 0) {
        // return if nonblocking operation is requested
        // FIXME: an alternative would be to break, this would read the
        // DCR data even if it is old
        if (filp->f_flags & O_NONBLOCK) 
            return -EAGAIN;

        PDEBUG("osif: read with no new data, blocking\n");

        // block; if interrupted, let fs layer handle it
        if (wait_event_interruptible(dev->read_queue, (dev->irq_count > 0)))
            return -ERESTARTSYS;
    }

    // okay, there seems to be data...

    // check for non-consecutive accesses (might be unneccessary)
    if (dev->next_read != *f_pos)
        printk(KERN_WARNING "osif: non-consecutive read access, possible data loss!\n");

    // calculate remaining bytes in read buffer
    remaining = sizeof(dev->read_buffer) - *f_pos;
    if (count > remaining) 
        to_copy = remaining;
    else
        to_copy = count;

    // if this operation reads all remaining data,
    // clear irq_count, so that we will block next time
    // until an interrupt occurs
    if (to_copy == remaining) {
        PDEBUG("clearing IRQ count\n");
        dev->irq_count = 0;
    }

    // access to offset 0 means read from DCR
    // this can potentially generate an interrupt
    if (*f_pos == 0) {
        PDEBUG("reading from DCR\n");
        for (i = 0; i < OSIF_DCR_READSIZE; i++) {
            dev->read_buffer[i] = dcr_read(dev->dcr_host, i);
                PDEBUG("read 0x%08X from register %d (DCR address 0x%08X)\n", dev->read_buffer[i], i, DCR_ADDR(dev->dcr_host) + i);
        }
    }
    
    // bytewise copy data from read buffer to user space
    if (copy_to_user(buf, &((char *)(dev->read_buffer))[*f_pos], to_copy))
        retval = -EFAULT;
    else
        retval = to_copy;
    
    // update file position pointer, wrap to 0 if beyond end of read buffer
    *f_pos += to_copy;
    if (*f_pos >= sizeof(dev->read_buffer)) {
        *f_pos = 0;
    }

    // update expected next read position
    dev->next_read = *f_pos;

    return retval;
}


///
/// Write to OSIF registers.
///
/// This function performs DCR writes on the OSIF registers. Every OSIF 
/// register is 32 bits in length
/// Again, we support byte-wise reads, though all registers should be
/// read together. See osif_read() for details.
///
/// \param filp     Pointer to kernel file structure
/// \param buf      Pointer to _user-space_ buffer
/// \param count    Number of bytes to write
/// \param f_pos    Offset into the DCR registers in bytes
///
/// \return         The number of written bytes
///
ssize_t osif_write(struct file *filp, const char __user *buf, size_t count, loff_t *f_pos) {
    struct osif_dev *dev = filp->private_data;
    size_t to_copy = 0, remaining = 0;
    ssize_t retval;
    int i;

    PDEBUG("trying to write %d bytes to pos %ld\n",
            count, (unsigned long int)*f_pos);

    if (dev->next_write != *f_pos)
        printk(KERN_WARNING "osif: non-consecutive write access, possible data loss!\n");

    // calculate how many bytes can be written max.
    remaining = sizeof(dev->write_buffer) - *f_pos;

    if (count >= remaining) 
        to_copy = remaining;
    else
        to_copy = count;

    // bytewise copy data from user space to write buffer
    if ((retval = copy_from_user(&((char *)(dev->write_buffer))[*f_pos], buf, to_copy))){
        retval = -EFAULT;
    }
    else {
        retval = to_copy;
    }

    // update file position pointer, wrap to 0 if beyond end of write buffer
    *f_pos += to_copy;
    if (*f_pos >= sizeof(dev->write_buffer)) {
        *f_pos = 0;
        // if the buffer is full, we need to write to dcr 
        PDEBUG("writing to DCR\n");
        for (i = 0; i < OSIF_DCR_WRITESIZE; i++) {
            dcr_write(dev->dcr_host, i, dev->write_buffer[i]);
            PDEBUG("wrote 0x%08X to register %d (DCR address %d)\n", dev->write_buffer[i], i, DCR_ADDR(dev->dcr_host) + i);
        }
    }

    dev->next_write = *f_pos;

    return retval;
}


///
/// Close OSIF device.
///
int osif_release(struct inode *inode, struct file *filp) {

#ifdef OSIF_DEBUG
    struct osif_dev *dev = filp->private_data;
#endif

    PDEBUG("closing slot %d at 0x%08X\n",
            dev->slot_num, DCR_ADDR(dev->dcr_host));

    return 0;
}



///
/// Interrupt handler
///
irqreturn_t osif_interrupt(int irq, void *dev_id) {

    struct osif_dev *dev = dev_id;

    // increment IRQ counter
    dev->irq_count++;

    // TODO: handle concurrency!

    // wake up blocking processes
    wake_up_interruptible(&dev->read_queue);

    return IRQ_HANDLED;

}



//
// INITIALIZATION FUNCTIONS ======================================
//

///
/// File operation struct
/// 
static struct file_operations osif_fops = {
    .owner = THIS_MODULE,
    .read  = osif_read,
    .write = osif_write,
    .open = osif_open,
    .release = osif_release
};


/// 
/// Set up the char_dev structure for this device.
///
static void osif_setup_cdev(struct osif_dev *dev, int index)
{
    int err, devno = MKDEV(osif_major, osif_minor + index);
    
    cdev_init(&dev->cdev, &osif_fops);
    dev->cdev.owner = THIS_MODULE;
    dev->cdev.ops = &osif_fops;
    err = cdev_add(&dev->cdev, devno, 1);
    /* Fail gracefully if need be */
    if (err)
        printk(KERN_NOTICE "Error %d adding osif%d", err, index);
    printk(KERN_INFO "osif: registered osif%d at 0x%08X irq %d\n",
            index, DCR_ADDR(dev->dcr_host), dev->irq);
    
}


///
/// Probe device parameters from OF device tree
///
/// This also involves allocating the osif_dev structs for our devices, and
/// initializing them.
///
static int __devinit
osif_of_probe( struct of_device *ofdev, const struct of_device_id *match) {

    struct osif_dev *osif_inst;
    struct resource r_irq_struct;
    struct resource *r_irq = &r_irq_struct;

    int start;
    int result = 0;

    PDEBUG("of_probe %s\n", ofdev->node->full_name);

    PDEBUG("probing IRQ\n");
    // lookup interrupt number
    result = of_irq_to_resource(ofdev->node, 0, r_irq);
    if(result == NO_IRQ) {
        printk( KERN_WARNING "osif: no IRQ found.\n");
        goto fail;
    }
    PDEBUG("IRQ = %lu\n", (unsigned long)r_irq->start);

    // allocate device data (TODO: does this need to be thread-safe?)
    osif_inst = kmalloc(sizeof(struct osif_dev), GFP_KERNEL);

    if (!osif_inst) {
        result = -ENOMEM;
        goto fail;  /* Make this more graceful */
    }
    memset(osif_inst, 0, sizeof(struct osif_dev));

    PDEBUG("probing DCR\n");
    // lookup dcr base address
    start = dcr_resource_start(ofdev->node, 0);
    osif_inst->dcr_len = dcr_resource_len(ofdev->node, 0);
    osif_inst->dcr_host = dcr_map(ofdev->node, start, osif_inst->dcr_len);
    if (!DCR_MAP_OK(osif_inst->dcr_host)) {
        printk( KERN_ERR "osif: invalid dcr address\n" );
        result = -ENODEV;
        goto fail1;
    }
    PDEBUG("DCR from %u, len %u\n", start, osif_inst->dcr_len);

    // register device data with device
    dev_set_drvdata(&ofdev->dev, osif_inst);

    /* Initialize device data */
    osif_inst->slot_num = 0;   // FIXME: this is hardcoded, can we extract this from ofdev?
    
    // request interrupt
    result = request_irq(r_irq->start, osif_interrupt, 0, "osif", osif_inst);
    if (result) {
        printk(KERN_WARNING "osif: can't get assigned IRQ %lu\n", (unsigned long)r_irq->start);
        goto fail2;
    }
    osif_inst->irq      = r_irq->start;
    osif_inst->next_read = 0;
    init_waitqueue_head(&osif_inst->read_queue);
    osif_inst->irq_count = 0;
    init_MUTEX(&osif_inst->sem);
    osif_setup_cdev(osif_inst, osif_inst->slot_num); // FIXME minor number

    // TODO: add to some kind of list for later reference?
    //       or is the reference via the filp->private_data (in open()) and 
    //       the dev_set_drvdata() enough?

    return 0;

fail2:
    dcr_unmap(osif_inst->dcr_host, osif_inst->dcr_len);
fail1:
    kfree(osif_inst);
fail:
    return result;
}

///
/// Remove device
///
/// This involves freeing used IRQs, character devices, DCR buses and all
/// occupied memory
///
static int __devexit osif_of_remove( struct of_device *ofdev ) {
    struct osif_dev *osif_inst = dev_get_drvdata(&ofdev->dev);
    
    printk(KERN_INFO "osif: unregistering osif slot %d\n", osif_inst->slot_num);

    // free the IRQ
    free_irq(osif_inst->irq, osif_inst);

    // unregister char device
    cdev_del(&osif_inst->cdev);

    // unmap DCR bus
    dcr_unmap(osif_inst->dcr_host, osif_inst->dcr_len);

    // free device structure
    kfree(osif_inst);

    // unregister device data
    dev_set_drvdata(&ofdev->dev, NULL);

    return 0;
}

/* Match table for of_platform binding */
static const struct of_device_id __devinitconst osif_of_match[] = {
        { .compatible = "xlnx,osif-2.01.a", .data = NULL },
        { .compatible = "xlnx,plb-osif-2.01.a", .data = NULL},
	{},
};

static struct of_platform_driver osif_of_driver = {
        .owner = THIS_MODULE,
	.name = "osif",
        .match_table = osif_of_match,

	.probe = osif_of_probe,
	.remove = __devexit_p(osif_of_remove),
        .driver = {
            .name = "osif"
        }
};

///
/// Initialize module.
///
/// This involves aquiring a major device number, 
/// and registering the open-firmware-based driver.
///
static int __init osif_init(void) {
    int result;
    dev_t dev = 0;

    PDEBUG("registering device\n");

    if (osif_major) {
        dev = MKDEV(osif_major, osif_minor);
        result = register_chrdev_region(dev, osif_numslots, "osif");
    } else {    // dynamic allocation of device numbers
        result = alloc_chrdev_region(&dev, osif_minor, osif_numslots, "osif");
        osif_major = MAJOR(dev);
    }
    if (result < 0) {
        printk(KERN_WARNING "osif: can't get major %d\n", osif_major);
        return result;
    }

    PDEBUG("registered up to %d char devices with major %d\n", osif_numslots, osif_major);

    result = of_register_platform_driver(&osif_of_driver);
    if (result) {
        printk(KERN_ERR "osif: of_register_platform_driver() failed\n");
        return result;
    }
    
    return result;
}

///
/// Clean up on unload.
///
/// This involves unregistering all character devices and
/// freeing the associated osif_dev structures.
///
static void osif_cleanup(void) {
    dev_t devno = MKDEV(osif_major, osif_minor);

    unregister_chrdev_region(devno, osif_numslots);

    PDEBUG("unregistered all char devices\n");

    of_unregister_platform_driver(&osif_of_driver);

    PDEBUG("unregistered of platform driver\n");
}

module_init(osif_init);
module_exit(osif_cleanup);

