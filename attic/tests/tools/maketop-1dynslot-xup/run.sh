#!/usr/bin/env bash
#
# run tool test
#
TEST=maketop-1dynslot-xup

TOOL=maketop.py
MESS="test.vhd test.vhd.output"
expected_retval=0

# source common test functions
. ../common/test_tools

# check for tools existence
which $TOOL &> /dev/null
if [ ! $? ]; then
    echo_failure
    echo "ERROR: tool '$TOOL' not found."
    exit 1
fi

# clean up possible mess from previous run(s)
rm -f ${MESS} ${TOOL}.log

# run test
cp -f test.vhd.before test.vhd
$TOOL -l layout.lyt test.vhd &> ${TOOL}.log
tail +6 test.vhd > test.vhd.output
retval=$?

# test return value
if [ $? -ne $expected_retval ]; then
    echo_failure
    echo "ERROR: return value '$?' does not match expected ('$expected_retval')."
    exit 2
fi

# test output
diff_vhdl test.vhd.output test.vhd.reference
if [ $? -ne 0 ]; then
    echo_failure
    echo "ERROR: output differs."
    exit 3
fi

echo_success

