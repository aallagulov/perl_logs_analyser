#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

use Getopt::Long;
use Text::CSV_XS;
use POSIX qw( strftime );
# use Data::Dumper;

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

	my $hits_per_10_secs = {};
	my $hits = {};

	my ($last_time_range, $report_time_range, $last_ts);

	while (my $row = $csv->getline_hr($fh)) {
		my $time_range = int($row->{date} / 10);

		# here we set initial values from the 1st row
		$last_time_range //= $time_range;
		$report_time_range //= $last_time_range - 2;
		$last_ts //= $row->{date};

		# regex to cut "/api" from "POST /api/whatever ..."
		my ($section) = ($row->{request} =~ /[^\/+](\/\w+)/);
		$hits_per_10_secs->{$time_range}{$section}++;

		# we have a lot of unordered records
		# to sum up those records which will came later
		# we will report stats not reactively (for last 10 secs)
		# but with a 10 secs delay (for 10 secs before last 10 secs)
		if ($time_range > $last_time_range) {
			$last_time_range = $time_range;
			$report_time_range = $last_time_range - 2;
		}

		if (my $report = $hits_per_10_secs->{$report_time_range}) {
			my $report_dt_start = strftime("%Y-%m-%d %H:%M:%S", localtime($report_time_range*10));
			my $report_dt_end = strftime("%Y-%m-%d %H:%M:%S", localtime(($report_time_range+1)*10));
			my $msg = "$report_dt_start - $report_dt_end: Hits stats for routes: ";
			for my $route (sort (keys %$report)) {
				$msg .= sprintf("%s - %d; ", $route, $report->{$route});
			}
			say $msg;

			delete $hits_per_10_secs->{$report_time_range};
		}

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