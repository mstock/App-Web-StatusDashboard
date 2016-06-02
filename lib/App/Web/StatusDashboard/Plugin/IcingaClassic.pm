package App::Web::StatusDashboard::Plugin::IcingaClassic;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch status from an Icinga classic instance

use Mojo::URL;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::IcingaClassic is a plugin to fetch data from
an IcingaClassic instance.

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

Base URL of your IcingaClassic instance, usually the C<status.cgi> URL.

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
