package App::Web::StatusDashboard::PollingPlugin;

use Mojo::Base 'App::Web::StatusDashboard::Plugin';

# ABSTRACT: Base class for status plugins that poll some service at regular intervals

use Carp;
use MRO::Compat;
use Mojo::IOLoop;
use Mojo::UserAgent;
use Log::Any qw($log);

has 'cycle' => 60;

=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::Plugin/new>
in L<App::Web::StatusDashboard::Plugin|App::Web::StatusDashboard::Plugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item cycle

Update cycle, defaults to 60s. If set to 0 or a negative value, no recurring
updates will be done, so you should trigger the update via some other mechanism
(for example using the
L<App::Web::StatusDashboard::Plugin::UpdateTrigger|App::Web::StatusDashboard::Plugin::UpdateTrigger>
plugin).

=back

=cut

=head2 init

Initialize the plugin. Will start recurring calls to C<update> with the configured
cycle.

=cut

sub init {
	my ($self, @arg) = @_;

	if ($self->cycle() > 0) {
		Mojo::IOLoop->recurring($self->cycle(), sub {
			$self->update();
		});
	}
	Mojo::IOLoop->timer(0, sub {
		$self->update();
	});
	return $self->next::method(@arg);
}


=head2 update

Update the status in the dashboard, and must be implemented by subclasses.

=cut

sub update {
	my ($self) = @_;

	confess('Plugins must implement the update() method');
}


1;
