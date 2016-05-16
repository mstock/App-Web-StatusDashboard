package App::Web::StatusDashboard::Plugin::IcingaClassic;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch status from an Icinga classic instance

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
					jsonoutput => '',
					style => 'hostdetail'
				]) => $delay->begin()
			);
			$self->ua()->get(
				$url->clone()->query([
					jsonoutput => ''
				]) => $delay->begin()
			);
		},
		sub {
			my ($delay, $hostdetail, $servicedetail) = @_;
			$self->dashboard()->update_status($self->id(), {
				services => $servicedetail->res->json(),
				hosts    => $hostdetail->res->json()
			});
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


1;
