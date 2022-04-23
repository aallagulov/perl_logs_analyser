package Hits;

use strict;
use warnings;

use Moo;
use POSIX qw( strftime );

sub _get_report_dt {
  my ($self, $ts) = @_;

  # converting from ts to datetime
  return strftime("%Y-%m-%d %H:%M:%S", localtime($ts));
}

1;
