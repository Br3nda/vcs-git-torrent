
# temporary, definitions from VCS::Git
package VCS::Git;

use Moose::Util::TypeConstraints;

enum "VCS::Git::object_type" => qw(blob commit tag tree);
subtype "VCS::Git::SHA1" => as "Str" => where { /^[0-9a-f]{40}$/ };
###

package VCS::Git::Torrent::CommitReel::Entry;

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
