use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Path::Tiny;

$ENV{MOJO_CONFIG} = path('t/dummy/app-web-status_dashboard.conf');
my $t = Test::Mojo->new('App::Web::StatusDashboard');
$t->get_ok('/')->status_is(200)->content_like(qr/Status Dashboard/i);

done_testing();
