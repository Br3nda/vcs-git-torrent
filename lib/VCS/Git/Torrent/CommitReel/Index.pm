
package VCS::Git::Torrent::CommitReel::Index;

use DB_File;
use Moose;
use Storable qw( freeze thaw );

use VCS::Git::Torrent::CommitReel::Entry;
use VCS::Git::Torrent::CommitReel::RevList;

has 'index' =>
	isa => 'HashRef',
	is  => 'rw',
	default => sub {
		my $self = shift;
		$self->open_index;
	};

sub open_index {
	my $self = shift;
	my %index;
	my $x;

	# define the sort function; the offset is the hash index, so we
	# need to force numeric sorting not string compare
	$DB_BTREE->{'compare'} = sub { $_[0] <=> $_[1] };
	$x = tie %index, 'DB_File' => 'reel.idx',
		O_CREAT|O_RDWR, 0666, $DB_BTREE;

	$self->{db} = $x;

	\%index;
}

has 'git' =>
	isa => 'Git',
	is  => 'ro',
	required => 1;

sub update_index {
	my $self = shift;
	my ($key, $val);
	my $last_sha1;
	my @revlist;
	my $rev;
	my $offset;

	if ( $self->{db}->seq($key, $val, R_LAST) ) { # assume empty
		$last_sha1 = undef;
	}
	else {
		my $last_entry = thaw $val;
		$last_sha1 = $last_entry->objectid;
	}

	@revlist = reel_revlist($self->git, '--all');

	if ( defined $last_sha1 ) {
		while($rev = shift @revlist) {
			last if ( $rev->[3] eq $last_sha1 );
		}
	}
#print STDERR 'last SHA1 is: ' . $last_sha1 . "\n" if ( defined $last_sha1 );
	foreach(@revlist) {
		$offset = $_->[0];

		$rev = VCS::Git::Torrent::CommitReel::Entry->new(
			offset   => $offset,
			type     => $_->[1],
			size     => $_->[2],
			objectid => $_->[3],
			pathctid => $_->[4],
		);
#print STDERR 'freezing: ' . sprintf("%8i %8s %8i %s %s\n", @$_);
		$self->index->{$offset} = freeze $rev;
	}
}

1;
