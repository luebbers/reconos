#!/bin/bash
# \file tests_modelsim.sh
#
# Automated simulations for ReconOS primitives
#
# \author     Enno Luebbers   <enno.luebbers@upb.de>
# \date       21.11.2008
#
#---------------------------------------------------------------------------
# %%%RECONOS_COPYRIGHT_BEGIN%%%
# %%%RECONOS_COPYRIGHT_END%%%
#---------------------------------------------------------------------------
#
# Major Changes:
#
# 21.11.2008   Enno Luebbers   File created.

TESTS="condvar mbox mbox_hw mbox_hwsw mutex coop"

for i in $TESTS; do
    make -C $i clean bfmsim
    if [ $? -ne 0 ]; then
        echo "ERROR: simulation failed, stopping."
        exit -1
    fi
done

echo -e "\n\nAll tests completed successfully."
