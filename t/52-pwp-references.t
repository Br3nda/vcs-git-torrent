#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use MooseX::TimestampTZ;

# In this test script, a node joins a swarm that has a more up-to-date
# reference list than the one it got from the tracker, and updates its
# reference list from a peer.

BEGIN {
	use_ok('t::TestUtils');

	use_ok('Coro');
	use_ok('Coro::Event');
	use_ok('VCS::Git::Torrent');
	use_ok('VCS::Git::Torrent::Peer::Async');
	use_ok('VCS::Git::Torrent::PWP', qw(:pwp_constants));
	use_ok('VCS::Git::Torrent::Reference');
}

my $path = mk_tmp_repo();
my $git = Git->repository($ENV{PWD} . '/' . $path);
ok($git, 'git repo created');

my $t = VCS::Git::Torrent->new(
	repo_hash => '501d' x 10,
	git => $git,
);
ok($t, 'gittorrent created');

qx(echo foo >> $path/bar);
$git->command('add', 'bar');
$git->command('commit', '-a', '-m baz');
my $sha1 = $git->command_oneline('show-ref', '-s', 'master');
like($sha1, qr/[[:xdigit:]]{40}/, 'object inserted successfully');

my $ref = VCS::Git::Torrent::Reference->new(
	torrent => $t,
	tagged_object => $sha1,
	refs => { 'HEAD' => $sha1 },
	tagger => 'Elanour Rigby <nowhereman@example.com>',
	tagdate => timestamptz,
	comment => "Ah, look at all the lonely people\n",
);
ok($ref, 'Reference created');

$t->references([$ref]);

my ($port_1, $port_2) = @{ random_port_pair() };

my $peer_1 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_1,
	torrent => $t,
	peer_id => 'AlphaPeer1AlphaPeer1',
);
ok($peer_1, 'Peer created');

my $path2 = mk_tmp_repo();
my $git2 = Git->repository($ENV{PWD} . '/' . $path2);
my $t2 = VCS::Git::Torrent->new(
	repo_hash => '501d' x 10,
	git => $git2,
);

my $peer_2 = VCS::Git::Torrent::Peer::Async->new(
	port => $port_2,
	torrent => $t,
	#torrent => $t2,  # this should also work...
	peer_id => 'BravoPeer2BravoPeer2',
);
ok($peer_2, 'Another peer created');

$peer_1->connect("localhost:$port_2");

# let the connect get processed
Coro::Event::loop(1);

my $victim = $peer_1->connections->[0]->remote;
$peer_1->send_message($victim, GTP_PWP_REFERENCES);

Coro::Event::sweep;
cede;

Coro::Event::loop(1);

for my $attr ( qw(tag_id tagged_object tagger tagdate comment refs) ) {
	is_deeply(
		$victim->references->[0]->$attr,
		$ref->$attr,
		'reconstructed Reference: ' . $attr . ' matches'
	       );
}

