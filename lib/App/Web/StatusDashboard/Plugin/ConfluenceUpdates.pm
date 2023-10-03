package App::Web::StatusDashboard::Plugin::ConfluenceUpdates;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch latest updates from Confluence

use Mojo::URL;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::ConfluenceUpdates is a plugin to fetch updates
from a Confluence instance.

=head1 METHODS

=cut


has 'url';
has 'username';
has 'token';


=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item url

URL where update can be retrieved. May look as follows:

	https://user:password@<subdomain>.atlassian.net/wiki/rest/dashboardmacros/1.0/updates.json? \
		maxResults=40&tab=all&showProfilePic=false&labels=&spaces=&users=&types=& \
		category=&spaceKey=

=item username

Username to use when logging in to Jira.

=item token

API token to use.

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	my $url = Mojo::URL->new($self->url());
	$url->userinfo($self->username() . ':' . $self->token());
	$self->ua()->get_p($url)->then(sub {
		my ($updates) = @_;
		if ($self->transactions_ok($updates)) {
			$self->update_status($updates->res->json()->{changeSets});
		}
	})->catch(sub {
		my ($err) = @_;
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
