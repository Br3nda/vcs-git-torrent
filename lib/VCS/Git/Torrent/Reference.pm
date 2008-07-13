
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
	is => "ro";

has 'tagger' =>
	isa => "Str";

has 'tagdate' =>
	isa => "TimestampTZ",
	required => 1,
	coerce => 1,
	default => \&timestamptz;

has 'comment' =>
	isa => "Str";

has 'refs' =>
	is => "ro",
	isa => "HashRef[VCS::Git::Torrent::sha1_hex]";

1;
