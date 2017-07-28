package App::Web::StatusDashboard::Plugin::XLSX;

use Mojo::Base 'App::Web::StatusDashboard::PollingPlugin';

# ABSTRACT: Simple plugin to fetch a XLSX spreadsheet and display its data

use Carp;
use Spreadsheet::XLSX;
use File::Temp;
use Encode;


=head1 DESCRIPTION

App::Web::StatusDashboard::Plugin::XLSX is a plugin to fetch a XLSX spreadsheet
and display the contained data.

=head1 METHODS

=cut


has 'url';


=head2 new

Constructor, creates new instance. See L<new|App::Web::StatusDashboard::PollingPlugin/new>
in L<App::Web::StatusDashboard::PollingPlugin|App::Web::StatusDashboard::PollingPlugin> for
more parameters.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item url

URL of the XLSX spreadsheet you want to display.

=back

=head2 update

Update the status in the dashboard.

=cut

sub update {
	my ($self) = @_;

	Mojo::IOLoop->delay(
		sub {
			my ($delay) = @_;
			$self->ua()->max_redirects(5);
			$self->ua()->get($self->url() => $delay->begin());
		},
		sub {
			my ($delay, $tx) = @_;
			if ($self->transactions_ok($tx)) {
				my $tmp_file = File::Temp->new();
				print {$tmp_file} $tx->res()->body()
					or confess('Failed to write data to temporary file');
				$tmp_file->close();
				my $xlsx = Spreadsheet::XLSX->new($tmp_file->filename());
				$self->update_status({
					sheets => [ $self->_convert_xlsx($xlsx) ],
				});
			}
		}
	)->catch(sub {
		my ($delay, $err) = @_;
		$self->log_update_error($err);
	})->wait;

	return;
}


sub _convert_xlsx {
	my ($self, $xlsx) = @_;

	my @result;
	foreach my $sheet (@{$xlsx->{Worksheet}}) {
		$sheet->{MaxRow} ||= $sheet->{MinRow};
		$sheet->{MaxCol} ||= $sheet->{MinCol};

		my @rows;
		foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
			my @cells;
			foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
				my $cell = $sheet->{Cells}[$row][$col];
				push @cells, !$cell ? undef : {
					value => decode('UTF-8', $cell->value()),
					type  => $cell->type(),
				};
			}

			push @rows, {
				cells => \@cells,
			};
		}

		push @result, {
			name => $sheet->{Name},
			rows => \@rows,
		};
	}

	return @result;
}


1;
