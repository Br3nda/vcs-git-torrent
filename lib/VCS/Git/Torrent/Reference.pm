
package VCS::Git::Torrent::Reference;

use Moose;
use VCS::Git::Torrent;
use MooseX::TimestampTZ;

has 'torrent' =>
	is => "rw",
	weak_ref => 1,
	isa => "VCS::Git::Torrent",
	handles => [ "git", "repo_hash" ];

has 'tag_id' =>
	isa => "VCS::Git::Torrent::git_object_id",
	is => "ro",
	required => 1;

has 'tagged_object' =>
	isa => "VCS::Git::Torrent::git_object_id",
	is => "ro",
	required => 1;

has 'tagger' =>
	isa => "Str",
	is => "ro",
	required => 1;

has 'tagdate' =>
	isa => "TimestampTZ",
	required => 1,
	coerce => 1,
	is => "ro",
	lazy => 1,
	default => \&timestamptz;

has 'comment' =>
	isa => "Str",
	required => 1,
	is => "ro";

has 'refs' =>
	is => "ro",
	isa => "HashRef[VCS::Git::Torrent::sha1_hex]",
	required => 1;

sub BUILD {
	my $self = shift;
	my $tag_id = $self->tag_id;
	if ( $tag_id ) {
		# loading a reference from disk
		my @data = $self->git->command("cat-file", "tag", $tag_id);

		# ... parse into the relevant fields ...
	}
	else {
		# creating a references object from scratch
		die "no refs or tag_id given"
			unless $self->refs;
	}
}

1;
