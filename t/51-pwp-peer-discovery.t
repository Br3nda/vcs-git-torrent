#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

BEGIN {
	use_ok('t::TestUtils');

	use_ok('Coro');
	use_ok('Coro::Event');
	use_ok('VCS::Git::Torrent');
	use_ok('VCS::Git::Torrent::Peer::Async');
	use_ok('VCS::Git::Torrent::PWP', qw(:pwp_constants));
}

# peers connect and exchange peer info

my $repo_hash = '501d' x 10;

my $git_1 = tmp_git();
my $git_2 = tmp_git();
my $git_3 = tmp_git();
my $git_4 = tmp_git();

my $torrent_1 = VCS::Git::Torrent->new(
	repo_hash => $repo_hash,
	git => $git_1,
);

my $torrent_2 = VCS::Git::Torrent->new(
	repo_hash => $repo_hash,
	git => $git_2,
);

my $torrent_3 = VCS::Git::Torrent->new(
	repo_hash => $repo_hash,
	git => $git_3,
);

my $torrent_4 = VCS::Git::Torrent->new(
	repo_hash => $repo_hash,
	git => $git_4,
);

# FIXME make port be chosen by OS
my ($port_1, $port_2) = @{ random_port_pair() };
my ($port_3, $port_4) = @{ random_port_pair() };

my $peer_1 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_1,
	torrent => $torrent_1,
	peer_id => 'AlphaPeer1AlphaPeer1',
);
ok($peer_1, 'peer 1 created');

my $peer_2 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_2,
	torrent => $torrent_2,
	peer_id => 'BravoPeer2BravoPeer2',
);
ok($peer_2, 'peer 2 created');

my $peer_3 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_3,
	torrent => $torrent_3,
	peer_id => 'AlphaPeer3AlphaPeer3',
);
ok($peer_3, 'peer 3 created');

my $peer_4 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_4,
	torrent => $torrent_4,
	peer_id => 'BravoPeer4BravoPeer4',
);
ok($peer_4, 'peer 4 created');

$peer_1->connect("localhost:$port_2");
$peer_1->connect("localhost:$port_3");
$peer_4->connect("localhost:$port_1");

# let the connects get processed
Coro::Event::loop(1);

my $victim = $peer_4->connections->[0]->remote;
$peer_4->send_message($victim, GTP_PWP_PEERS);

Coro::Event::loop(1);

is(@{$peer_4->knows}, 2, 'peer 4 knows 2 other peers now');
is($peer_4->knows->[0]->peer_id, 'BravoPeer2BravoPeer2', 'got peer 2');
is($peer_4->knows->[1]->peer_id, 'AlphaPeer3AlphaPeer3', 'got peer 3');

