#!/usr/bin/perl -w
#
# dat2gp: Generates gnuplot scripts (*.gp) from data files (*.dat).
#
# The first line of the data file must start with a '#' and contain the column headers.
#

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub usage() {
	print "Usage: dat2gp.pl <file.dat>\n";
}


if ($#ARGV < 0) {
	usage();
	die;
}

$filename = $ARGV[0];

# read header line
open(DATFH, "< $filename");
$headerline = <DATFH>;
close(DATFH);
chomp $headerline;
$headerline = trim($headerline);
$headerline = substr($headerline, 1);	# trim the leading '#'
$headerline = trim($headerline);

@captions = split(/ +/, $headerline);

$i = 1;

foreach $column (@captions) {
	$basename = $filename;
	$basename =~ s/^.*\///;		# strip directory name
	$basename =~ s/\.dat$//;	# strip .dat extension 
	open(FH, "> $basename" . "_$column" . ".gp");
	print FH "reset\n";
	print FH "set terminal jpeg\n";
	print FH "set output \"" . $basename . "_" . $column . ".jpg\"\n";
	print FH "plot \"$filename\" using " . $i . " title \"" . $basename . "_" . $column . "\"\n";
	close(FH);
	$i++;
}
