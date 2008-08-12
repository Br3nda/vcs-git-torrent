#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use t::TestUtils;
use VCS::Git::Torrent;
use List::Util qw(first max);
use MooseX::TimestampTZ;

BEGIN { use_ok('VCS::Git::Torrent::CommitReel::Local') }

# This test script tests the "VCS::Git::Torrent::CommitReel::Index"
# module

my $git = Git->repository(".");

my $dummy_torrent = VCS::Git::Torrent->new
	( repo_hash => "6549" x 10,
	  git => $git,
	);

# for now, we'll use a hard-coded ref which is known to be in the
# history of this project.
my $TEST_COMMIT = "5e8f6a7807a378259daa3b91314c8c9775fa160e";

my $reference = VCS::Git::Torrent::Reference->new
	( tagged_object => "0"x40,
	  tagger => "R.U. Interested <whoever\@example.com>",
	  tagdate => timestamptz,
	  comment => "",
	  torrent => $dummy_torrent,
	  refs => { "refs/heads/master" => $TEST_COMMIT } );

my $reel = VCS::Git::Torrent::CommitReel::Local->new
	( end => $reference,
	  torrent => $dummy_torrent,
	);

ok($reel, "made the reel OK");

my $reel_index = $reel->index;

ok($reel_index, 'Index was created automatically');

my $index_file = $reel_index->index_filename;
if ( -e $index_file ) {
	unlink($index_file)
		or warn("failed to remove $index_file; $!");
}

my $reel_iter = $reel_index->reel_revlist_iter;

my $first_obj = $reel_iter->();
is($first_obj->type, "blob", "first object is a blob");

my (%offset, @reel);
my $pos = 0;
$offset{$first_obj->objectid} = $pos;
$reel[$pos]=$first_obj;
my $last_commit_pos = -1;

my %fail;
my $fail = sub {
	my $category = shift;
	my $o1 = shift;
	my $o2 = shift;
	push @{ $fail{$category}||= [] }, [ $o1, $o2 ];
};

my $cue = $first_obj->size;
while ( my $o = $reel_iter->() ) {

	if ( $o->offset != $cue ) {
		$fail->("cue", $o->offset, $cue);
	}
	$cue += $o->size;

	if ( exists $offset{$o->objectid} ) {
		fail("object seen repeated");
		last;
	}

	$reel[++$pos] = $o;
	$offset{$o->objectid} = $pos;

	if ( $ENV{DEBUG_REEL}) {
		diag("offset $pos: ".substr($o->objectid, 0, 16)." "
		     .($o->path ||
		       ( $o->type eq "commit" ? "(commit)" : "/") ));
	}

	my @deps;
	if ( $o->type eq "commit" ) {
		$last_commit_pos = $pos;
		@deps = map { m{([a-f0-9]{40})}g }
			$git->command
				("log", "-1", "--pretty=format:%P",
				 $o->objectid );
	}
	if ( $o->type eq "tree" ) {
		@deps = map { m{([a-f0-9]{40})}g }
			$git->command("ls-tree", $o->objectid);
	}

	my $last_dep = -1;
	for my $dep ( @deps ) {
		if ( not exists $offset{$dep} ) {
			$fail->("dependency", $o, $dep);
		}
		else {
			$last_dep = max($offset{$dep}, $last_dep);
		}
	}

	if ( $last_dep == -1 or
	     ($o->type ne "commit" and $last_dep < $last_commit_pos) ) {
		$last_dep = $last_commit_pos + 1;
	}

	my $x;
	my @betwixt;
	if ( $o->type eq "commit" ) {
		@betwixt = grep { $_->type eq "commit" }
			@reel[$last_dep+1..$#reel-1];
	}
	else {
		for $x ( @reel[$last_dep+1..$#reel-1] ) {
			if ( $x->type eq "commit" ) {
				@betwixt=();
			}
			else {
				push @betwixt, $x;
			}
		}
	}

	for $x ( @betwixt ) {
		if ( $x->objectid gt $o->objectid ) {
			if ( $o->type eq "commit" ) {
				my $o_when = $git->command
					("log", "-1", "--pretty=format:%ct",
					 $o->objectid);
				my $x_when = $git->command
					("log", "-1", "--pretty=format:%ct",
					 $x->objectid);
				if ( $o_when == $x_when ) {
					$fail->("sha1", $o, $x);
				}
				elsif ( $o_when < $x_when ) {
					$fail->("date", $o, $x);
				}
			}
			else {
				$fail->("sha1", $o, $x);
			}
		}
	}
}

for my $category ( qw(dependency sha1 order date cue) ) {
	my $test_name =
		($category ne "cue"
		 ? "objects in correct order according to $category rule"
		 : "offsets correct");

	if ( exists $fail{$category} ) {
		fail($test_name);
		diag("details:");
		for my $failure ( @{ $fail{$category} } ) {
			my ($o1, $o2) = map {
				substr(ref($_)?$_->objectid:$_, 0, 16)
			} @{ $failure };
			if ( $category eq "cue" ) {
				diag("object at offset $o1, running offset was $o2");
			}
			else {
				diag("$o1 seen after $o2");
			}
		}
	}
	else {
		pass($test_name);
	}
}

is($reel->size, $cue, "Reel knows its size");

my ($all, $ctx) = $git->command_output_pipe
	("rev-list", "--objects", "--reverse", $TEST_COMMIT);

my $missing = 0;
my $first;
while ( <$all> ) {
	if ( m{([a-f0-9]{40})} and
	     !exists $offset{$1} ) {
		$missing++;
		$first ||= $1;
	}
}

is($missing, 0, "no objects were missing")
	or diag("first missing: $first");

is(scalar(@{$reel->commit_info}), 28, 'reel has correct number of commits');

