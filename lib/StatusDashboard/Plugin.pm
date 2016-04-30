package StatusDashboard::Plugin;

use Mojo::Base -base;

# ABSTRACT: Base class for status plugins

use Carp;
use Mojo::IOLoop;
use Mojo::UserAgent;

has 'dashboard';
has 'id';
has 'cycle' => 60;
has 'ua' => sub {
	return Mojo::UserAgent->new();
};

=head2 new

Constructor, creates new instance.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item dashboard

Dashboard application instance.

=item id

Id of the plugin instance.

=item cycle

Update cycle, defaults to 60s.

=item ua

A L<Mojo::UserAgent|Mojo::UserAgent> instance to use. Will be automatically
created if not passed.

=back

=cut

=head2 init

Initialize the plugin. Will start recurring calls to C<update> with the configured
cycle.

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

Update the status in the dashboard, and must be implemented by subclasses.

=cut

sub update {
	my ($self) = @_;

	confess('Plugins must implement the update() method');
}

1;
