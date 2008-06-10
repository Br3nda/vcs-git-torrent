#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

t::RevList - helper module for test suite

=head1 SYNOPSIS

 require t::RevList;

 my @reel = reel_revlist($repo, @revspec);

=head1 DESCRIPTION

This test module deals with fetching RFC-normative revision lists, but
not necessarily very quickly.

=head2 reel_revlist($repo, @revspec)

Given a commit reel ending by the `rev-list' arguments C<@revspec>,
return a RFC-correct ordering of objects within that reel, with
offsets.

Does not currently deal with reels that do not start at the beginning
of history.

Returns a list of:

  [ offset, type, length, SHA1 ]

=cut

use Carp qw(croak confess);

sub reel_revlist {
	my $repo = shift;
	my @revspec = @_;

	my ($fh, $c) = $repo->command_output_pipe
		(qw(rev-list --date-order --reverse),
		 "--pretty=format:%P %ct", @revspec);

	my @revs;
	my %seen;
	my $last;

	# check that 'git rev-list --date-order' orders commits in an
	# RFC-compliant way.
	do {
		my ($commitid) =
			<$fh> =~ m{^commit (.*)} or last;
		my ($parents, $when) =
			<$fh> =~ m{^(.*) (\d+)$} or last;
		my %parents = map { $_ => 1 } split /\s+/, $parents;

		for ( keys %parents ) {
			$seen{$_} or confess "saw commit $commitid before parent";
		}

		# check that this commit belongs after the last
		# commit, if it wasn't a parent.
		if ( $last and not exists $parents{$last->{commitid}} ) {
			if ( $last->{when} > $when ) {
				confess "$last->{commitid} newer than $commitid";
			}
			elsif ( $last->{when} == $when ) {
				# tie breaker - commit ID
				if ( $last->{commitid} ge $commitid ) {
					confess "$last->{commitid} higher SHA1 than $commitid";
				}
			}
		}

		$last = { commitid => $commitid,
			  when => $when,
			  };
		$seen{$commitid}++;
		push @revs, $commitid;

	} while ( not eof($fh));

	my $offset = 0;

	my @reel;

	foreach(@revs) {
		my $o_hash = (split(/\s+/))[0];
		my $o_size = $repo->command('cat-file', '-s', $o_hash);
		my $o_type = $repo->command('cat-file', '-t', $o_hash);
		chomp($o_type);

		my @deps = $repo->command (qw(rev-list --objects), $o_hash . '^!');
		shift @deps;

		# the sort order in the RFC is quite specific -
		# objects must have the objects they refer to come
		# first.

		my @x;
		foreach my $d (sort { $a cmp $b } @deps) {
			my ($d_hash, $d_what) = split /\s+/, $d, 2;
			my $d_size = $repo->command('cat-file', '-s', $d_hash);
			my $d_type = $repo->command('cat-file', '-t', $d_hash);
			chomp($d_type);
			push @x, [ $d_hash, $d_size, $d_type, $d_what ];
		}

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
					$ready = !grep { $_->[3] =~ m{$pat} }
						@x[$i+1..$#x];
				}
				else {
					confess "encountered strange object '$x[$i][2]'";
				}
				if ( $ready ) {
					push @rfc_ordered, $x[$i];
					@x=(@x[0..$i-1], @x[$i+1..$#x]);
					$i = -1;
				}
			}
		}

		for ( @rfc_ordered ) {
			push @reel, [ $offset, $_->[2], $_->[1], $_->[0] ];
			$offset += $_->[1];
		}

		push @reel, [ $offset, $o_type, $o_size, $o_hash ];
		$offset += $o_size;
	}

	return @reel;
}

1;
