package App::Web::StatusDashboard::Plugin::Picture;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch a picture

use Mojo::URL;
use Mojo::Util qw(b64_encode);

has 'url';


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


sub has_css {
	my ($self) = @_;

	return 1;
}


1;
