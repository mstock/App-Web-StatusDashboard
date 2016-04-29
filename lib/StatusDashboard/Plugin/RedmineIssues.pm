package StatusDashboard::Plugin::RedmineIssues;

use Mojo::Base -base;

# ABSTRACT: Simple plugin to fetch Redmine issues

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
