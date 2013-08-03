# length.pl
# Tested with perl v5.14.3 on Windows
# Author: Ted Zhang
# Email ted.g.zhang@live.com
use strict;

# Entry of this script
main:run();

package main;

use Getopt::Long;
use Scalar::Util qw(looks_like_number);

# Switch to control whether print debug message
my $DEBUG_MODE = "off";

# Map of the plurs and singular
my %plurs_map = ();

# Hash of the units we parsed
my %units = ();

# Array of the results
my @results;

# Print the usage of this script
sub usage
{
    my $usage =<<EOT;
$0 [options]
    -help: display usage
    -inputfile: path of input flie
EOT
;
    print "\n$usage\n";
    return;
}

sub parse_units
{
    my $rc = 0;
    my $content = shift;
    my $nr_tokens = undef;
    my @records = undef;
    my @unit = undef;
    my @meter = undef;

    @records = split("=", $content);
    $nr_tokens = @records;
    if ($nr_tokens != 2) {
	print("Invalid line: $content\n");
	$rc = -1;
	goto parse_units_exit;
    }

    @unit = split(" ", $records[0]);
    $nr_tokens = @unit;
    if ($nr_tokens != 2) {
	print("Invalid line: $content\n");
	$rc = -1;
	goto parse_units_exit;
    }

    @meter = split(" ", $records[1]);
    $nr_tokens = @meter;
    if ($nr_tokens != 2) {
	print("Invalid line: $content\n");
	$rc = -1;
	goto parse_units_exit;
    }

    # Insert the unit to meter value into the global hash
    if ($DEBUG_MODE eq "on") {
	print("$unit[1]:$meter[0]\n");
    }

    $units{$unit[1]} = $meter[0];

parse_units_exit:

    return $rc;
}

sub process_items
{
    my $rc = 0;
    my $content = shift;
    my $value = undef;
    my $result = "0";
    my $token = undef;
    my $nr_tokens = 0;
    my @tokens = split(" ", $content);
    
    $nr_tokens = @tokens;
    while ($nr_tokens > 0) {
	$token = pop(@tokens);
	if (looks_like_number($token)) {
	    $value = $value * $token;
	} elsif ($token eq '+' ) {
	    $result = $result + $value;
	} elsif ($token eq '-') {
	    $result = $result - $value;
	} else {
	    if (!defined($units{$token})) {
		$token = $plurs_map{$token};
		if (!defined($token)) {
		    print "Invalid unit: $token\n";
		    $rc = -1;
		    goto process_items_exit;
		}
	    }
	    
	    $value = $units{$token};
	}
	$nr_tokens = @tokens;
    }

    # We don't expect a operator at the beginning of a line, so need to
    # add the last value
    $result = $result + $value;

    push(@results, $result);

    if ($DEBUG_MODE eq "on") {
	print("$result\n");
    }

process_items_exit:

    return;
}

sub process_file
{
    my $rc = 0;
    my $fd = shift;
    my $line = undef;
    my $units_parsed = 0;

    while (!eof($fd)) {
	$line = readline($fd);
	defined($line) or die "readline failed: $!\n";
	if ($units_parsed == 0) {
	    if ($line eq "\n") {
		# We have parsed all the unites, left of the file 
		# should all be items need to be processed
		$units_parsed = 1;
	    } else {
		$rc = parse_units($line);
		if ($rc != 0) {
		    goto process_file_exit;
		}
	    }
	} else {
	    # The line should contain at least a number, a whitespace
	    # and a letter if it is a valid line
	    if (length($line) > 3) {
		$rc = process_items($line);
		if ($rc != 0) {
		    goto process_file_exit;
		}
	    } else {
		if ($DEBUG_MODE eq "on") {
		    print("Unable to process: $line");
		}
	    }
	}
    }

process_file_exit:

    return;
}

sub print_results
{
    my $index = undef;
    my $result = undef;
    my $nr_results = undef;

    open(FILEHANDLE, ">", "output.txt") or die "Unable to open output.txt: $!\n";

    print(FILEHANDLE "ted.g.zhang\@live.com\n");
    print(FILEHANDLE "\n");

    $nr_results = @results;
    for ($index = 0; $index < ($nr_results - 1); $index++) {
	printf(FILEHANDLE "%.2f m\n", $results[$index]);
    }

    # For the last result, we don't print the newline
    printf(FILEHANDLE "%.2f m", $results[$index++]);
}

# Run the task
sub run
{
    my $rc = 0;
    my $die_msg = undef;
    my %args = ();

    unless (GetOptions(\%args, 'inputfile=s', 'help', 'debug')) {
	usage();
	$rc = -1;
	goto out;
    }

    if (defined($args{help}) || !defined($args{inputfile})) {
	usage();
	$rc = -1;
	goto out;
    }

    if (defined($args{debug})) {
	$DEBUG_MODE = "on";
    }

    # Initialize the plurs_map
    %plurs_map = (
	miles => "mile",
	yards => "yard",
	inches => "inch",
	feet => "foot",
	faths => "fath",
	furlongs => "furlong"
	);

    open(FILEHANDLE, "<", $args{inputfile}) or die "Unable to open: $args{inputfile}: $!\n";
    $rc = process_file(*FILEHANDLE);
    close(FILEHANDLE);
    if ($rc != 0) {
	print("Unable to process file\n");
	goto out;
    }

    # Output of this scripts
    print_results();
    
out:
    
    exit $rc;
}
