#!/bin/sh
#
# update_tb.sh: Updates a BFM OSIF testbench with an .sst file
#

TESTBENCH=../pcores/osif_tb_v1_00_c/simhdl/vhdl/osif_tb.vhd

if [ -z $1 ]; then
    echo "No stimulus file given, using 'sample.sst'"
    STIMULUS=sample.sst
fi

if [ ! -f $STIMULUS ]; then
    echo "ERROR: $STIMULUS does not exist!"
    exit -1
fi

if [ ! -f $TESTBENCH ]; then
    echo "ERROR: $TESTBENCH does not exist!"
    exit -1
fi

echo -n "Updating testbench..."
mkbfmtb.py $STIMULUS $TESTBENCH
echo "done"

