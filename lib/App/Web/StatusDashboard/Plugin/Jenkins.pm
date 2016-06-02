package App::Web::StatusDashboard::Plugin::Jenkins;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch status from Jenkins

use Mojo::URL;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::Jenkins is a plugin to fetch data from
Jenkins.

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

Base URL of your Jenkins instance.

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
			if ($self->transactions_ok($executors, $jobs)) {
				$self->update_status({
					executors => $executors->res->json(),
					jobs      => $jobs->res->json()->{jobs}
				});
			}
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


1;
