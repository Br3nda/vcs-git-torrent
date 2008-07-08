
package VCS::Git::Torrent::Peer;

=encoding utf8

=head1 NAME

VCS::Git::Torrent::Peer - a peer in a GTP/0.1 swarm

=head1 SYNOPSIS

 my $peer = VCS::Git::Torrent::Peer->new
         ( repo_hash   => $repo_hash,
           peer_id     => $peer_id,
           address     => "1.2.3.4",
           port        => "1234",
         );

 my $peer_in = VCS::Git::Torrent::Peer->new
         ( repo_hash => $repo_hash,
           from_addr => $socket->peeraddr,
           from_port => $socket->peerport,
         );

=head1 DESCRIPTION

A Peer in a GitTorrent swarm has a unique identifier, unique within an
individual swarm.  Depending on how we know about this peer, we will
know an incoming address, an outgoing address, or both.

The Peer may be local; that is, it
C<-E<gt>does("VCS::Git::Torrent::Peer::Local")>.  If that is the case,
then it will not have a C<from_addr> or C<from_port>.  It may also
have an associated thread or process that is serving incoming
connections, depending on which class implements it.

We may or may not have a connection to the peer.  Local nodes have a
C<connections> property that track this.  Each connection object will
implement the L<VCS::Git::Torrent::Peer::Connection> Role.  The
convenience method C<is_connected_to> will check to see if there is an
active connection between the node in question and the node asked for.

The other type of connection between nodes is the C<knows>
relationship; this is another set of nodes.  To avoid an O(N²) number
of these sets, they are only kept for nodes that we hold an active
connection to.

=cut

use Moose;
use VCS::Git::Torrent;

=head1 ATTRIBUTES

=head2 repo_hash

The identifier of the swarm this peer is a member of

=cut

has 'repo_hash' =>
	isa => "VCS::Git::Torrent::repo_hash",
	is => "ro",
	required => 1;

=head2 peer_id

This attribute is required, and must be a string exactly 20 I<bytes>
in length uniquely idenitifying the peer.

=cut

has 'peer_id' =>
	isa => "VCS::Git::Torrent::peer_id",
	is  => "rw";

=head2 address

This is an address that should be behave like an IP address or
hostname; for example, an IPv4 address or a DNS hostname.

=cut

has 'address' =>
	isa => "Str",
	is => "ro";

has 'from_addr' =>
	isa => "Str",
	is  => "ro";

=head2 port

TCP/IP is used by GTP/0.1.  This specifies the TCP port number to use
for connecting to this peer.

=cut

has 'port' =>
	isa => "VCS::Git::Torrent::port",
	is => "rw";

has 'from_port' =>
	isa => "VCS::Git::Torrent::port",
	is  => "ro";

=head2 knows

Peers we know this node knows - an Array managed as a set

=cut

has 'knows' =>
	isa => "ArrayRef[VCS::Git::Torrent::Peer]",
	is  => "rw",
	default => sub { [] };

=head2 has_connections

=head2 num_connections

Return whether or not the peer has other peers.

=cut

sub has_connections {
	my $self = shift;
	$#{$self->connections} > -1;
}

sub num_connections {
	my $self = shift;
	$#{$self->connections}+1;
}

use Moose::Util::TypeConstraints;

subtype 'does::VCS::Git::Torrent::Peer::Connection'
	=> as Object
	=> where { $_->does("VCS::Git::Torrent::Peer::Connection") };

has 'connections' =>
	isa => 'ArrayRef[does::VCS::Git::Torrent::Peer::Connection]',
	is  => "ro",
	default => sub { [] };

1;

=head1 SEE ALSO

L<VCS::Git::Torrent>, L<VCS::Git::Torrent::Peer::Local>

=head1 LICENSE

  Copyright (C) 2007  Sam Vilain

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program, as the file COPYING.  If not, see
  <http://www.gnu.org/licenses/>.

=cut
