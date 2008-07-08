
package VCS::Git::Torrent::CommitReel::Index;

use DB_File;
use Moose;
use Storable;

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

	if ( $self->{db}->seq($key, $val, R_LAST) )
	{ # assume empty?
		;
	}
	else
	{
		my $last_entry = thaw $val;
		$last_sha1 = $last_entry->objectid;
	}
}

1;
