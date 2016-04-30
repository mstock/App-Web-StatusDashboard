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

	my $status = {};

	$self->ua()->get($self->base_url().'?style=hostdetail&jsonoutput' => sub {
		my ($hosts_ua, $hosts_tx) = @_;

		if ($hosts_tx->success()) {
			$status->{hosts} = $hosts_tx->res->json();
			$self->ua()->get($self->base_url().'?jsonoutput' => sub {
				my ($services_ua, $services_tx) = @_;
				if ($services_tx->success()) {
					$status->{services} = $services_tx->res->json();
					$self->dashboard()->update_status($self->id(), $status);
				}
				else {
					$log->errorf('Request failed: %s', $services_tx->error());
				}
			});
		}
		else {
			$log->errorf('Request failed: %s', $hosts_tx->error());
		}
	});
	return;
}


1;
