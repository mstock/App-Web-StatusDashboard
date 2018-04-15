use Mojo::Base -strict;

use 5.010001;
use Test::More;
use Test::Mojo;

use DateTime;
use DateTime::Format::ISO8601;
use App::Web::StatusDashboard::Plugin::UnhandledRedmineIssues;


sub age_ok {
	my ($plugin, $created_on, $now, $expected_age, $comment) = @_;

	my $now_dt = DateTime::Format::ISO8601->parse_datetime($now);
	my $age = $plugin->get_age($created_on, $now_dt);
	is(DateTime::Duration->compare(
		DateTime::Duration->new($expected_age),
		$age,
	$created_on), 0, $comment // 'age ok');
}


subtest "get_age" => sub {
	my $plugin = App::Web::StatusDashboard::Plugin::UnhandledRedmineIssues->new(
		office_hours => {
			1 => ['T08:00:00/PT9H'],
			2 => ['T08:00:00/PT9H'],
			3 => ['T08:00:00/PT9H'],
			4 => ['T08:00:00/PT9H'],
			5 => ['T08:00:00/PT8H'],
		},
	);

	# Created during work hours
	my $created_on = DateTime::Format::ISO8601->parse_datetime('2018-03-01T10:00:00Z');

	age_ok($plugin, $created_on, '2018-03-01T11:00:00Z', { hours => 1  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-02T11:00:00Z', { hours => 10 }); # Friday
	age_ok($plugin, $created_on, '2018-03-03T13:00:00Z', { hours => 15 }); # Saturday
	age_ok($plugin, $created_on, '2018-03-04T13:00:00Z', { hours => 15 }); # Sunday
	age_ok($plugin, $created_on, '2018-03-05T08:00:00Z', { hours => 15 }); # Monday
	age_ok($plugin, $created_on, '2018-03-05T09:00:00Z', { hours => 16 }); # Monday
	age_ok($plugin, $created_on, '2018-03-05T21:00:00Z', { hours => 24 }); # Monday

	# Created after work hours
	$created_on = DateTime::Format::ISO8601->parse_datetime('2018-03-01T21:00:00Z');

	age_ok($plugin, $created_on, '2018-03-01T22:00:00Z', {             }); # Thursday
	age_ok($plugin, $created_on, '2018-03-02T08:00:00Z', {             }); # Friday
	age_ok($plugin, $created_on, '2018-03-02T09:00:00Z', { hours => 1  }); # Friday

	# Created before work hours
	$created_on = DateTime::Format::ISO8601->parse_datetime('2018-03-01T07:00:00Z');

	age_ok($plugin, $created_on, '2018-03-01T08:00:00Z', {             }); # Thursday
	age_ok($plugin, $created_on, '2018-03-01T09:00:00Z', { hours => 1  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-01T17:00:00Z', { hours => 9  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-01T18:00:00Z', { hours => 9  }); # Thursday

	# No office hour over lunch
	$plugin = App::Web::StatusDashboard::Plugin::UnhandledRedmineIssues->new(
		office_hours => {
			1 => ['T08:00:00/PT4H', 'T13:00:00/PT4H'],
			2 => ['T08:00:00/PT4H', 'T13:00:00/PT4H'],
			3 => ['T08:00:00/PT4H', 'T13:00:00/PT4H'],
			4 => ['T08:00:00/PT4H', 'T13:00:00/PT4H'],
			5 => ['T08:00:00/PT4H', 'T13:00:00/PT3H'],
		},
	);

	# Created during work hours
	$created_on = DateTime::Format::ISO8601->parse_datetime('2018-03-01T10:00:00Z');

	age_ok($plugin, $created_on, '2018-03-01T11:00:00Z', { hours => 1  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-01T12:00:00Z', { hours => 2  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-01T13:00:00Z', { hours => 2  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-01T14:00:00Z', { hours => 3  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-02T11:00:00Z', { hours => 9  }); # Friday
	age_ok($plugin, $created_on, '2018-03-03T13:00:00Z', { hours => 13 }); # Saturday
	age_ok($plugin, $created_on, '2018-03-04T13:00:00Z', { hours => 13 }); # Sunday

	done_testing();
};


subtest "get_age with different office hour time zone" => sub {
	my $plugin = App::Web::StatusDashboard::Plugin::UnhandledRedmineIssues->new(
		office_hours => {
			1 => ['T08:00:00/PT9H'],
			2 => ['T08:00:00/PT9H'],
			3 => ['T08:00:00/PT9H'],
			4 => ['T08:00:00/PT9H'],
			5 => ['T08:00:00/PT8H'],
		},
		office_hours_time_zone => 'Europe/Zurich',
	);

	# Created during work hours
	my $created_on = DateTime::Format::ISO8601->parse_datetime('2018-03-01T10:00:00+01:00');

	age_ok($plugin, $created_on, '2018-03-01T11:00:00+01:00', { hours => 1  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-02T11:00:00+01:00', { hours => 10 }); # Friday
	age_ok($plugin, $created_on, '2018-03-03T13:00:00+01:00', { hours => 15 }); # Saturday

	# Different time zones for created on and work hours
	$created_on = DateTime::Format::ISO8601->parse_datetime('2018-03-01T09:00:00Z');

	age_ok($plugin, $created_on, '2018-03-01T11:00:00+01:00', { hours => 1  }); # Thursday
	age_ok($plugin, $created_on, '2018-03-02T11:00:00+01:00', { hours => 10 }); # Friday
	age_ok($plugin, $created_on, '2018-03-03T13:00:00+01:00', { hours => 15 }); # Saturday

	done_testing();
};


done_testing();
