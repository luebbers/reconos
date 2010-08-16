#!/bin/sh
# *********************************
# Apple OS X Script
#
# Converts a DOT file to PDF
# and opens the PDF for viewing
# *********************************

# Convert DOT file to PDF
dot -Tpdf $1 -o $1.pdf

# Open PDF
open $1.pdf
