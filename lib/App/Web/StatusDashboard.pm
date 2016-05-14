package App::Web::StatusDashboard;

use Mojo::Base 'Mojolicious';

# ABSTRACT: Mojolicious-based status dashboard application

use Mojo::IOLoop;
use Class::Load qw(load_class);
use DateTime;
use Test::Deep::NoTest;
use Log::Any qw($log);
use Log::Any::Adapter;
use File::Spec::Functions qw(catdir);

has 'status' => sub { return {} };
has 'websocket_clients' => sub { return {} };
has 'status_plugins' => sub { return {} };
has 'dashboards' => sub { return [] };

=head2 startup

Mojolicious startup method.

=cut

sub startup {
	my ($self) = @_;

	Log::Any::Adapter->set('MojoLog', logger => $self->log());

	my $r = $self->routes;
	$r->get('/config')->to('root#config');
	$r->get('/status')->to('status#status');
	$r->websocket('/status/ws')->to('status#statuswsinit');
	$r->get('/:dashboard' => {
		dashboard=> 'index'
	})->to('root#index');

	my $config = $self->plugin('Config');
	for my $plugin ($self->_load_plugins($config)) {
		$plugin->init();
		push @{$self->status_plugins()->{ref $plugin} //= []}, $plugin;
	}

	my @dashboard_dirs = grep { -d $_ } map {
		catdir($_, 'dashboards')
	} @{$self->renderer()->paths()};
	for my $dashboard_dir (@dashboard_dirs) {
		opendir(my $dirh, $dashboard_dir) or die('Could not open '
			. $dashboard_dir . ': ' . $!);
		while (my $candidate = readdir($dirh)) {
			if (my ($dashboard_name) = $candidate =~ m{^([\w_-]+)\.html\.ep$}) {
				push @{$self->dashboards()}, $dashboard_name;
			}
		}
		closedir($dirh);
	}
}


sub _load_plugins {
	my ($self, $config) = @_;

	my @plugins;
	for my $plugin_class (keys %{$config->{plugins}}) {
		load_class($plugin_class);
		for my $instance_id (keys %{$config->{plugins}->{$plugin_class}}) {
			push @plugins, $plugin_class->new({
				%{$config->{plugins}->{$plugin_class}->{$instance_id}},
				id        => $instance_id,
				dashboard => $self,
			});
		}
	}

	return @plugins;
}


=head2 update_status

Update the given status.

=head3 Parameters

This method expects positional parameters.

=over

=item status_id

Id of the status that should be updated. Should correspond to the plugin instance
id from the configuration.

=item status

Hash reference with the latest status object.

=back

=head3 Result

Nothing on success, an exception otherwise.

=cut

sub update_status {
	my ($self, $status_id, $status) = @_;

	$log->debug('Status update from ' . $status_id);

	if (!eq_deeply($self->status()->{$status_id}->{data}, $status)) {
		my $new_status = {
			data         => $status,
			last_updated => DateTime->now->strftime('%Y%m%dT%H%M%S%z'),
		};
		$self->status()->{$status_id} = $new_status;
		for my $client (values %{$self->websocket_clients()}) {
			$client->send({
				json => {
					$status_id => $new_status,
				},
			});
		}
	}

	return;
}


=head2 register_client

Register a client of the websocket connection.

=head3 Parameters

This method expects positional parameters.

=over

=item tx

Connection object.

=back

=head3 Result

Nothing on success, an exception otherwise.

=cut

sub register_client {
	my ($self, $tx) = @_;
	Mojo::IOLoop->stream($tx->connection())->timeout(3000);
	$self->websocket_clients()->{"$tx"} = $tx;
	$tx->send({
		json => $self->status()
	});
	return;
}


=head2 unregister_client

Unregister websocket client.

=head3 Parameters

This method expects positional parameters.

=over

=item tx

Connection object.

=back

=head3 Result

Nothing on success, an exception otherwise.

=cut

sub unregister_client {
	my ($self, $tx) = @_;

	delete $self->websocket_clients()->{"$tx"};
	return;
}


1;
