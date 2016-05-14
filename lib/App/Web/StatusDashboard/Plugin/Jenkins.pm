package App::Web::StatusDashboard::Plugin::Jenkins;

use Mojo::Base 'App::Web::StatusDashboard::Plugin';

# ABSTRACT: Simple plugin to fetch status from Jenkins

use Log::Any qw($log);
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
				$url->clone()->path('computer/api/json')->query([
					tree => 'busyExecutors,totalExecutors'
				]) => $delay->begin()
			);
			$self->ua()->get(
				$url->clone()->path('api/json')->query([
					tree => 'jobs[name,color]'
				]) => $delay->begin()
			);
		},
		sub {
			my ($delay, $executors, $jobs) = @_;
			$self->dashboard()->update_status($self->id(), {
				executors => $executors->res->json(),
				jobs      => $jobs->res->json()->{jobs}
			});
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


1;
