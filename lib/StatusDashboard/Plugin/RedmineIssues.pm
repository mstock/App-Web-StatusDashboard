package StatusDashboard::Plugin::RedmineIssues;

use Mojo::Base 'StatusDashboard::Plugin';

# ABSTRACT: Simple plugin to fetch Redmine issues

has 'base_url';


=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	$self->ua()->get($self->base_url() => sub {
		my ($hosts_ua, $hosts_tx) = @_;

		if ($hosts_tx->success()) {
			$self->dashboard()->update_status($self->id(), $hosts_tx->res->json());
		}
		else {
			warn $hosts_tx->error();
		}
	});
	return;
}


1;
