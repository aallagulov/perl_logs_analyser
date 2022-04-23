package Hits::Stat;

use strict;
use warnings;
use feature 'say';
 
use Moo;
use POSIX qw( strftime );
use Data::Dumper;

has last_time_range => (
  is  => 'ro',
  writer => 'set_last_time_range',
);

has report_time_range => (
  is  => 'ro',
  writer => 'set_report_time_range',
);

has hits_per_10_secs => (
  is  => 'rw',
  default => => sub { {} }
);

sub process_row {
	my ($self, $row) = @_;

	my $time_range = $self->_get_time_range($row);

	# here we set initial values from the 1st row
	unless ($self->last_time_range) {
		$self->set_last_time_range($time_range);
	}
	unless ($self->report_time_range) {
		$self->set_report_time_range($self->last_time_range - 2);
	}


	$self->add_hit($row, $time_range);

	# we have a lot of unordered records
	# to sum up those records which will came later
	# we will report stats not reactively (for last 10 secs)
	# but with a 10 secs delay (for 10 secs before last 10 secs)
	if ($time_range > $self->last_time_range) {
		$self->set_last_time_range($time_range);
		$self->set_report_time_range($self->last_time_range - 2);
	}

	$self->_get_current_report();
}

sub _get_time_range {
	my ($self, $row) = @_;

	my $time_range = int($row->{date} / 10);
	return $time_range;
}

sub add_hit {
	my ($self, $row, $time_range) = @_;

	my $section = $self->_get_section_from_row($row);
	$self->hits_per_10_secs->{$time_range}{$section}++;
}

sub _get_section_from_row {
	my ($self, $row) = @_;

	# regex to cut "/api" from "POST /api/whatever ..."
	my ($section) = ($row->{request} =~ /[^\/+](\/\w+)/);
	return $section;
}

sub _get_current_report {
	my ($self) = @_;

	if (my $report = $self->hits_per_10_secs->{$self->report_time_range}) {
		$self->_get_report_msg($report);
		delete $self->hits_per_10_secs->{$self->report_time_range};
	}
}

sub _get_report_msg {
	my ($self, $report) = @_;

	my $report_ts = $self->report_time_range;

	my $report_dt_start = $self->_get_report_dt($report_ts*10);
	my $report_dt_end = $self->_get_report_dt(($report_ts+1)*10);
	my $msg = "$report_dt_start - $report_dt_end: Hits stats for routes: ";
	for my $route (sort (keys %$report)) {
		$msg .= sprintf("%s - %d; ", $route, $report->{$route});
	}
	say $msg;
}

sub _get_report_dt {
	my ($self, $ts) = @_;

	# converting from ts to datetime
	return strftime("%Y-%m-%d %H:%M:%S", localtime($ts));
}

1;
