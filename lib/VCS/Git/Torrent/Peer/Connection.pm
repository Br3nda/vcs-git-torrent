
package VCS::Git::Torrent::Peer::Connection;

# a class for a known connection between two peers.  We only know
# about connections between a local node and a remote node; so the
# properties of this association class are so.

use VCS::Git::Torrent;
use Moose::Role;
use strict;
use warnings;

has 'local'  =>
	#isa => "VCS::Git::Torrent::Peer",
	does => "VCS::Git::Torrent::Peer::Local",
	required => 1,
	is => "rw";

has 'remote' =>
	isa => "VCS::Git::Torrent::Peer",
	required => 1,
	is => "rw";

has 'choked_in' =>
	isa => "Bool",
	is => "rw";

has 'choked_out' =>
	isa => "Bool",
	is => "rw";

use Carp;

=head1 NAME

VCS::Git::Torrent::Peer::Connection - A connection between two GTP Peers

=head1 SYNOPSIS

  # can't directly instantiate, need to get from the peer
  my $connection = $peer->connections->[0];

  my $local_peer  = $connection->local;
  my $remote_peer = $connection->remote;

  $connection->send($pwp_message);
  $connection->incoming;
  my $pwp_response = $connection->incoming;

=head1 DESCRIPTION

This role describes the requirements of a connection class between two
Peers.  As described in L<VCS::Git::Torrent::Peer>, this only ever
exists between a local peer and a remote peer.

This is a role, and not a concrete class, because how it behaves
depends on the concurrency implementation.

=cut

1;
