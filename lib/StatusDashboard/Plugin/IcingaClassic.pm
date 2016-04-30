package StatusDashboard::Plugin::IcingaClassic;

use Mojo::Base 'StatusDashboard::Plugin';

# ABSTRACT: Simple plugin to fetch status from an Icinga classic instance

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
				$self->base_url().'?style=hostdetail&jsonoutput' => $delay->begin()
			);
			$self->ua()->get(
				$self->base_url().'?jsonoutput' => $delay->begin()
			);
		},
		sub {
			my ($delay, $hostdetail, $servicedetail) = @_;
			$self->dashboard()->update_status($self->id(), {
				services => $servicedetail->res->json(),
				hosts    => $hostdetail->res->json()
			});
		}
	)->wait;

	return;
}


1;
