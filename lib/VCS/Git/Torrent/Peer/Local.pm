
package VCS::Git::Torrent::Peer::Local;

=head1 NAME

VCS::Git::Torrent::Peer::Local - role for local GTP/0.1 peers

=head1 SYNOPSIS

 # adjust the maximum number of peers
 $peer->max_peers(10);

 # adjust the configured transfer rates
 $peer->max_up_rate(32 * 1024);
 $peer->max_down_rate(200 * 1024);

=head1 DESCRIPTION

You would not normally instantiate objects in this class directly;
normally this would happen through a sub-class that selects the
multi-processing implementation to use.

This interface serves as a point for placing operations, functions and
attributes that can only ever be performed on local Peers.

=cut

use Moose::Role;

use Carp;

has '+peer_id' =>
	default => sub {
		pack("S*", map { int(rand(65535)) } (1..10));
	};

has 'peername' =>
	isa => "Str",
	is  => "ro";

has 'peerport' =>
	isa => "VCS::Git::Torrent::port",
	is  => "ro";

has 'peerpeer_id' =>
	isa => "VCS::Git::Torrent::peer_id",
	is => "rw";

has '+port' => required => 0;
has '+address' => required => 0;

=head2 has_address

Do we have an address?

=cut

sub has_address {
	my $self = shift;
	defined $self->address
}

=head2 has_port

Do we have a port?

=cut

sub has_port {
	my $self = shift;
	defined $self->port
}

has 'torrent' =>
	isa => "VCS::Git::Torrent",
	is => "ro",
	required => 1;

has '+repo_hash' =>
	lazy => 1,
	default => sub {
		my $self = shift;
		croak "no torrent passed to new local Peer\n"
			unless $self->torrent;
		$self->torrent->repo_hash;
	};

=head1 ATTRIBUTES

=head2 max_peers

Specify the maximum number of active connections to hold.

=cut

has 'max_peers' =>
	isa => "Int",
	is  => "rw";

=head2 max_up_rate

=head2 max_down_rate

Specify overall up/down rate limiting for this peer.

=cut

has 'max_up_rate' =>
	isa => "Int",
	is  => "rw";

has 'max_down_rate' =>
	isa => "Int",
	is  => "rw";

=head1 SEE ALSO

L<VCS::Git::Torrent>, L<VCS::Git::Torrent::Peer>

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

1;
