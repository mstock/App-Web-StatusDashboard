package App::Web::StatusDashboard;

use Mojo::Base 'Mojolicious';

# ABSTRACT: Mojolicious-based status dashboard application

use Mojo::IOLoop;
use Mojo::EventEmitter;
use Class::Load qw(load_class);
use DateTime;
use Test::Deep::NoTest;
use Log::Any qw($log);
use Log::Any::Adapter;
use File::ShareDir;
use File::Spec::Functions qw(catdir);
use App::Web::StatusDashboard::Plugin;


=head1 SYNOPSIS

When running from Git:

	./script/status_dashboard daemon

When running from the installed distribution:

	status_dashboard daemon

You can now open a web browser at L<http://localhost:3000> to get some basic
instructions for setting up your own dashboard.

=head1 DESCRIPTION

App::Web::StatusDashboard is a L<Mojolicious|Mojolicious>-based micro-framework
to build status dashboards. The backend provides a plugin infrastructure which
should make it easy to add additional plugins that prepare and/or fetch status
data from various systems and sources, and the AngularJS-based frontend provides
directives for the included plugins to visualize their data.

=head1 METHODS

=cut


has 'status' => sub { return {} };
has 'websocket_clients' => sub { return {} };
has 'status_plugins' => sub { return {} };
has 'status_plugins_by_id' => sub { return {} };
has 'dashboards' => sub { return [] };
has 'event_emitter' => sub { Mojo::EventEmitter->new() };


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

	my $config = $self->plugin('Config', default => {});
	for my $plugin ($self->_load_plugins($config)) {
		$plugin->init();
		push @{$self->status_plugins()->{ref $plugin} //= []}, $plugin;
		$self->status_plugins_by_id()->{$plugin->id()} = $plugin;
	}

	my $share_dir = eval { File::ShareDir::dist_dir('App-Web-StatusDashboard') } // 'share';
	$self->renderer()->paths([
		@{$config->{template_paths} // []},
		catdir($share_dir, 'templates')
	]);
	$self->static()->paths([
		@{$config->{static_paths} // []},
		catdir($share_dir, 'public')
	]);

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

Hash reference with the latest status data.

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
			last_updated => App::Web::StatusDashboard::Plugin->format_timestamp(
				DateTime->now()
			),
		};
		$self->status()->{$status_id} = $new_status;
		my $data = {
			$status_id => $new_status,
		};
		for my $client (values %{$self->websocket_clients()}) {
			$client->send({
				json => $data,
			});
		}
		$self->event_emitter->emit(status_update => $data);
	}

	return;
}


=head2 get_plugin

Get plugin with the given id.

=cut

sub get_plugin {
	my ($self, $id) = @_;

	return $self->status_plugins_by_id()->{$id};
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


=head1 BUNDLED FILES

The L<App::Web::StatusDashboard|App::Web::StatusDashboard> distribution contains
some files and frameworks with other licenses that were bundled for convenience.

=head2 AngularJS

	Copyright (c) 2010-2015 Google, Inc. http://angularjs.org

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Angular-Bootstrap

	Copyright (c) L<https://github.com/angular-ui/bootstrap/graphs/contributors>

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Angular-Chart.js

	Copyright (c) 2013-2015 Nick Downie

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Angular-Message-Format

	Copyright (c) 2010-2015 Google, Inc. http://angularjs.org

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Angular-Messages

	Copyright (c) 2010-2015 Google, Inc. http://angularjs.org

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Angular-Moment

	Copyright (c) 2013-2016 Uri Shaked and contributors

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Angular-Route

	Copyright (c) 2010-2015 Google, Inc. http://angularjs.org

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Angular-Websocket

	Copyright (c) 2013-2016 Patrick Stapleton, gdi2290, PatrickJS

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Bootstrap

	Copyright (c) L<https://github.com/angular-ui/bootstrap/graphs/contributors>

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Chart.js

	Copyright (c) 2013-2015 Nick Downie

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 jQuery

	Copyright (c) jQuery Foundation and other contributors, https://jquery.org/

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head2 Moment.js

	Copyright (c) 2011-2016 Tim Wood, Iskren Chernev, Moment.js contributors

Licensed under the MIT License, L<http://creativecommons.org/licenses/MIT>.

=head1 SEE ALSO

=over

=item *

L<App::Web::StatusDashboard::Plugin|App::Web::StatusDashboard::Plugin> - base
class for plugins.

=item *

L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin>
- base class for plugins that retrieve their data through polling.

=item *

C<App::Web::StatusDashboard::Plugin::*> - included plugins.

=back

=cut


1;
