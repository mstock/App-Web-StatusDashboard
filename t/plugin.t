use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use App::Web::StatusDashboard::Plugin;

is(
	App::Web::StatusDashboard::Plugin::short_name('StatusDashboard::Plugin::FooBar'),
	'foo-bar',
	'short name ok'
);
is(
	App::Web::StatusDashboard::Plugin::short_name('StatusDashboard::Plugin::FooBarBaz'),
	'foo-bar-baz',
	'short name ok'
);
is(
	App::Web::StatusDashboard::Plugin::short_name('StatusDashboard::Plugin::foobar'),
	'foobar',
	'short name ok'
);
is(
	App::Web::StatusDashboard::Plugin::short_name('StatusDashboard::Plugin::FooBar20'),
	'foo-bar20',
	'short name ok'
);

done_testing();
