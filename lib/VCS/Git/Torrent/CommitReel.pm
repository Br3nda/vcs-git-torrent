
package VCS::Git::Torrent::CommitReel;

use Moose;
use VCS::Git::Torrent;
use VCS::Git::Torrent::Reference;

has 'reel_id' =>
	isa => "ArrayRef[VCS::Git::Torrent::sha1_hex]";

has 'start' =>
	isa => "VCS::Git::Torrent::Reference",
	is  => "ro",
	required => 0;

has 'end' =>
	isa => "VCS::Git::Torrent::Reference",
	is  => "ro",
	required => 1;

use Digest::SHA1 qw(sha1_hex);

sub reel_id {
	my $self = shift;
	[ $self->start ? $self->start->tag_id : sha1_hex(""),
	  $self->end->tag_id ];
}

1;
