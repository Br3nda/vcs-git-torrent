
package VCS::Git::Torrent::CommitReel::Index;

use DB_File;
use Moose;
use Storable qw( freeze thaw );

use VCS::Git::Torrent::CommitReel::Entry;

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

	my $iter = $self->reel_revlist_iter;

	while ( my $rev = $iter->() ) {
		$self->index->{$rev->offset} = freeze $rev;
	}
}

sub reel_revlist_iter {
	my $self = shift;

	no strict 'refs';
	sub {
		&{"..."}();
		$offset = $_->[0];

		$rev = VCS::Git::Torrent::CommitReel::Entry->new(
			offset   => $offset,
			type     => $_->[1],
			size     => $_->[2],
			objectid => $_->[3],
			pathctid => $_->[4],
		);
	};

1;
