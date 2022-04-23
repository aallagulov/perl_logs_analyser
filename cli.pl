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

	my $threshold_120 = $threshold * 120;
	my $hits_120_sum = 0;
	my $is_alerting = 0;

	my $hits = {};

	my ($last_ts);

	my $stat = Hits::Stat->new();

	while (my $row = $csv->getline_hr($fh)) {
		$last_ts //= $row->{date};

		$stat->process_row($row);

		$hits->{$row->{date}}++;
		$hits_120_sum++;

		# we need to clean up all old hits
		# even if we had some silent seconds w/o requests
		# so we check the difference between last 2 rows' timestamps
		# and clean all the corresponding old hit counters
		for my $i (0 .. $row->{date} - $last_ts) {
			my $expired_ts = $row->{date} - 120 - $i;
			if (my $old_hits = $hits->{$expired_ts}) {
				$hits_120_sum -= $old_hits;

				delete $hits->{$expired_ts};
			}
		}

		if ($is_alerting) {
			if ($hits_120_sum < $threshold_120) {
				$is_alerting = 0;
				my $dt = strftime("%Y-%m-%d %H:%M:%S", localtime($row->{date}));
				say "$dt: !!! ALERT RECOVERED : $hits_120_sum hits for 2 minutes < $threshold_120 threshold !!!"
			}
		} else {
			if ($hits_120_sum > $threshold_120) {
				$is_alerting = 1;
				my $dt = strftime("%Y-%m-%d %H:%M:%S", localtime($row->{date}));
				say "$dt: !!! HIGH TRAFFIC GENERATED ALERT : $hits_120_sum hits for 2 minutes > $threshold_120 threshold !!!"
			}
		}

		$last_ts = $row->{date};
	}
}