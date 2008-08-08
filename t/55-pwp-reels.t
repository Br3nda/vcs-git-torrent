#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

BEGIN {
	use_ok('t::TestUtils');

	use_ok('Coro');
	use_ok('Coro::Event');
	use_ok('VCS::Git::Torrent');
	use_ok('VCS::Git::Torrent::CommitReel::Local');
	use_ok('VCS::Git::Torrent::Peer::Async');
	use_ok('VCS::Git::Torrent::PWP', qw(:pwp_constants));
}

# In this test, two peers connect and exchange reel (and reference)
# information

my $git = Git->repository('.');

my $torrent = VCS::Git::Torrent->new(
	repo_hash => '501d' x 10,
	git => $git,
);

# for now, we'll use a hard-coded ref which is known to be in the
# history of this project.
my $TEST_COMMIT = '7377253c66201c515f723f909830b3557fb6fa74';

my $reference = VCS::Git::Torrent::Reference->new(
	torrent => $torrent,
	tagged_object => $TEST_COMMIT,
	tagger => 'Nobody <dev@null.org>',
	tagdate => '2008-07-18 12:00:00-0400',
	comment => "Created by $0",
	refs => {
		'refs/heads/master' => $TEST_COMMIT,
	},
);
ok($reference, 'Reference created');

my $reel = VCS::Git::Torrent::CommitReel::Local->new(
	torrent => $torrent,
	end => $reference,
);
ok($reel, 'made the reel OK');

# this also gives the reel a link to the torrent
$torrent->reels([$reel]);

my ($port_1, $port_2) = @{ random_port_pair() };

my $peer_1 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_1,
	torrent => $torrent,
	peer_id => 'AlphaPeer1AlphaPeer1',
);
ok($peer_1, 'Peer created');

my $peer_2 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_2,
	torrent => $torrent,
	peer_id => 'BravoPeer2BravoPeer2',
	reels => [ $reel ],
);
ok($peer_2, 'Another peer created');

$peer_1->connect("localhost:$port_2");

# let the connect get processed
Coro::Event::loop(1);

# ask $peer_2 for reels
my $victim = $peer_1->connections->[0]->remote;
$peer_1->send_message($victim, GTP_PWP_REELS);

# let our message get there, and the reply back to us
Coro::Event::sweep;
cede;

Coro::Event::loop(1);

