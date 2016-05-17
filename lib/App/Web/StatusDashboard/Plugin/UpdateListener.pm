package App::Web::StatusDashboard::Plugin::UpdateListener;

use Mojo::Base 'App::Web::StatusDashboard::Plugin';

# ABSTRACT: Listen for status updates, call handlers

use MRO::Compat;
use List::MoreUtils qw(natatime);

has 'listeners' => sub { {} };

=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::Plugin/new>
in L<App::Web::StatusDashboard::Plugin|App::Web::StatusDashboard::Plugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item listeners

Array reference with status ids at uneven positions and code references at even
positions. The code references will be called if the corresponding status was
updated.

=back

=head2 init

Register the listeners with the dashboard application.

=cut

sub init {
	my ($self, @arg) = @_;

	my $iterator = natatime 2, @{$self->listeners() // []};
	my $status_id_handler = {};
	while (my @vals = $iterator->()) {
		my ($status_ids, $handler) = @vals;
		for my $status_id (@{$status_ids}) {
			$status_id_handler->{$status_id} //= [];
			push @{$status_id_handler->{$status_id}}, $handler;
		}
	}

	$self->dashboard()->event_emitter()->on(status_update => sub {
		my ($emitter, $data) = @_;
		for my $status_id (keys %{$data}) {
			for my $handler (@{$status_id_handler->{$status_id} // []}) {
				$handler->($status_id => $data->{$status_id}, $self->ua());
			}
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
