package App::Web::StatusDashboard::Plugin::UnhandledRedmineIssues;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Plugin to fetch unhandled Redmine issues

use 5.010001;
use Mojo::URL;
use Mojo::Parameters;
use DateTime;
use DateTimeX::ISO8601::Interval;
use List::MoreUtils qw(uniq none any);

=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::UnhandledRedmineIssues is a plugin to fetch
issues from a Redmine instance that have not yet been handled (by eg. a first
level support person).

=head1 METHODS

=cut


has 'base_url';

has 'handler_uids' => sub { [] };

has 'max_age';

has 'office_hours';

has 'office_hours_time_zone' => sub { 'UTC' };

has 'warning_threshold';

has 'critical_threshold';

has '_url' => sub {
	my ($self) = @_;

	return Mojo::URL->new($self->base_url());
};

=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item base_url

Base URL of the issues resource of your Redmine API. You can also apply
filters to the issues via query parameters if you're only interested in a subset.

=item handler_uids

Array reference with Redmine user ids of users that, if they update an issue,
make the issue considered as 'handled'.

=item max_age

Maximum age of an issue. Expects an ISO8601 duration string. Useful to reduce the
number of issues fetched from the Redmine API.

=item office_hours

Hash reference where keys are week days (1-7) and values are array references
of C<ISO 8601> intervals:

	{
		1 => ['T08:00:00/PT9H'], # Monday, office hours start at 08:00:00, last
		                         # for 9 hours
		2 => ['T08:00:00/PT4H', 'T13:00:00/PT4H'], # Tuesday, office hours start
		                                           # at 08:00:00, last for 8 hours
		                                           # with a 1 hour lunch break
		...
	}

=item office_hours_time_zone

Time zone of the office hours declaration. Defaults to C<UTC>. Should be
provided as eg. C<Europe/Zurich> for useful DST handling.

=item warning_threshold

Duration which, when overrun, will trigger a 'warning' state.

=item critical_threshold

Duration which, when overrun, will trigger a 'critical' state.

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	my $url = $self->_url();
	my @collection_params = (
		sort => 'created_on:desc',
	);
	my @filter;
	my $now = DateTime->now(time_zone => 'UTC');
	if (my $max_age = $self->max_age()) {
		my $created_on = $now->clone()->subtract_duration(
			DateTimeX::ISO8601::Interval->parse($max_age)->duration()
		);
		@filter = (
			created_on => $created_on->format_cldr('\'>=\'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
		);
	}

	Mojo::IOLoop->delay(
		sub {
			# Fetch count
			my ($delay) = @_;
			$self->ua()->get(
				$url->clone()->query([
					limit => 1,
					@filter,
					@collection_params,
				]) => $delay->begin()
			);
		},
		sub {
			# Fetch all issues
			my ($delay, $basic) = @_;
			if ($self->transactions_ok($basic)) {
				my $total = $basic->res()->json()->{total_count};
				if ($total > 0) {
					my $offset = 0;
					my $limit = 50;
					while ($offset < $total) {
						$self->ua()->get(
							$url->clone()->query([
								limit  => $limit,
								offset => $offset,
								@filter,
								@collection_params,
							]) => $delay->begin()
						);
						$offset = $offset + $limit;
					}
				}
				else {
					$self->update_status([]);
				}
			}
		},
		sub {
			# Fetch issue details
			my ($delay, @responses) = @_;
			if ($self->transactions_ok(@responses)) {
				for my $issue (map { @{$_->res->json()->{issues}} } @responses) {
					my $issue_url = $url->clone()->path('issues/' . $issue->{id} . '.json');
					$self->ua()->get(
						$issue_url->query([
							include => 'journals'
						]) => $delay->begin()
					);
				}
			}
		},
		sub {
			# Apply filter, assemble status
			my ($delay, @responses) = @_;
			if ($self->transactions_ok(@responses)) {
				my @issues = $self->get_unhandled_issues(
					$now,
					map {
						$_->res->json()->{issue}
					} @responses
				);
				my $status = (any { $_->{status} eq 'critical' } @issues)
					? 'critical'
					: (any { $_->{status} eq 'warning' } @issues)
						? 'warning'
						: 'ok';
				$self->update_status({
					status => $status,
					issues => \@issues,
				});
			}
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


=head2 get_unhandled_issues

Extract issues that are considered as unhandled from a list of issues.

=head3 Parameters

This method expects positional parameters.

=over

=item now

L<DateTime>-based timestamp that should be considered as "now".

=item issues

Array with the issues that should be filtered.

=back

=head3 Result

The issues that are considered as unhandled, i.e. issues which have not been
updated by a user with one of the C<handler_uids>.

=cut

sub get_unhandled_issues {
	my ($self, $now, @issues) = @_;

	my $url = $self->_url();
	my @handler_uids = @{$self->handler_uids()};
	return map {
		+{
			%{$_->[0]},
			status => $_->[1],
			age    => DateTimeX::ISO8601::Interval->new(duration => $_->[2])->format(),
			links  => {
				self => $url->clone()->userinfo(undef)->path(
					'issues/' . $_->[0]->{id}
				)->query(Mojo::Parameters->new())->to_string()
			}
		}
	}
	map {
		[ $_, $self->get_issue_status_and_age($_, $now) ]
	}
	grep {
		my @editors = uniq map { $_->{user}->{id} } @{$_->{journals} // []};
		none {
			my $editor = $_;
			any {
				my $handler = $_;
				$handler eq $editor
			} @handler_uids
		} @editors;
	} @issues;
}


=head2 get_age

Calculate age of a given issue. Only counts the time during the office hours.

=head3 Parameters

This method expects positional parameters.

=over

=item created_on

L<DateTime|DateTime> object with creation date.

=item now

L<DateTime>-based timestamp that should be considered as "now".

=back

=head3 Result

The age as a L<DateTime::Duration|DateTime::Duration> object.

=cut

sub get_age {
	my ($self, $created_on, $now) = @_;

	$now = $now->clone();
	$created_on = $created_on->clone();
	my $current_day = $created_on->clone()->set_time_zone(
		$self->office_hours_time_zone()
	);
	$current_day->set_hour(0);
	$current_day->set_minute(0);
	$current_day->set_second(0);

	my $age = DateTime::Duration->new();
	while ($current_day < $now) {
		my @office_hours = @{$self->office_hours()->{$current_day->day_of_week()} // []};
		for my $office_hours (@office_hours) {
			my $interval = DateTimeX::ISO8601::Interval->parse(
				$current_day->strftime('%F') . $office_hours,
				time_zone => $self->office_hours_time_zone()
			);
			if ($interval->contains($created_on)) {
				if ($interval->end() < $now) {
					$age->add_duration($interval->end()->subtract_datetime($created_on));
				}
				else {
					$age->add_duration($now->subtract_datetime($created_on));
				}
			}
			elsif ($now > $interval->start()) {
				if ($now < $interval->end()) {
					$age->add_duration($now->subtract_datetime($interval->start()));
				}
				elsif ($created_on < $interval->start()) {
					$age->add_duration($interval->duration());
				}
			}
		}
		$current_day->add(days => 1);
	}

	return $age;
}


=head2 get_issue_status_and_age

Calculates age of given issue and derives the issue status from the age, based
on the C<warning_threshold> and C<critical_threshold> values.

=head3 Parameters

This method expects positional parameters.

=over

=item issue

Hash reference with issue data.

=item now

L<DateTime>-based timestamp that should be considered as "now".

=back

=head3 Result

A list with issue status (one of C<ok>, C<warning> or C<critical>) and issue age
as L<DateTime::Duration|DateTime::Duration> object.

=cut

sub get_issue_status_and_age {
	my ($self, $issue, $now) = @_;

	my $warning_threshold = DateTimeX::ISO8601::Interval->parse(
		$self->warning_threshold()
	)->duration();
	my $critical_threshold = DateTimeX::ISO8601::Interval->parse(
		$self->critical_threshold()
	)->duration();
	my $created_on = DateTime::Format::ISO8601->parse_datetime($issue->{created_on});
	my $age = $self->get_age($created_on, $now);
	my $status;
	if (DateTime::Duration->compare($critical_threshold, $age , $created_on) < 0) {
		$status = 'critical';
	}
	elsif (DateTime::Duration->compare($warning_threshold, $age , $created_on) < 0) {
		$status = 'warning';
	}
	else {
		$status = 'ok';
	}
	return ($status, $age);
}


=head2 has_css

Specialized method to indicate that this plugin has CSS resources.

=cut

sub has_css {
	return 1;
}


1;
