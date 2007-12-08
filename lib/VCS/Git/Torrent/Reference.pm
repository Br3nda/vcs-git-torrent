
package VCS::Git::Torrent::Reference;

use Moose;
use VCS::Git::Torrent;
use MooseX::TimestampTZ;

has 'repo_hash' =>
	isa => "VCS::Git::Torrent::repo_hash",
	is => "ro",
	required => 1,
	lazy => 1,
	default => sub {
		&{"..."};
	};

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

1;
