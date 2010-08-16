#!/usr/bin/env bash

TDIR=pr_demo_generated

SW_FILES=src/sw/*
HW_FILES=src/hw/*
PRJ_FILE=src/*.rprj
HW_THREADS="add sub"

reconos_mkprj.py $TDIR

cp $PRJ_FILE $TDIR
cp $SW_FILES $TDIR/sw
cp $HW_FILES $TDIR/hw
cd $TDIR/hw/hwthreads
for hwt in $HW_THREADS; do
    reconos_addhwthread.py $hwt $hwt ../../../src/$hwt.vhd
done

