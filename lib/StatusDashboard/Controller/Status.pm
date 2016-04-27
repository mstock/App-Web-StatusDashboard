package StatusDashboard::Controller::Status;

use Mojo::Base 'Mojolicious::Controller';

# ABSTRACT: Provide action that returns status as JSON and endpoint for websocket


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

	$self->app->log->info('Initializing websocket...');
	$self->app->register_client($self->tx);
	$self->on('finished', sub {
		my ($self) = @_;
		$self->app->unregister_client($self->tx);
		$self->app->log->debug('Client disconnected');
	});
	$self->on('message', sub {
		my ($self, $message) = @_;
		$self->app->log->debug('Client message: ' . $message);
	});
	return;
}


1;
