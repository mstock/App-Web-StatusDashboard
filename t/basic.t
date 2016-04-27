use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('StatusDashboard');
$t->get_ok('/')->status_is(200)->content_like(qr/Status Dashboard/i);

done_testing();
