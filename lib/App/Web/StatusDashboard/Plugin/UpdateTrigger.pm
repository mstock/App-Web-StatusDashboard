package App::Web::StatusDashboard::Plugin::UpdateTrigger;

use Mojo::Base 'App::Web::StatusDashboard::Plugin';

# ABSTRACT: Trigger status update on POST requests

use MRO::Compat;
use Scalar::Util qw(blessed);
use List::MoreUtils qw(any);

has 'update_ids' => sub { [] };
has 'token' => sub { };

=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::Plugin/new>
in L<App::Web::StatusDashboard::Plugin|App::Web::StatusDashboard::Plugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item token

Optional token, if given, must be part of the query parameters of the request.

=item update_ids

Array reference with plugin ids where an update may be triggered.

=back

=head2 init

Register the resource with the dashboard application.

=cut

sub init {
	my ($self, @arg) = @_;

	$self->dashboard()->routes()
		->post('/plugin/update-trigger/' . $self->id() . '/:plugin_id' => sub {
			my ($c) = @_;

			if (defined $self->token()
					&& (! defined $c->param('token') || $c->param('token') ne $self->token())) {
				$c->res()->code(403);
				$c->render(json => {
					error => 'Valid token required',
				});
				return;
			}

			my $plugin_id = $c->param('plugin_id');
			if (any { $plugin_id eq $_ } @{$self->update_ids()}) {
				my $plugin = $self->dashboard()->get_plugin($plugin_id);
				if (blessed $plugin && $plugin->isa('App::Web::StatusDashboard::Plugin')
						&& $plugin->can('update')) {
					$plugin->update();
					$c->render(json => {});
				}
				else {
					$c->res()->code(400);
					$c->render(json => {
						error => 'No valid plugin specified',
					});
				}
			}
			else {
				$c->res()->code(403);
				$c->render(json => {
					error => 'Update not allowed',
				});
			}
		});

	return $self->next::method(@arg);
}


=head2 has_js

Specialized method to indicate that this plugin has no JavaScript resources.

=cut

sub has_js {
	return 0;
}


1;
