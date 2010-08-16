#!/usr/bin/perl -w
#
# measure2gnuplot.pl: Seperates Andreas' measurements for the FPL paper into
#                     single files parseable by gnuplot


# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}


sub usage() {
	print "Usage: mkhist.pl <file.dat>\n";
}


if ($#ARGV < 0) {
	usage();
	die;
}

$filename = $ARGV[0];



# read header line
open(DATFH, "< $filename");
$caption = <DATFH>;
chomp $caption;
$caption = trim($caption);
$caption = substr($caption, 1);	# trim the leading '#'
$caption = trim($caption);

@captions = split(/ +/, $caption);

#ignore first column
#shift @captions;

$num = $#captions + 1;

@min = ();
@max = ();
@avg = ();

# initialize data and histogram arrays
# initialize min and max arrays
for ($i = 0; $i < $num; $i++) {
	push(@data, []);	# erzeuge neue Liste und speichere Referenz
	push(@histograms, {});
	$min[$i] = -1;		# we work only with positive values;
	$max[$i] = 0;
	$avg[$i] = 0;
	$dev[$i] = 0;
}

# read data lines
@lines = <DATFH>;
close(DATFH);


# read values from @lines, store them in corresponding data arrays
# and calculate min and max values.
foreach $line (@lines) {
	chomp $line;
	$line = trim($line);
	
	@values = split(/[ \t]+/, $line);
	#ignore first column
#	shift @values;
	
	for ($i = 0; $i < $num; $i++) {
		push(@{$data[$i]}, $values[$i]);
		if ($min[$i] == -1 || $min[$i] > $values[$i]) {
			$min[$i] = $values[$i];
		}
		if ($max[$i] < $values[$i]) {
			$max[$i] = $values[$i];
		}
		$avg[$i] += $values[$i];
	}
}

# calculate average
for ($i = 0; $i < $num; $i++) {
	$avg[$i] = $avg[$i] / ($#lines+1);
}

# now we have the values of the $num columns in seperate lists

# calculate standard deviation
for ($i = 0; $i < $num; $i++) {
	$dev[$i] = 0;
	foreach $value (@{$data[$i]}) {
		$dev[$i] = $dev[$i] + ($value - $avg[$i])*($value - $avg[$i]);
	}
	$dev[$i] = sqrt(1/$#lines * $dev[$i]);
}


# generate histogram
for ($i = 0; $i < $num; $i++) {
#	print "Column $i ('". $captions[$i] . "'):\n";
	$column = $captions[$i];
	$basename = $filename;
	$basename =~ s/^.*\///;		# strip directory name
	$basename =~ s/\.dat$//;	# strip .dat extension 

	# save how often the most occuring calue occures (for y scaling)
	$max_occurence = 0;

	foreach $value (@{$data[$i]}) {
		if (exists ${$histograms[$i]}{$value}) {
			${$histograms[$i]}{$value} = ${$histograms[$i]}{$value} + 1;
		} else {
			${$histograms[$i]}{$value} = 1;
		}
		if ($max_occurence < ${$histograms[$i]}{$value}) {
			$max_occurence = ${$histograms[$i]}{$value};
		}
	}

	# write histogram data
	open(FH, "> $basename" . "_$column" . "_histogram.dat");
	print FH "# min: $min[$i], max: $max[$i], avg: $avg[$i], dev: $dev[$i]\n";
	while (($key, $value) = each %{$histograms[$i]}) {
		print FH "$key   $value\n";
	}
	close(FH);
	
	# write gnuplot script
	open(FH, "> $basename" . "_$column" . "_histogram.gp");
	print FH "reset\n";
	print FH "set terminal jpeg\n";
	print FH "set output \"" . $basename . "_" . $column . "_histogram.jpg\"\n";
	print FH "set style data boxes\n";
	print FH "set style fill solid 1.0\n";
	print FH "set boxwidth 0.5\n";
	print FH "set xrange [" . $min[$i] . ":" . $max[$i] . "]\n";
	print FH "set yrange [0:$max_occurence]\n";
	print FH "plot \"$basename" . "_$column" . "_histogram.dat\" title \"" . $basename . "_" . $column . "\" lt rgb \"blue\"\n";
	close(FH);
}

