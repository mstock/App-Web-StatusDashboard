package App::Web::StatusDashboard::Plugin::JiraIssues;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch issues from Jira

use Mojo::URL;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::JiraIssues is a plugin to fetch data from a
Jira instance.

=head1 METHODS

=cut


has 'base_url';


=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item base_url

Base URL of your Jira API. May look about as follows:

	https://user:password@<subdomain>.atlassian.net/rest/api/2/search? \
		jql=status%20in%20%28%22In%20Progress%22%2C%20%22To%20Do%22%29& \
		fields=issuetype,project,status,summary,priority

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	my $url = Mojo::URL->new($self->base_url());
	Mojo::IOLoop->delay(
		sub {
			my ($delay) = @_;
			$self->ua()->get(
				$url->clone()->query([
					maxResults => 0
				]) => $delay->begin()
			);
		},
		sub {
			my ($delay, $basic) = @_;
			if ($self->transactions_ok($basic)) {
				my $total = $basic->res->json()->{total};
				my $start_at = 0;
				my $max_results = 50;
				while ($start_at < $total) {
					$self->ua()->get(
						$url->clone()->query([
							maxResults => $max_results,
							startAt    => $start_at,
						]) => $delay->begin()
					);
					$start_at = $start_at + $max_results;
				}
			}
		},
		sub {
			my ($delay, @responses) = @_;
			if ($self->transactions_ok(@responses)) {
				$self->update_status([
					map { @{$_->res->json()->{issues}} } @responses
				]);
			}
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


1;
