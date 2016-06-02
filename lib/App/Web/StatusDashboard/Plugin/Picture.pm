package App::Web::StatusDashboard::Plugin::Picture;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch a picture

use Mojo::URL;
use Mojo::Util qw(b64_encode);


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::Picture is a plugin to fetch a picture.

=head1 METHODS

=cut


has 'url';


=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item url

URL of the picture you want to display.

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	Mojo::IOLoop->delay(
		sub {
			my ($delay) = @_;
			$self->ua()->get($self->url() => $delay->begin());
		},
		sub {
			my ($delay, $tx) = @_;
			if ($self->transactions_ok($tx)) {
				my $content_type = $tx->res()->headers()->content_type();
				unless (defined $content_type) {
					die('No content type in response');
				}
				unless ($content_type =~ m{^image/\w+$}) {
					die('Unsupported content type ' . $content_type . ' in response');
				}
				$self->update_status({
					data => 'data:' . $content_type . ';base64,'
						. b64_encode($tx->res()->body())
				});
			}
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


=head2 has_css

Specialized method to indicate that this plugin has CSS resources.

=cut

sub has_css {
	return 1;
}


1;
