package App::Web::StatusDashboard::Plugin::CalDAV;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Plugin to fetch data from CalDAV calendar

use Carp;
use Mojo::URL;
use DateTime;
use Data::ICal::DateTime;
use Mojo::IOLoop::ForkCall;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::CalDAV retrieves events from a C<CalDAV>
server.

=head1 METHODS

=cut


has 'sources';
has 'days' => sub { 1 };
has 'timezone' => sub { 'local' };


=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item sources

Array reference with CalDAV URLs from where calendar data should be retrieved.
The calendars events will be merged together and sorted by date.

=item days

Days since last midnight that should be fetched. Defaults to C<1>, i.e.
fetch and keep only events from today.

=item timezone

Time zone to use in time calculations. Defaults to C<local>.

=back

=head2 update

Update the status in the dashboard.

=cut

my $filter = <<'EOFILTER';
<?xml version="1.0"?>
<c:calendar-query xmlns:c="urn:ietf:params:xml:ns:caldav">
	<d:prop xmlns:d="DAV:">
		<d:getetag/>
		<c:calendar-data></c:calendar-data>
	</d:prop>
	<c:filter>
		<c:comp-filter name="VCALENDAR">
			<c:comp-filter name="VEVENT">
				<c:time-range start="%s" end="%s"/>
			</c:comp-filter>
		</c:comp-filter>
	</c:filter>
</c:calendar-query>
EOFILTER

sub update {
	my ($self) = @_;

	my $now = DateTime->now(time_zone => $self->timezone());
	my $start = $now->clone()->set(
		hour       => 0,
		minute     => 0,
		second     => 0,
		nanosecond => 0
	);
	my $end = $start->clone()->add(days => $self->days());
	my $span  = DateTime::Span->from_datetimes(
		start => $now,
		end   => $end
	);
	$start->set_time_zone('UTC');
	$end->set_time_zone('UTC');

	Mojo::IOLoop->delay(
		sub {
			my ($delay) = @_;
			for my $source (@{$self->sources() // []}) {
				my $tx = $self->ua()->build_tx(REPORT => $source => {
						'Content-Type' => 'text/xml'
					} => sprintf(
						$filter,
						$self->format_timestamp_compact($start),
						$self->format_timestamp_compact($end),
					)
				);
				$self->ua()->start($tx => $delay->begin());
			}
		},
		sub {
			my ($delay, @transactions) = @_;

			Mojo::IOLoop::ForkCall->new()->run(
				sub {
					my @data;
					my $ical_data = $self->_extract_ical_data(@transactions);
					unless (defined $ical_data) {
						return [];
					}
					my $calendar = Data::ICal->new(
						data => $ical_data
					);
					unless ($calendar) {
						confess($calendar->error_message());
					}
					for my $event ($calendar->events($span, 'day')) {
						my $event_start = $event->start()->set_time_zone('UTC');
						my $event_end   = $event->end()->set_time_zone('UTC');
						if ($event_start >= $start && $event_end <= $end) {
							push @data, {
								start   => $self->format_timestamp($event_start),
								end     => $self->format_timestamp($event_end),
								summary => $event->summary()
							}
						}
					}
					return [
						sort {
							$a->{start} cmp $b->{start}
								|| $a->{summary} cmp $b->{summary}
						} @data
					];
				},
				sub {
					my ($fc, $err, $data) = @_;
					if ($err) {
						confess($err)
					}
					$self->update_status($data);
				}
			);
		},
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


sub _extract_ical_data {
	my ($self, @transactions) = @_;

	my @calendar_data;
	for my $transaction (@transactions) {
		$transaction->res()->dom('calendar-data')->each(sub {
			my ($entry) = @_;
			push @calendar_data, $self->_clean_entry(
				$entry->child_nodes->first()->content()
			);
		});
	}
	if (scalar @calendar_data > 0) {
		unshift @calendar_data, "BEGIN:VCALENDAR\n";
		push @calendar_data, 'END:VCALENDAR';
		return join('', @calendar_data);
	}
	else {
		return;
	}
}


sub _clean_entry {
	my ($self, $entry) = @_;

	my @lines = split(/(?:\r\n|\n)/x, $entry);
	my $result;
	my $in_alarm = 0;
	LINE: for my $line (@lines) {
		# Drop VALARM sections (may contain data that cannot be processed by Data::ICal)
		if ($line eq 'BEGIN:VALARM') {
				$in_alarm = 1;
		}
		elsif ($line eq 'END:VALARM') {
				$in_alarm = 0;
				next LINE;
		}
		if ($in_alarm || $line eq 'BEGIN:VCALENDAR' || $line eq 'END:VCALENDAR') {
			next LINE;
		}
		$result .= $line . "\n";
	}
	return $result;
}


=head2 has_css

Specialized method to indicate that this plugin has CSS resources.

=cut

sub has_css {
	return 1;
}

1;
