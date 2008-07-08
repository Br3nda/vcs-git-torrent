#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

BEGIN { use_ok('Git') }
BEGIN { use_ok('VCS::Git::Torrent::CommitReel::Index') }

# This test script tests the "VCS::Git::Torrent::CommitReel::Index"
# module

my $git = Git->repository('.'); # TODO: make a fake repo on the fly
ok($git, 'We have a git repo');

my $reel_index = VCS::Git::Torrent::CommitReel::Index->new( git => $git );
ok($reel_index, 'The reel sees the repo');
