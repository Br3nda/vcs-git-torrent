
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
	handles => [ qw(size) ],
	default => sub {
		my $self = shift;
		VCS::Git::Torrent::CommitReel::Index->new( reel => $self ),
	};

# make sure the index has a reference to us
sub BUILD {
	my $self = shift;
	$self->index->reel($self);
}

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

package VCS::Git::Torrent::CommitReel::Remote;
use Moose;
# this is a bit of a hack; it should be a role, that CommitReel::Local
# consumes.
extends 'VCS::Git::Torrent::CommitReel';

# also, this union type here makes using this object class problematic;
# the 'reference' should also have this behaviour of being allowed to
# be a proxy object.
has '+start' =>
	isa => "VCS::Git::Torrent::Reference|VCS::Git::Torrent::sha1_hex";
has '+end' =>
	isa => "VCS::Git::Torrent::Reference|VCS::Git::Torrent::sha1_hex";

# this will complain about there already being a 'size' method...
has 'size' =>
	isa => "Int",
	is => "ro",
	required => 1;

has '+torrent' =>
	required => 0;

1;
