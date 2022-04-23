use strict;
use warnings;
use feature 'say';

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Hits::Stat;
use Hits::Alert;

for my $case (
	{
		request => 'GET /api/user HTTP/1.0',
		section => '/api'
	},
	{
		request => 'POST /api/help HTTP/1.0',
		section => '/api'
	},
	{
		request => 'GET /report HTTP/1.0',
		section => '/report'
	},
	{
		request => 'POST /report/subreport/uberreport HTTP/2.0',
		section => '/report'
	},
)
{
	my $row = {request=>$case->{request}};
	is(Hits::Stat->_get_section_from_row($row), $case->{section});
}

done_testing();