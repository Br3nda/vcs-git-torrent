
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
	required => 1,
	handles => [ 'git', 'plumb', "state_dir" ];

has 'start' =>
	isa => "VCS::Git::Torrent::Reference|VCS::Git::Torrent::sha1_hex",
#	isa => "VCS::Git::Torrent::Reference",
	is  => "ro",
	required => 0;

has 'end' =>
	isa => "VCS::Git::Torrent::Reference|VCS::Git::Torrent::sha1_hex",
#	isa => "VCS::Git::Torrent::Reference",
	is  => "ro",
	required => 1;

has 'size' =>
	isa => "Int",
	is => "ro",
	required => 1;

use Digest::SHA1 qw(sha1_hex);

=head2 reel_id returns [ sha1_hex, sha1_hex ]

Return a reference that uniquely identifies the reel; that is, the ID
of the tag objects that delimit its start and end.  This is used in
various parts of the protocol to uniquely identify a reel, and is
defined in section I<FIXME>.

=cut

sub reel_id {
	my $self = shift;
	[ $self->start ? $self->start->tag_id : sha1_hex(""),
	  $self->end->tag_id ];
}

1;
