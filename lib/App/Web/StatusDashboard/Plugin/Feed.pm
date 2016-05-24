package App::Web::StatusDashboard::Plugin::Feed;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch data from some feed (like RSS, ATOM, etc.)

use Mojo::URL;
use XML::Feed;

has 'sources';

my $date_time_format = 'yyyy-MM-dd\'T\'HH:mm:ssZZZZZ';

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
							issued  => $item->issued(),
						};
					}
				}
				@items = sort { $b->{issued} cmp $a->{issued} } @items;
				for my $item (@items) {
					$item->{issued} = $item->{issued}->format_cldr($date_time_format);
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


sub has_css {
	my ($self) = @_;

	return 1;
}


1;
