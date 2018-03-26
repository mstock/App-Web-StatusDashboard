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

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	my $url = Mojo::URL->new($self->base_url());
	my @handler_uids = @{$self->handler_uids()};
	my @collection_params = (
		sort => 'created_on:desc',
	);
	my @filter;
	if (my $max_age = $self->max_age()) {
		my $created_on = DateTime->now(time_zone => 'UTC')->subtract_duration(
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
				$self->update_status([
					map {
						{
							%{$_},
							links => {
								self => $url->clone()->path(
									'issues/' . $_->{id}
								)->query(Mojo::Parameters->new())
							}
						}
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
					}
					map {
						$_->res->json()->{issue}
					} @responses
				]);
			}
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


=head2 has_css

Specialized method to indicate that this plugin has CSS resources.

=cut

sub has_css {
	return 1;
}


1;
