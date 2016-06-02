package App::Web::StatusDashboard::Controller::Root;

use Mojo::Base 'Mojolicious::Controller';

# ABSTRACT: Basic root controller which provides root HTML and configuration

use File::Spec::Functions qw(catfile);


=head1 DESCRIPTION

App::Web::StatusDashboard::Controller::Root is the root controller of the
application which handles requests to C</> and C</config>.

=head1 METHODS

=head2 index

Provide dashboard HTML for the document root or the selected dashboard.

=cut

sub index {
	my ($self) = @_;

	my ($dashboard) = grep {
		$self->param('dashboard') eq $_
	} @{$self->app()->dashboards()};

	if (defined $dashboard) {
		$self->render(
			template => catfile('dashboards', $dashboard),
			format   => 'html',
			handler  => 'ep'
		);
	}
	else {
		$self->res()->code(404);
		$self->render();
	}

	return;
}


=head2 config

Provide configuration values for the application, as a JavaScript file that
can be included.

=cut

sub config {
	my ($self) = @_;

	$self->render(format => 'js');
	return;
}


1;
