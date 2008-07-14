
package VCS::Git::Torrent::CommitReel;

=head1 NAME

VCS::Git::Torrent::CommitReel - a list of commits between two References

=head1 SYNOPSIS

=cut

use Moose;
use VCS::Git::Torrent;
use VCS::Git::Torrent::Reference;
use VCS::Git::Torrent::CommitReel::Index;

has 'reel_id' =>
	isa => "ArrayRef[VCS::Git::Torrent::sha1_hex]";

has 'torrent' =>
	isa => "VCS::Git::Torrent",
	is => "rw",
	weak_ref => 1,
	handles => [ 'git' ];

has 'start' =>
	isa => "VCS::Git::Torrent::Reference",
	is  => "ro",
	required => 0;

has 'end' =>
	isa => "VCS::Git::Torrent::Reference",
	is  => "ro",
	required => 1;

has 'index' =>
	isa => "VCS::Git::Torrent::CommitReel::Index",
	is => "ro",
	default => sub {
		VCS::Git::Torrent::CommitReel::Index->new(),
	};

=head2 BUILD

Moose sub which is called on object creation; makes the index for the reel

=cut

sub BUILD {
	my $self = shift;
	$self->index->reel($self);
}

use Digest::SHA1 qw(sha1_hex);

=head2 reel_id

Return a reference to an array as follows:

[ tag_id_of_start_reference, tag_id_of_end_reference ]

=cut

sub reel_id {
	my $self = shift;
	[ $self->start ? $self->start->tag_id : sha1_hex(""),
	  $self->end->tag_id ];
}

1;
