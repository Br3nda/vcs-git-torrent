#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

# This test script tests the abstract (ie, shared between local and
# remote peers) portion of the "VCS::Git::Torrent::Peer" object, and
# the role for local peers.

BEGIN { use_ok("VCS::Git::Torrent::Peer") }

my $peer;

eval { $peer = VCS::Git::Torrent::Peer->new };
isnt($@, "", "attributes are required");

my @RH = (repo_hash => "1234" x 10);
my @where = ( address => "1.2.3.4", "port" => "1234", @RH );

$peer = VCS::Git::Torrent::Peer->new
	( @where,
          peer_id => "SomeStringExactly20B"
         );
ok($peer, "Created a new Peer");

my $peer_id = "SomeS\x{308}tringExactly20";
is(length($peer_id), 20, "String is the right length");
eval { $peer = VCS::Git::Torrent::Peer->new
	       ( @where,
		 peer_id => $peer_id,
	       ); };
isnt($@, "", "Heavy metal umlauts are not a single character");

chop($peer_id);
$peer = VCS::Git::Torrent::Peer->new
	( @where,
	  peer_id => $peer_id,
	);
ok($peer, "They're two ;)");

eval { $peer = VCS::Git::Torrent::Peer->new
	       ( @RH,
		 address => "1.2.3.4",
		 port    => "65536",
		 peer_id => $peer_id ) };
like($@, qr{\(port\) does not pass the type constraint},
     "Can't set an invalid port");

{
	package MyImpl;
	use Moose;
	extends "VCS::Git::Torrent::Peer";
	with "VCS::Git::Torrent::Peer::Local";
	has '+torrent' => required => 0;
}

my $node = MyImpl->new(@where, peer_id => $peer_id);
ok($node, "made a new node");
ok(!$node->isa("VCS::Git::Torrent::Peer::Local"),
   "It's not a Local node");
ok($node->does("VCS::Git::Torrent::Peer::Local"),
   "But it has all the traits of one");

# Copyright (C) 2007  Sam Vilain
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program, as the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.
