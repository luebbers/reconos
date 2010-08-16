#!/bin/bash

# parameter: filename of input file (has to be in /input-folder)

# 1. extract results from minicom input file
./evaluate.py $1

# 2. draw graph
sh make_graphs.sh
