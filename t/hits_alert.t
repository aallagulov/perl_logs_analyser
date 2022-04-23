use strict;
use warnings;
use feature 'say';

use Test::More;
use Test::Output;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Hits::Alert;

# some functional tests

{
    my $rows = [
    	(map {{date=>'0',request=>'GET /api', stdout => ''}} 1 .. 12),
    	{
    		date=>'0',
    		request =>'GET /api',
    		stdout => "1970-01-01 03:00:00: !!! HIGH TRAFFIC GENERATED ALERT : 13 hits for 2 minutes > 12 threshold !!!\n"
    	},
    	{
    		date=>'0',
    		request =>'GET /api',
    		stdout => "" # we already have an alert, no new messages
    	},
    	{
    		date=>'119',
    		request =>'GET /api',
    		stdout => "" # we already have an alert, no new messages
    	},
    	{
    		date=>'120',
    		request =>'GET /api',
    		stdout => "1970-01-01 03:02:00: !!! ALERT RECOVERED : 2 hits for 2 minutes < 12 threshold !!!\n"
    	},
    	(map {{date=>'120',request=>'GET /api', stdout => ''}} 1 .. 10),
    	{
    		date=>'121',
    		request =>'GET /api',
    		stdout => "1970-01-01 03:02:01: !!! HIGH TRAFFIC GENERATED ALERT : 13 hits for 2 minutes > 12 threshold !!!\n"
    	},
    	{
    		date=>'1000',
    		request =>'GET /api',
    		stdout => "1970-01-01 03:16:40: !!! ALERT RECOVERED : 1 hits for 2 minutes < 12 threshold !!!\n"
    	},
    ];
    # we should have an alert after 12 requests in 120 secs
	my $alert = Hits::Alert->new(sec_threshold => 0.1);
	for my $row (@$rows) {
		stdout_is(
           sub { $alert->process_row($row)},
           $row->{stdout},
           'Test STDOUT'
        );
        # say Dumper($alert);
	}
}


done_testing();