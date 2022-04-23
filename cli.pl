#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

use Getopt::Long;
use Pod::Usage;
use Text::CSV_XS;
use POSIX qw( strftime );
use Data::Dumper;

use lib './lib';
use Hits::Stat;
use Hits::Alert;

main();

sub main {
	my ($file, $threshold) = get_opts();

	my ($csv, $fh) = get_csv($file);
	process_csv($csv, $fh, $threshold);
}


sub get_opts {
	my ($file, $threshold) = ('', 10);

	GetOptions(
	    'file=s' => \$file,
	    'threshold=i' => \$threshold,
	);
	$file or pod2usage("Please specify (-f|--file) to work with\n");

	return ($file, $threshold);
}

sub get_csv {
	my ($file) = @_;

	my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
	open my $fh, "<:encoding(utf8)", $file or die "$file: $!";
	$csv->header($fh);

	return ($csv, $fh);
}

sub process_csv {
	my ($csv, $fh, $threshold) = @_;

	my $stat = Hits::Stat->new();
	my $alert = Hits::Alert->new(sec_threshold => $threshold);

	while (my $row = $csv->getline_hr($fh)) {
		$stat->process_row($row);
		$alert->process_row($row);
	}
}