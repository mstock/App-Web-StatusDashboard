package App::Web::StatusDashboard::Controller::Root;

use Mojo::Base 'Mojolicious::Controller';

# ABSTRACT: Basic root controller which provides root HTML and configuration

use Mojo::IOLoop;
use MRO::Compat;


=head2 index

Provide HTML for the document root.

=cut

sub index {
	my ($self) = @_;

	$self->render();
	return;
}


=head2 config

Provide configuration values for the application.

=cut

sub config {
	my ($self) = @_;

	$self->render(format => 'js');
	return;
}


1;
