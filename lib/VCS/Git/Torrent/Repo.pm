
package VCS::Git::Torrent::Repo;

use VCS::Git::Torrent;

use Moose;

has 'alternatives' =>
	isa => 'ArrayRef[VCS::Git::Torrent::sha1_hex]',
	is  => "ro";

has 'description' =>
	isa => 'Str',
	is  => "ro";

has 'pubkey' =>
	isa => 'Str',
	is  => "ro";

1;
