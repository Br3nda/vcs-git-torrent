
# temporary, definitions from VCS::Git
package VCS::Git;

use Moose::Util::TypeConstraints;

enum "VCS::Git::object_type" => qw(blob commit tag tree);
subtype "VCS::Git::SHA1" => as "Str" => where { /^[0-9a-f]{40}$/ };
###

package VCS::Git::Torrent::CommitReel::Entry;

=head1 NAME

VCS::Git::Torrent::CommitReel::Entry - an entry in the RFC-ordered commit reel

=head1 DESCRIPTION

An Entry consists of the following:

=over 4

=item offset

=item type (VCS::Git::object_type)

=item size

=item objectid

=item path (for debugging)

=back

=cut

use Moose;
use Storable;

has 'offset' =>
	isa => 'Int',
	is  => 'rw';

has 'type' =>
	isa => 'VCS::Git::object_type',
	is  => 'ro';

has 'size' =>
	isa => 'Int',
	is  => 'ro';

has 'objectid' =>
	isa => 'VCS::Git::SHA1',
	is  => 'ro';

has 'path' => # for debugging
	isa => 'Str',
	is  => 'ro';

1;
