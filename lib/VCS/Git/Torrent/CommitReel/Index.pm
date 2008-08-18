
package VCS::Git::Torrent::CommitReel::Index;

=head1 NAME

VCS::Git::Torrent::CommitReel::Index

=cut

use DB_File;
use Moose;
use Storable qw( freeze thaw );
use IO::Plumbing qw(hose);

use VCS::Git::Torrent::CommitReel::Entry;

has 'index' =>
	isa => 'HashRef',
	is  => 'rw',
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		$self->open_index;
	};

has 'index_filename' =>
	isa => "Str",
	is => "ro",
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		my (@pair_sha1) = @{ $self->reel->reel_id };
		($self->state_dir."/reel-"
			 .join("-",map { substr($_, 0, 16) } @pair_sha1)
				 .".idx");
	};

has 'reel' =>
	isa => "VCS::Git::Torrent::CommitReel",
	is => "rw",
	weak_ref => 1,
	handles => [ 'git', 'plumb', "state_dir" ];

has 'cat_file_info' =>
	isa => 'ArrayRef',
	is => 'ro',
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		# yeah, this API could use a little simplification :)
		my $rdr = hose;
		my $wtr = hose;
		my $plumb = $self->plumb
			([ "cat-file", "--batch-check" ],
			 input => $wtr,
			 output => $rdr,
			);
		$plumb->execute;
		[ $rdr->in_fh, $wtr->out_fh, $plumb ];
	};

has 'commit_info' =>
	isa => 'ArrayRef',
	is => 'rw';

=head2 open_index

Open, and possibly create, the file that stores the commit reel index.
DB_File in DB_BTREE mode is currently used, with a numeric sort to the keys,
which are the offsets in the commit reel.  The values are frozen
VCS::Git::Torrent::CommitReel::Entry objects; see L<Storable>.

=cut

sub open_index {
	my $self = shift;
	my %index;
	my $x;

	# define the sort function; the offset is the hash index, so we
	# need to force numeric sorting not string compare
	$DB_BTREE->{'compare'} = sub { $_[0] <=> $_[1] };
	$x = tie %index, 'DB_File' => $self->index_filename,
		O_CREAT|O_RDWR, 0666, $DB_BTREE
			or die $!;

	$self->{db} = $x;

	\%index;
}

=head2 update_index

Update ourself to contain the latest entries from the commit reel.  This is
done by calling L<reel_revlist_iter> and freezing (see L<Storable>) the
resulting list into the index.

=cut

sub update_index {
	my $self = shift;
	my $iter = $self->reel_revlist_iter;

	my $inter_commit_size = 0;

	$self->commit_info([]);

	while ( my $rev = $iter->() ) {
		$inter_commit_size += $rev->size;

		if ( $rev->type eq 'commit' ) {
			push @{ $self->commit_info }, {
				in_repo => 1,
				offset => $rev->offset,
				objectid => $rev->objectid,
				size => $inter_commit_size,
				parents => $rev->parents,
			};

			$inter_commit_size = 0;
		}
	}
}

=head2 reel_revlist_iter() returns VCS::Git::Torrent::CommitReel::Entry

Using the currently available references in the index, determine what other
references are needed to bring us up to date.

Commits are ordered according to the RFC.
L<http://gittorrent.utsl.gen.nz/rfc.html#org-reels>

=cut

sub reel_revlist_iter {
	my $self = shift;

	my @refs = values %{ $self->reel->end->refs };
	my @not;
	if ( $self->reel->start ) {
		@not = values %{ $self->reel->start->refs };
	}

	my ($rev_list, $ctx) = $self->git->command_output_pipe
		("rev-list", "--date-order", "--reverse",
		 "--pretty=format:%P %ct",
		 @refs, @not ? ( "--not" => @not ) : () );

	my @peek;
	my $get_rev_list = sub {
		if ( @_ ) {
			unshift @peek, @_;
			return;
		}
		elsif ( @peek ) {
			return shift @peek;
		}
		return if not defined $rev_list;
		if (eof($rev_list)) {
			$self->git->command_close_pipe($rev_list, $ctx);
			undef($rev_list);
			return;
		}
		my ($commitid) = <$rev_list> =~ m{^commit (.*)} or die;
		my ($parents, $when) = <$rev_list> =~ m{^(.*) (\d+)$}
			or die;
		my %parents = map { $_ => 1 } split /\s+/, $parents;
		({ commitid => $commitid,
		   parents => \%parents,
		   when => $when });
	};

	# note: the fact we need to pre-populate this %seen may be a
	# good reason to say that reels should always include all the
	# objects required for the first revisions in them; it
	# introduces one point of bad scalability
	my %seen;
	if ( @not ) {
		my ($base, $ctx) = $self->git->command_output_pipe
			("rev-list", "--objects", @not );
		while ( my $rev = <$base> ) {
			chomp($rev);
			$seen{$rev}++;
		}
		$self->git->command_close_pipe($base, $ctx);
	}

	my @ready;
	my $commit_iter = sub {
		# keep grabbing items off the list, until we see one that
		# a) has a different commit date, or
		# b) has a parent which has not been written to the
		#    reel yet ("seen")
		my $next = $get_rev_list->() or return shift @ready;
		while ( $next and
			( !@ready or
			  $next->{when} == $ready[0]->{when} ) and
			not grep { not $seen{$_} }
			keys %{ $next->{parents} }
		      ) {
			push @ready, $next;
			$next = $get_rev_list->();
		}
		# put one back
		$get_rev_list->($next) if $next;

		# nothing left on @ready is not "ready to go"
		@ready = sort { $a->{commitid} cmp $b->{commitid} }
				@ready;

		return shift @ready;
	};

	my @objects;
	my @parents;
	my $offset = 0;
	my $git = $self->git;
	my $object_iter = sub {
		if ( !@objects ) {
			my $next_commit = $commit_iter->()
				or return;

			my $id = $next_commit->{commitid};
			@parents = keys(%{$next_commit->{parents}});

			@objects = grep { !$seen{$_->[0]}++ }
				$self->_commit_objects($id);
		}

		my $x = shift @objects;

		my %args = (
			offset   => $offset,
			type     => $x->[2],
			size     => $x->[1],
			objectid => $x->[0],
			($x->[3] ?
			 ( path  => $x->[3] ) : ()),
		);

		if ( $x->[2] eq 'commit' ) {
			$args{'parents'} = [ @parents ];
		}

		my $rev = VCS::Git::Torrent::CommitReel::Entry->new(%args);

		$offset += $rev->size;

		$self->index->{$offset} = freeze $rev;
		return $rev;
	};

	return $object_iter;
}

sub _commit_objects {
	my $self = shift;
	my $commitid = shift;

	my $pipe_read = $self->cat_file_info->[0];
	my $pipe_write = $self->cat_file_info->[1];
	$pipe_write->autoflush(1);

	my $git = $self->git;

	my $commit_size = do {
		print $pipe_write $commitid . "\n";
		(split(/ /, <$pipe_read>))[2];
	};
	my @deps = $git->command (qw(rev-list --objects), $commitid.'^!');

	# get information for all the objects between these two commits;
	# use git-cat-file --batch-check, asynchronously.
	my @x;
	my $x_item = 0;
	my $flush_pipe = sub {
		while ($x[$x_item] and
		       defined(my $line = <$pipe_read>)) {
			my $x = $x[$x_item++];
			(undef, $x->[2], $x->[1]) = split(/ /, $line);
		}
	};

	$pipe_write->autoflush(0);
	$pipe_read->blocking(0);

	# the sort order in the RFC is quite specific - objects must
	# have the objects they refer to come first.
	foreach my $d (sort { $a cmp $b } @deps) {
		my ($d_hash, $d_what) = split /\s+/, $d, 2;
		next if $d_hash eq $commitid;
		print $pipe_write $d_hash . "\n";
		push @x, [ $d_hash, undef, undef, $d_what ];

		# more than 42 or so answers backed up might end up
		# with us getting SIGPIPE
		$flush_pipe->() if (@x - $x_item > 42);
	}

	$pipe_write->autoflush(1);
	$pipe_read->blocking(1);
	$flush_pipe->();

	my @rfc_ordered;

	# an object is ready if:
	#   - it is a blob, or
	#   - it is a tree, but there are no other trees or
	#     blobs under a sub-path of this one.
	while ( @x ) {
		for (my $i = 0; $i <= $#x; $i++ ) {
			my $ready;
			if ( $x[$i][2] eq "blob" ) {
				$ready = 1;
			}
			elsif ( $x[$i][2] eq "tree" ) {
				my $path = $x[$i][3];
				my $pat = $path ? qr{^\Q$path\E/} : qr{.};
				$ready = !grep { $_->[3] && $_->[3] =~ m{$pat} }
					@x[$i+1..$#x];
			}
			else {
				confess "encountered strange object "
					."'$x[$i][2]'";
			}
			if ( $ready ) {
				push @rfc_ordered, $x[$i];
				@x=(@x[0..$i-1], @x[$i+1..$#x]);
				$i = -1;
			}
		}
	}

	push @rfc_ordered, [ $commitid, $commit_size, "commit" ];
	@rfc_ordered;
}

=head2 size() returns Int

Returns the total length of the reel

=cut

sub size {
	my $self = shift;

	$self->open_index unless $self->{db};

	my ($key, $val);
	$self->{db}->seq($key, $val, R_LAST);

	my $last = thaw $val;
	$last->offset + $last->size;
}

1;
