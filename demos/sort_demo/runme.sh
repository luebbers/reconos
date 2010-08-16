#!/usr/bin/env bash

TDIR=sort_demo_generated

SW_FILES=src/sw/*
HW_FILES=src/hw/*
PRJ_FILE=src/*.rprj

reconos_mkprj.py $TDIR

cp $PRJ_FILE $TDIR
cp $SW_FILES $TDIR/sw
#cp $HW_FILES $TDIR/hw
cd $TDIR/hw/hwthreads
reconos_addhwthread.py sort8k sort8k ../../../src/bubble_sorter.vhd ../../../src/sort8k.vhd 

