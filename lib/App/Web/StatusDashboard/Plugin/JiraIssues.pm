package App::Web::StatusDashboard::Plugin::JiraIssues;

use Mojo::Base 'App::Web::StatusDashboard::Plugin';

# ABSTRACT: Simple plugin to fetch issues from Jira

use Mojo::URL;

has 'base_url';


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
		},
		sub {
			my ($delay, @responses) = @_;
			$self->dashboard()->update_status($self->id(), [
				map { @{$_->res->json()->{issues}} } @responses
			]);
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


1;