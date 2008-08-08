
package VCS::Git::Torrent::CommitReel::Local;

=head1 NAME

VCS::Git::Torrent::CommitReel::Local - a commit reel with an index

=head1 SYNOPSIS

=cut

use Moose;
extends 'VCS::Git::Torrent::CommitReel';

has 'index' =>
	isa => "VCS::Git::Torrent::CommitReel::Index",
	is => "ro",
	default => sub {
		VCS::Git::Torrent::CommitReel::Index->new(),
	};

has '+size' =>
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->index->size;
	};

# make sure the index has a reference to us
sub BUILD {
	my $self = shift;
	$self->index->reel($self);
}

1;
