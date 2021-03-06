#!/usr/bin/perl

use Test::Depends qw(Coro);
use Test::More no_plan;
use strict;
use warnings;
use t::TestUtils;

BEGIN { use_ok("VCS::Git::Torrent::Peer::Async") }

# In this test script, we will set up two peers and check that they
# can successfully handshake, and disconnect gracefully.

my ($port_1, $port_2) = @{ random_port_pair() };

my $dummy_torrent = VCS::Git::Torrent->new(repo_hash => "6549" x 10,
					   git => tmp_git,
					  );

$SIG{PIPE} = sub {
	print STDERR "OW SIGPIPE\n";
};

my $peer_1 = VCS::Git::Torrent::Peer::Async->new
	( port => $port_1,
	  torrent => $dummy_torrent,
	  peer_id => "AlphaPeer1AlphaPeer1",
	);
ok($peer_1, "Made a new peer");

my $peer_2 = VCS::Git::Torrent::Peer::Async->new
	( port => $port_2,
	  torrent => $dummy_torrent,
	  peer_id => "BravoPeer2BravoPeer2",
	);
ok($peer_2, "Made another new peer");

$peer_2->connect("localhost:$port_1");

is(Coro::nready, 3, "All set up and ready to go");

use Coro::Event;
#use Coro;
Coro::Event::loop(1);
#diag("finished");

SKIP:{
	ok($peer_1->num_connections, "Peer 1 found a peer")
		or skip "no connection made", 9;

	ok(!$peer_2->connections->[0]->choked_in,
	   "Peer 2 is not yet feeling the choke");

	use VCS::Git::Torrent::PWP qw(:pwp_constants);
	my $victim = $peer_1->connections->[0]->remote;
	ok($victim, "Peer 1 knows someone")
		or skip "doesn't know anyone!", 7;

	isnt($victim, $peer_2, "Peer 2 and victim look different");
	# this won't match.  The outgoing ports are different.
	#is($victim->port, $peer_2->port, "But they share a port");
	is($victim->peer_id, $peer_2->peer_id, "And a Peer ID!");

	# get 'im!
	$peer_1->send_message($victim, GTP_PWP_CHOKE);
	pass("Sent a message to the victim");

	my $conn = $peer_2->connections->[0];

	Coro::Event::sweep;
	cede;

	ok($conn->choked_in,
	   "Peer 2 felt the choke");

	# lets revive them.
	$peer_1->send_message($victim, GTP_PWP_UNCHOKE);

	Coro::Event::sweep;
	cede;

	# did they make it?
	ok(!$conn->choked_in, "Peer 2 is breathing again!");

	# peer 2 retaliates
	$peer_2->send_message($conn->remote, GTP_PWP_CHOKE);

	# but it's too late!
	$peer_1->hangup ($victim);
	is($peer_1->num_connections, 0, "Hung up on the victim");
	$peer_1->shutdown;

	Coro::Event::loop(1);

	is ( $peer_2->num_connections, 0,
	     "Peer 2 detected the hangup");

	$peer_2->shutdown;
}

is(Coro::nready, 0, "Nothing left running!");
