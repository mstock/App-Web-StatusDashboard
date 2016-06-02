package App::Web::StatusDashboard::Plugin::RedmineIssues;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch Redmine issues

use Mojo::URL;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::RedmineIssues is a plugin to fetch data from
a Redmine instance.

=head1 METHODS

=cut


has 'base_url';


=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item base_url

Base URL of the issues resource of your Redmine API. You can also apply
filters to the issues if you're only interested in a subset.

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	my $url = Mojo::URL->new($self->base_url());

	Mojo::IOLoop->delay(
		sub {
			my ($delay) = @_;
			$self->ua()->get(
				$url->clone()->query([
					limit => 1
				]) => $delay->begin()
			);
		},
		sub {
			my ($delay, $basic) = @_;
			if ($self->transactions_ok($basic)) {
				my $total = $basic->res()->json()->{total_count};
				my $offset = 0;
				my $limit = 50;
				while ($offset < $total) {
					$self->ua()->get(
						$url->clone()->query([
							limit  => $limit,
							offset => $offset,
						]) => $delay->begin()
					);
					$offset = $offset + $limit;
				}
			}
		},
		sub {
			my ($delay, @responses) = @_;
			if ($self->transactions_ok(@responses)) {
				$self->update_status([
					map { @{$_->res->json()->{issues}} } @responses
				]);
			}
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


1;
