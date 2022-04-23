package Hits::Alert;

use strict;
use warnings;
use feature 'say';

use Moo;
use POSIX qw( strftime );
use Data::Dumper;

has sec_threshold => (
  is  => 'ro',
  default => => 10
);

has alert_expiration => (
  is  => 'ro',
  default => => 120
);

has alert_threshold => (
  is  => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    return $self->sec_threshold * $self->alert_expiration;
  },
);

has is_alerting => (
  is  => 'rw',
  default => => 0
);

has last_ts => (
  is  => 'ro',
  writer => 'set_last_ts',
);

has hits => (
  is  => 'rw',
  default => sub { {} }
);

has hits_120_sum => (
  is  => 'rw',
  default => 0
);

sub process_row {
  my ($self, $row) = @_;

  # here we set initial values from the 1st row
  unless ($self->last_ts) {
    $self->set_last_ts($row->{date});
  }

  $self->_add_hit($row->{date});
  $self->_expire_old_hits($row->{date});
  $self->_check_alert($row->{date});

  $self->set_last_ts($row->{date});
}

sub _add_hit {
  my ($self, $row_ts) = @_;

  $self->hits->{$row_ts}++;
  # die Dumper($self);
  $self->hits_120_sum($self->hits_120_sum + 1);
}

sub _expire_old_hits {
  my ($self, $row_ts) = @_;

  # we need to clean up all old hits
  # even if we had some silent seconds w/o requests
  # so we check the difference between last 2 rows' timestamps
  # and clean all the corresponding old hit counters
  for my $i (0 .. $row_ts - $self->last_ts) {
    my $expired_ts = $row_ts - 120 - $i;
    if (my $old_hits = $self->hits->{$expired_ts}) {
      $self->hits_120_sum($self->hits_120_sum - $old_hits);

      delete $self->hits->{$expired_ts};
    }
  }
}

sub _check_alert {
  my ($self, $ts) = @_;

  if ($self->is_alerting) {
    if ($self->hits_120_sum < $self->alert_threshold) {
      $self->is_alerting(0);
      $self->_get_report_msg($ts);
    }
  } else {
    if ($self->hits_120_sum > $self->alert_threshold) {
      $self->is_alerting(1);
      $self->_get_report_msg($ts);
    }
  }
}

sub _get_report_msg {
  my ($self, $ts) = @_;

  my $dt = $self->_get_report_dt($ts);
  my $msg_main = $self->is_alerting ?
    "!!! HIGH TRAFFIC GENERATED ALERT :" :
    "!!! ALERT RECOVERED :";
  say sprintf(
    "%s: %s %d hits for 2 minutes < %d threshold !!!",
    $dt,
    $msg_main,
    $self->hits_120_sum,
    $self->alert_threshold
  );
}

sub _get_report_dt {
  my ($self, $ts) = @_;

  # converting from ts to datetime
  return strftime("%Y-%m-%d %H:%M:%S", localtime($ts));
}

1;
