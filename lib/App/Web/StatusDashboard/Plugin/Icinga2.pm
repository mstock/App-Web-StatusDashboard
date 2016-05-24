package App::Web::StatusDashboard::Plugin::Icinga2;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch status from an IcingaWeb2 instance

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
				$url->clone()->path('monitoring/list/hosts') => {
					'Accept' => 'application/json'
				} => $delay->begin()
			);
			$self->ua()->get(
				$url->clone()->path('monitoring/list/services') => {
					'Accept' => 'application/json'
				} => $delay->begin()
			);
		},
		sub {
			my ($delay, $hostdetail, $servicedetail) = @_;
			if ($self->transactions_ok($hostdetail, $servicedetail)) {
				$self->update_status({
					services => $servicedetail->res->json(),
					hosts    => $hostdetail->res->json()
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
