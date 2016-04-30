package StatusDashboard::Plugin::Jenkins;

use Mojo::Base 'StatusDashboard::Plugin';

# ABSTRACT: Simple plugin to fetch status from Jenkins

use Log::Any qw($log);

has 'base_url';


=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	Mojo::IOLoop->delay(
		sub {
			my ($delay) = @_;
			$self->ua()->get(
				$self->base_url().'/computer/api/json?tree=busyExecutors,totalExecutors' => $delay->begin()
			);
			$self->ua()->get(
				$self->base_url().'/api/json?tree=jobs[name,color]' => $delay->begin()
			);
		},
		sub {
			my ($delay, $executors, $jobs) = @_;
			$self->dashboard()->update_status($self->id(), {
				executors => $executors->res->json(),
				jobs      => $jobs->res->json()->{jobs}
			});
		}
	)->wait;

	return;
}


1;
