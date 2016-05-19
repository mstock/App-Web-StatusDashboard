package App::Web::StatusDashboard::Plugin;

use Mojo::Base -base;

# ABSTRACT: Base class for status plugins

use Carp;
use Mojo::UserAgent;
use Log::Any qw($log);
use List::MoreUtils qw(any);

has 'dashboard';
has 'id';
has 'cycle' => 60;
has 'ua' => sub {
	return Mojo::UserAgent->new();
};

=head2 new

Constructor, creates new instance.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item dashboard

Dashboard application instance.

=item id

Id of the plugin instance.

=item ua

A L<Mojo::UserAgent|Mojo::UserAgent> instance to use. Will be automatically
created if not passed.

=back

=cut

=head2 init

Initialize the plugin.

=cut

sub init {
	my ($self) = @_;

	return;
}


=head2 update_status

Publish status update to dashboard.

=head3 Parameters

This method expects positional parameters.

=over

=item status

The updated status.

=back

=cut

sub update_status {
	my ($self, $status) = @_;

	$self->dashboard()->update_status($self->id(), $status);
	return;
}


=head2 short_name

Get short name of the plugin. Will be the last part of the package name, in lower
case letters, split at the upper case letters.

=head3 Result

The short name.

=cut

sub short_name {
	my ($self) = @_;

	my $class = ref $self || $self;
	my ($plugin_name) = $class =~ m{::(\w+)$};
	my @parts = $plugin_name =~ m{([A-Z]?[a-z0-9]+)}g;
	return join('-', map { lc } @parts);
}


=head2 transactions_ok

Check if any transaction response contains a non-HTTP-success status and throw
an exception in this case. If there is no reponse code (which can happen on event
loop resets), return false.

=head3 Result

C<1> on success, C<0> if status is unknown, an exception on non-HTTP-success.

=cut

sub transactions_ok {
	my ($self, @transactions) = @_;

	# Event loop reset?
	if (any { ! defined $_->res()->code() && defined $_->{http_state} } @transactions) {
		return 0;
	}

	# HTTP non-200 status?
	my @errors = grep { ! $_->res()->is_status_class(200) } @transactions;
	if (scalar @errors) {
		die [ map { $_->error() } @errors ];
	}

	return 1;
}


=head2 log_update_error

Log an error that occurred during the data update.

=head3 Parameters

This method expects positional parameters.

=over

=item error

The error message/exception.

=back

=cut

sub log_update_error {
	my ($self, $error) = @_;

	if (defined $error && !ref $error) {
		chomp $error;
	}
	$log->errorf('%s[%s]: Error while updating data: %s',
		ref $self, $self->id(), $error);
	return;
}


=head2 has_js

Static method to indicate if this plugin has a JavaScript resource. Defaults to
<code>1</code>. Override and return C<0> if your plugin has no such resource.

=cut

sub has_js {
	return 1;
}


1;
