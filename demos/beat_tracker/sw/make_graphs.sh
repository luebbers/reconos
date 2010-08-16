#!/bin/bash

# 1. draw graph with gnuplot
cd partitionings/madness
sh make_graphs.sh
cp measurements.pdf ../../measurements_madness.pdf


cd ../../
