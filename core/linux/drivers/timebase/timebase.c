///
/// \file timebase.c
///
/// DCR timebase device driver for ReconOS dcr_timebase on Linux 2.6.
///
/// This driver provides a character device (e.g. /dev/timebase) for
/// accessing the dcr_timebase registers from user space.
///
/// \author     Enno Luebbers <enno.luebbers@upb.de>
/// \date       18.03.2008
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
// 18.03.2008   Enno Luebbers   File created
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

//#define __uCLinux__
// DCR access not supported in petalinux
#ifndef __uCLinux__
#include <asm/dcr.h>
#else
#define mtdcr(x, y) PDEBUG("mtdcr() not supported in uCLinux!\n")
#define mfdcr(x)    PDEBUG("mfdcr() not supported in uCLinux!\n")
#endif

#include "xparameters.h"
#include "timebase.h"
#include "params.h"

// TYPE DEFINITIONS ========================================

struct timebase_dev {
    unsigned int read_buffer[TIMEBASE_DCR_READSIZE];  // buffer for DCR reads
//    unsigned int write_buffer[OSIF_DCR_WRITESIZE]; // buffer for DCR writes
    loff_t next_read;                       // next expected read offset
    loff_t next_write;                      // next expected write offset
    unsigned int baseaddr;              // DCR baseaddr of dcr_timebase
    struct semaphore sem;                   // mutual exclusion semaphore
//    wait_queue_head_t read_queue;           // queue for blocking reads
    struct cdev cdev;                       // character device structure
};

// GLOBAL VARIABLES ========================================

int timebase_major = TIMEBASE_MAJOR;
int timebase_minor = 0;
int timebase_baseaddr = TIMEBASE_BASEADDR;
int use_opb2dcr = USE_OPB2DCR;  // detected in params.h
struct timebase_dev *timebase_devices;  // allocated in osif_init

module_param(timebase_major, int, S_IRUGO);
module_param(timebase_baseaddr, int, S_IRUGO);
module_param(use_opb2dcr, int, S_IRUGO);

MODULE_AUTHOR("Enno Luebbers <enno.luebbers@upb.de>");
MODULE_LICENSE("Proprietary");   // for now


// FILE OPERATIONS =============================================

///
/// Open timebase device.
///
/// This function also looks up the timebase_dev associated with the inode,
/// an makes it available for other methods.
///
int timebase_open(struct inode *inode, struct file *filp)
{
    struct timebase_dev *dev; /* device information */

    dev = container_of(inode->i_cdev, struct timebase_dev, cdev);
    filp->private_data = dev; /* for other methods */

    PDEBUG("opening timebase at 0x%08X\n", 
            dev->baseaddr);

    return 0;          /* success */
}


///
/// Read data from timebase.
///
/// This function performs DCR reads on the timebase registers. Every register has
/// 32 bits. For now, we only read the timebase register (offset 1).
/// Although the registers should be read at once (in the correct order),
/// we allow for shorter reads (down to single bytes), in case the user application 
/// wants to read the register contents one by one.
/// Reads that exceed the last register are truncated. The application can
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
ssize_t timebase_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos) {
    struct timebase_dev *dev = filp->private_data;
    size_t to_copy = 0, remaining = 0;
    ssize_t retval;
    int i;

    PDEBUG("trying to read %d bytes from pos %ld\n",
            count, (unsigned long int)*f_pos);

    // check for non-consecutive accesses (might be unneccessary)
    if (dev->next_read != *f_pos)
        printk(KERN_WARNING "timebase: non-consecutive read access, possible data loss!\n");

    // calculate remaining bytes in read buffer
    remaining = sizeof(dev->read_buffer) - *f_pos;
    if (count > remaining) 
        to_copy = remaining;
    else
        to_copy = count;

    // access to offset 0 means read from DCR
    if (*f_pos == 0) {
        PDEBUG("reading from DCR\n");
        for (i = 0; i < TIMEBASE_DCR_READSIZE; i++) {   
            if (use_opb2dcr) {
                dev->read_buffer[i] = in_be32((volatile unsigned*)dev->baseaddr + i + 1);
                PDEBUG("read 0x%08X from register %d (OPB address 0x%08X)\n", dev->read_buffer[i], i, dev->baseaddr + (i + 1)*4);
            } else {
                dev->read_buffer[i] = mfdcr(dev->baseaddr + i + 1);
                PDEBUG("read 0x%08X from register %d (DCR address 0x%08X)\n", dev->read_buffer[i], i, dev->baseaddr + i + 1);
            }
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

/*
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
    if (copy_from_user(&((char *)(dev->write_buffer))[*f_pos], buf, to_copy))
        retval = -EFAULT;
    else
        retval = to_copy;
    
    // update file position pointer, wrap to 0 if beyond end of write buffer
    *f_pos += to_copy;
    if (*f_pos >= sizeof(dev->write_buffer)) {
        *f_pos = 0;
        // if the buffer is full, we need to write to dcr
        PDEBUG("writing to DCR\n");
        for (i = 0; i < OSIF_DCR_WRITESIZE; i++) {
            if (use_opb2dcr) {
                out_be32((volatile unsigned*)dev->baseaddr + i, dev->write_buffer[i]);
                PDEBUG("wrote 0x%08X to register %d (OPB address 0x%08X)\n", dev->write_buffer[i], i, dev->baseaddr + i*4);
            } else {
                mtdcr(dev->baseaddr + i, dev->write_buffer[i]);
                PDEBUG("wrote 0x%08X to register %d (DCR address %d)\n", dev->write_buffer[i], i, dev->baseaddr + i);
            }
        }
    }

    dev->next_write = *f_pos;

    return retval;
}
*/

///
/// Close timebase device.
///
int timebase_release(struct inode *inode, struct file *filp) {

    struct timebase_dev *dev = filp->private_data;

    PDEBUG("closing timebase at 0x%08X\n",
            dev->baseaddr);

    return 0;
}


/*
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
*/


//
// INITIALIZATION FUNCTIONS ======================================
//

///
/// File operation struct
/// 
static struct file_operations timebase_fops = {
    .owner = THIS_MODULE,
    .read  = timebase_read,
//    .write = osif_write,
    .open = timebase_open,
    .release = timebase_release
};


/// 
/// Set up the char_dev structure for this device.
///
static void timebase_setup_cdev(struct timebase_dev *dev, int index)
{
    int err, devno = MKDEV(timebase_major, timebase_minor + index);
    
    cdev_init(&dev->cdev, &timebase_fops);
    dev->cdev.owner = THIS_MODULE;
    dev->cdev.ops = &timebase_fops;
    err = cdev_add(&dev->cdev, devno, 1);
    /* Fail gracefully if need be */
    if (err)
        printk(KERN_NOTICE "Error %d adding timebase", err);
    printk(KERN_INFO "timebase: registered timebase at 0x%08X\n",
            dev->baseaddr);
    
}

///
/// Clean up on unload.
///
/// This involves unregistering all character devices and
/// freeing the associated timebase_dev structures.
///
static void timebase_cleanup(void) {
//    int i;
    dev_t devno = MKDEV(timebase_major, timebase_minor);

    // free the interrupts, if any

    /* Get rid of our char dev entries */
    if (timebase_devices) {
        cdev_del(&timebase_devices[0].cdev);
        printk(KERN_INFO "timebase: timebase unregistered\n");

        kfree(timebase_devices);
    }

    unregister_chrdev_region(devno, 1);

    PDEBUG("unregistered all char devices\n");
}

///
/// Initialize module.
///
/// This involves aquiring a major device number, 
/// allocating the timebase_dev structs for our devices,
/// and initializing them.
///
static int __init timebase_init(void) {
    int result;
//    int i;
    dev_t dev = 0;


    PDEBUG("registering device\n");
    
    if (use_opb2dcr)
        PDEBUG("using OPB2DCR bridge\n");
    else
        PDEBUG("using direct DCR access\n");

    if (timebase_major) {
        dev = MKDEV(timebase_major, timebase_minor);
        result = register_chrdev_region(dev, 1, "timebase");
    } else {    // dynamic allocation of device numbers
        result = alloc_chrdev_region(&dev, timebase_minor, 1, "timebase");
        timebase_major = MAJOR(dev);
    }
    if (result < 0) {
        printk(KERN_WARNING "timebase: can't get major %d\n", timebase_major);
        return result;
    }

    PDEBUG("registered %d char devices with major %d\n", 1, timebase_major);

    // allocate devices
    timebase_devices = kmalloc(1 * sizeof(struct timebase_dev), GFP_KERNEL);
    
    if (!timebase_devices) {
        result = -ENOMEM;
        goto fail;  /* Make this more graceful */
    }
    memset(timebase_devices, 0, 1 * sizeof(struct timebase_dev));


    /* Initialize device. */
    timebase_devices[0].baseaddr = timebase_baseaddr;
    timebase_devices[0].next_read = 0;
    // init_waitqueue_head(&timebase_devices[0].read_queue);
    init_MUTEX(&timebase_devices[0].sem);
    timebase_setup_cdev(&timebase_devices[0], 0);
    

    return 0;
  
fail:
    timebase_cleanup();
    return result;
}

module_init(timebase_init);
module_exit(timebase_cleanup);

