#!/usr/bin/perl -w
#
# text2dat.pl: Parses textfiles to create gnuplot input files
#
# This script is usually used for creating histograms for ReconOS benchmark
# outputs. There can be multiple benchmarks in the input file.
#
# A "benchmark" is marked as follows:
#
#
#                ... some arbitrary text not starting with BEGIN ...
#
#                BEGIN your_benchmark_name_here
#                # col1_header    col2_header     col3_header
#                0                42.3            22.7
#                1                14.6            69.4
#                ...
#                999              53.6            25.2
#                END
#
# Everything between (and excluding) BEGIN and END is copied into a file
# named your_benchmark_name_here.dat, as input to gnuplot. Also, for evey
# column xxx, a file named your_benchmark_here_xxx.gp is created, which will
# plot the data in the column if called with gnuplot.


# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub usage() {
	print "Usage: text2dat.pl < <text_file.txt>\n"
}

# read input file
@lines = <STDIN>;

$state = "text";

foreach $line (@lines) {
	chomp $line;
	$line = trim($line);
	
	if ($state eq "text") {
		if ($line =~ /^BEGIN\s+(\w+)/) {
			$benchname = $1;
			open(FH, "> $benchname" . ".dat");
			$state = "benchmark";
		}
	} elsif ($state eq "benchmark") {
		if ($line =~ /^END/) {
			close(FH);
			$state = "text";
		} else {
			print FH $line . "\n";
		}
	}
}
