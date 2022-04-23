use strict;
use warnings;
use feature 'say';

use Test::More;
use Test::Output;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Hits::Stat;


# some unit tests for a method with regex

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
	{
		request => '/api',
		section => undef
		# there is no http method
	},
)
{
	my $row = {request=>$case->{request}};
	is(Hits::Stat->_get_section_from_row($row), $case->{section}, 'section parsing works ok');
}

# some functional tests

{
    my $rows = [
    	{date=>'0',request=>'GET /api', stdout => ''},
    	{date=>'1',request=>'GET /api', stdout => ''},
    	{date=>'2',request=>'GET /api', stdout => ''},
    	{date=>'3',request=>'GET /api', stdout => ''},
    	{date=>'4',request=>'GET /api', stdout => ''},
    	{date=>'5',request=>'GET /api', stdout => ''},
    	{date=>'6',request=>'GET /api', stdout => ''},
    	{date=>'7',request=>'GET /api', stdout => ''},
    	{date=>'8',request=>'GET /api', stdout => ''},
    	{date=>'9',request=>'GET /api', stdout => ''},
    	{date=>'10',request=>'GET /api', stdout => ''},
    	{date=>'9',request=>'GET /api', stdout => ''},
    	{date=>'8',request=>'GET /api', stdout => ''},
    	{date=>'7',request=>'GET /api', stdout => ''},
    	{date=>'11',request=>'GET /api', stdout => ''},
    	{date=>'12',request=>'GET /api', stdout => ''},
    	{date=>'13',request=>'GET /api', stdout => ''},
    	{date=>'14',request=>'GET /api', stdout => ''},
    	{date=>'15',request=>'GET /api', stdout => ''},
    	{date=>'16',request=>'GET /api', stdout => ''},
    	{date=>'17',request=>'GET /api', stdout => ''},
    	{date=>'18',request=>'GET /api', stdout => ''},
    	{date=>'19',request=>'GET /api', stdout => ''},
    	{date=>'20',request=>'GET /api', stdout => "1970-01-01 03:00:00 - 1970-01-01 03:00:10: Hits stats for routes: /api - 13; \n"},
    	{date=>'29',request=>'GET /help', stdout => ''},
    	{date=>'30',request=>'GET /api', stdout => "1970-01-01 03:00:10 - 1970-01-01 03:00:20: Hits stats for routes: /api - 10; \n"},
    	{date=>'40',request=>'GET /api', stdout => "1970-01-01 03:00:20 - 1970-01-01 03:00:30: Hits stats for routes: /api - 1; /help - 1; \n"},
    	{date=>'1000',request=>'GET /api', stdout => ""}, # we missed some old stat, because of too big delay between logs
    ];
	my $stat = Hits::Stat->new();
	for my $row (@$rows) {
		stdout_is(
           sub { $stat->process_row($row)},
           $row->{stdout},
           'Test STDOUT'
        );
        say Dumper($stat);
	}
}


done_testing();