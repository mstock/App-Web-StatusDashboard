package App::Web::StatusDashboard::Plugin::Feed;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch data from some feed (like RSS, ATOM, etc.)

use Mojo::URL;
use XML::Feed;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::Feed retrieves data from RSS/ATOM etc. feeds,
and processes them using L<XML::Feed|XML::Feed>.

=head1 METHODS

=cut


has 'sources';


=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item sources

Array reference with feed URLs from where data should be retrieved. The feeds
will be merged together and sorted by date.

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	Mojo::IOLoop->delay(
		sub {
			my ($delay) = @_;
			for my $source (@{$self->sources() // []}) {
				$self->ua()->get(
					$source => $delay->begin()
				);
			}
		},
		sub {
			my ($delay, @transactions) = @_;
			if ($self->transactions_ok(@transactions)) {
				my @items;
				for my $tx (@transactions) {
					my $feed = XML::Feed->parse(\($tx->res->body()));
					for my $item ($feed->items()) {
						push @items, {
							title   => $item->title(),
							content => $item->content()->body(),
							issued  => $item->issued() // $item->modified(),
						};
					}
				}
				@items = sort { $b->{issued} cmp $a->{issued} } @items;
				for my $item (@items) {
					$item->{issued} = $self->format_timestamp($item->{issued});
				}
				$self->update_status(\@items);
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
