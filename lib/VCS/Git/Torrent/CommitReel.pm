
package VCS::Git::Torrent::CommitReel;

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

sub BUILD {
	my $self = shift;
	$self->index->reel($self);
}

use Digest::SHA1 qw(sha1_hex);

sub reel_id {
	my $self = shift;
	[ $self->start ? $self->start->tag_id : sha1_hex(""),
	  $self->end->tag_id ];
}

1;
