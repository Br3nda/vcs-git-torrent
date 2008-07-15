
package VCS::Git::Torrent::Peer::Async::State;

=head1 NAME

VCS::git::Torrent::Peer::Async::State

=head1 DESCRIPTION

Contains the L<Coro> object as C<coro>.

Provides the C<trace> debugging function.

=cut

use Moose::Role;

use Coro;
use warnings;
use strict;

has 'coro' =>
	isa => "Coro",
	is => "ro",
	handles => [qw( ready is_ready cancel join on_destroy prio
			nice desc throw )],
	required => 1,
	default => sub {
		my $self = shift;
		async { $self->trace(sub{"_run"}); $self->_start };
	};

sub BUILD {
	my $self = shift;
	$self->trace(sub { "built!" });
}

requires '_start';

my %counters;
my $i;
has 'uniqueid' =>
	isa => "Int",
	is => "ro",
	default => sub {
		my $self = shift;
		++$counters{ref($self)};
	};

use Sub::Exporter -setup =>
	{ exports => ['trace'],
	  groups => { default => ['trace'] } };

use constant DEBUG => 0;

=head2 trace(&coderef)

If C<DEBUG> is set, print out some debugging by calling the passed coderef.

=cut

BEGIN {
	if ( DEBUG ) {
		*trace = sub(&) {
			my $self = shift;
			my $block = shift;
			print STDERR ref($self)."[".$self->uniqueid."]: "
				.$block->()."\n";
		};
	} else {
		*trace = sub(&) { };
	}
}

1;
