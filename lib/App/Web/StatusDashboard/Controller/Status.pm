package App::Web::StatusDashboard::Controller::Status;

use Mojo::Base 'Mojolicious::Controller';

# ABSTRACT: Provide action that returns status as JSON and endpoint for websocket

use Log::Any qw($log);


=head1 DESCRIPTION

App::Web::StatusDashboard::Controller::Status provides a resource to fetch the
current status information as JSON, and a websocket endpoint to get notified
with status updates.

=head1 METHODS

=head2 status

Simple resource that returns the current status in JSON format.

=cut

sub status {
	my ($self) = @_;

	$self->render(json => $self->app()->status());
	return;
}


=head2 statuswsinit

Initialize the status websocket.

=cut

sub statuswsinit {
	my ($self) = @_;

	$log->debug('Initializing websocket...');
	$self->app->register_client($self->tx);
	$self->on('finish', sub {
		my ($self) = @_;
		$self->app->unregister_client($self->tx);
	});
	$self->on('message', sub {
		my ($self, $message) = @_;
		$log->debug('Client message: ' . $message);
	});
	return;
}


1;
