
package VCS::Git::Torrent::Peer;

=head1 NAME

VCS::Git::Torrent::Peer - a peer in a GTP/0.1 swarm

=head1 SYNOPSIS

 my $peer = new VCS::Git::Torrent::Peer
         (address => "1.2.3.4",
          port    => "1234",
          peer_id => "SomeStringExactly20B"
         );

=head1 DESCRIPTION

A Peer in a GitTorrent swarm has an address, port and an identifier.
Normally, you will create objects of this class for remote peers, and
one that implements the L<VCS::Git::Torrent::Peer::Local> role for
peers which are connected to local repositories.

=cut

use Moose;
use VCS::Git::Torrent;

=head1 ATTRIBUTES

=head2 peer_id

This attribute is required, and must be a string exactly 20 I<bytes>
in length uniquely idenitifying the peer.

=cut

has 'peer_id' =>
	isa => "VCS::Git::Torrent::peer_id",
	required => 1,
	is  => "ro";

=head2 address

This is an address that should be behave like an IP address or
hostname; for example, an IPv4 address or a DNS hostname.

=cut

has 'address' =>
	isa => "Str",
	required => 1,
	is => "ro";

=head2 port

TCP/IP is used by GTP/0.1.  This specifies the TCP port number to use
for connecting to this peer.

=cut

has 'port' =>
	isa => "VCS::Git::Torrent::port",
	required => 1,
	is => "ro";

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
