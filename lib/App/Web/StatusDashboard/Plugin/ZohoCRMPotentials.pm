package App::Web::StatusDashboard::Plugin::ZohoCRMPotentials;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch potentials from Zoho CRM

use Mojo::URL;
use DateTime;

=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::ZohoCRMPotentials is a plugin to fetch potentials
from a Zoho CRM.

=head1 METHODS

=cut


has 'url';
has 'from' => sub { 1 };
has 'to' => sub { 100 };
has 'sort_column' => sub { 'Closing Date' };
has 'sort_order' => sub { 'asc' };
has 'max_age' => sub {{ years => 1 }};
has 'scope' => sub { 'crmapi' };


=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters, see below.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item url

URL where potentials can be fetched. Must already include the C<authtoken>
parameter required for access:

	https://crm.zoho.com/crm/private/json/Potentials/getRecords?authtoken=<token>

Some other parameters will be set by the plugin:

=item from

Index where to start. Defaults to C<1>.

=item to

Index where to end. Defaults to C<100>.

=item sort_column

Column to sort by. Defaults to C<Closing Date>.

=item sort_order

Sort order to use. Defaults to C<asc>.

=item max_age

Maximum age as hash reference (will be passed to L<DateTime::Duration|DateTime::Duration>).
Potentials that have not been modified for this amount of time will not be fetched.

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	my $url = Mojo::URL->new($self->url());
	Mojo::IOLoop->delay(
		sub {
			my ($delay) = @_;
			my $last_modified = DateTime->now()->subtract(
				%{$self->max_age()}
			)->strftime('%F %T');
			$self->ua()->get(
				$url->clone()->query([
					scope            => $self->scope(),
					newFormat        => 2,
					version          => 2,
					sortColumnString => $self->sort_column(),
					sortOrderString  => $self->sort_order(),
					fromIndex        => $self->from(),
					toIndex          => $self->to(),
					lastModifiedTime => $last_modified,
				]) => $delay->begin()
			);
		},
		sub {
			my ($delay, $potentials) = @_;
			if ($self->transactions_ok($potentials)) {
				$self->update_status(
					$potentials->res()->json()->{response}->{result}->{Potentials}->{row} // []
				);
			}
		},
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


1;
