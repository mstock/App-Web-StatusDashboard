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


=head2 short_name

Get short name of the plugin. Will the last part of the package name, in lower
case letters, split at the upper case letters.

=head3 Result

The short name.

=cut

sub short_name {
	my ($self) = @_;

	my $class = ref $self || $self;
	my ($plugin_name) = $class =~ m{::(\w+)$};
	my @parts = $plugin_name =~ m{([A-Z]?[a-z0-9]+)}g;
	return join('-', map { lc } @parts);
}


1;
