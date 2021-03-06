package App::Web::StatusDashboard::Plugin::Icinga2;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch status from an IcingaWeb2 instance

use Mojo::URL;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::Icinga2 is a plugin to fetch data from an
IcingaWeb2 instance.

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

Base URL of your IcingaWeb2 instance.

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


=head2 has_css

Specialized method to indicate that this plugin has CSS resources.

=cut

sub has_css {
	return 1;
}


1;
