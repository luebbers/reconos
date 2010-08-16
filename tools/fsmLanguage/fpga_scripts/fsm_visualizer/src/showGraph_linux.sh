#!/bin/sh
# *********************************
# Linux Script
#
# Converts a DOT file to JPG
# and opens the JPG for viewing
# *********************************

ext=svg

# Convert DOT file to JPG
dot -T$ext $1 -o $1.$ext

# Open JPG
display $1.$ext
