#!/bin/sh
# *********************************
# Generate SVG Script
#
# Converts a DOT file to SVG (uses URLs)
# *********************************

# Convert DOT file to SVG
dot -Tsvg $1 -o $1.svg
