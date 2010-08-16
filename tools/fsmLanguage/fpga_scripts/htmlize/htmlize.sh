#!/bin/sh
# *********************************************
# htmlize
#
# Script used to turn a text file into HTML
# *********************************************

# Transform tabs into a set of non-breaking spaces
sed -e "s/\t/\&nbsp;\&nbsp;\&nbsp;\&nbsp;/g" $1 > $1.temp

# Add <br> to the end of every line
sed -e "s/$/<br>/g" $1.temp > $1.temp2

# Generate HTML header file
echo "
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<HTML>
<HEAD>
 <TITLE> $1 </TITLE>
 <STYLE type="text/css">
  BODY { background: white; color: black}
  A:link { color: red }
  A:visited { color: maroon }
  A:active { color: fuchsia }
 </STYLE>
</HEAD>
<BODY> " > $1.begin

# Generate HTML footer file
echo "
</BODY>
</HTML>
" > $1.end

# Concatenate all files to form the HTML file
cat $1.begin $1.temp2 $1.end > $1.html

# Remove intermediate files
rm -rf $1.temp $1.temp2 $1.begin $1.end



