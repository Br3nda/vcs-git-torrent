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
#	use_ok('VCS::Git::Torrent::PWP::Message::Blocks');
}

# In this test, two peers connect and exchange reel (and reference)
# information

my $repo_hash = '501d' x 10;

my $git_1 = Git->repository('.');
my $git_2 = tmp_git();

my $torrent_1 = VCS::Git::Torrent->new(
	repo_hash => $repo_hash,
	git => $git_1,
);

my $torrent_2 = VCS::Git::Torrent->new(
	repo_hash => $repo_hash,
	git => $git_2,
);

# for now, we'll use a hard-coded ref which is known to be in the
# history of this project.
my $TEST_COMMIT = '7377253c66201c515f723f909830b3557fb6fa74';

my $reference_1 = VCS::Git::Torrent::Reference->new(
	torrent => $torrent_1,
	tagged_object => $TEST_COMMIT,
	tagger => 'Nobody <dev@null.org>',
	tagdate => '2008-07-18 12:00:00-0400',
	comment => "Created by $0",
	refs => {
		'refs/heads/master' => $TEST_COMMIT,
	},
);
ok($reference_1, 'Reference created');

my $reel_1 = VCS::Git::Torrent::CommitReel::Local->new(
	torrent => $torrent_1,
	end => $reference_1,
);
ok($reel_1, 'made the reel OK');

# this also gives the reel a link to the torrent
$torrent_1->reels([$reel_1]);

my ($port_1, $port_2) = @{ random_port_pair() };

my $peer_1 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_1,
	torrent => $torrent_1,
	peer_id => 'AlphaPeer1AlphaPeer1',
	reels => [ $reel_1 ],
);
ok($peer_1, 'Peer created');

my $peer_2 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_2,
	torrent => $torrent_2,
	peer_id => 'BravoPeer2BravoPeer2',
);
ok($peer_2, 'Another peer created');

$peer_1->connect("localhost:$port_2");

# let the connect get processed
Coro::Event::loop(1);

# ask $peer_1 for reels
my $victim = $peer_2->connections->[0]->remote;
$peer_2->send_message($victim, GTP_PWP_REELS);

# let our message get there, and the reply back to us
Coro::Event::loop(1);

is(scalar(@{$peer_2->torrent->reels}), 1, 'peer_2 received a reel');
my $reel_2 = $peer_2->torrent->reels->[0];

$peer_2->send_message($victim, GTP_PWP_BLOCKS, $reel_2);

Coro::Event::loop(1);

my $bits = @{ $peer_2->connections->[0]->remote->reels->[0]->commit_info };
is($bits, 71, 'received 71 commit bits');

