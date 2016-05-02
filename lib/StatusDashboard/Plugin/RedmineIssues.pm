package StatusDashboard::Plugin::RedmineIssues;

use Mojo::Base 'StatusDashboard::Plugin';

# ABSTRACT: Simple plugin to fetch Redmine issues

use Log::Any qw($log);
use Mojo::URL;

has 'base_url';


=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	my $url = Mojo::URL->new($self->base_url());
	$self->ua()->get($url => sub {
		my ($hosts_ua, $hosts_tx) = @_;

		if ($hosts_tx->success()) {
			$self->dashboard()->update_status($self->id(), $hosts_tx->res->json());
		}
		else {
			$log->errorf('Request failed: %s', $hosts_tx->error());
		}
	});
	return;
}


1;
