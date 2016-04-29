package StatusDashboard::Plugin::IcingaClassic;

use Mojo::Base -base;

# ABSTRACT: Simple plugin to fetch status from an Icinga classic instance

use Mojo::IOLoop;
use Mojo::UserAgent;

has 'dashboard';
has 'id';
has 'base_url';
has 'cycle' => 60;
has 'ua' => sub {
	return Mojo::UserAgent->new();
};


=head2 init

Initialize the plugin.

=cut

sub init {
	my ($self) = @_;

	Mojo::IOLoop->recurring($self->cycle(), sub {
		$self->update();
	});
	$self->update();
	return;
}


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
					warn $services_tx->error();
				}
			});
		}
		else {
			warn $hosts_tx->error();
		}
	});
	return;
}

1;
