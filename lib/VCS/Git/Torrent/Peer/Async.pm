
package VCS::Git::Torrent::Peer::Async;

=head1 NAME

VCS::Git::Torrent::Peer::Async - local GTP/0.1 PWP node using Coro

=head1 SYNOPSIS

 use VCS::Git::Torrent::Peer::Async;

 # adjust the maximum number of peers
 my $peer = VCS::Git::Torrent::Peer::Async->new
         ( port => 1234,
           torrent => $torrent,
         );

 $peer->connect("peer:PORT");   # spawns a new Coro

 sleep 1 while $peer->peers < 0;

 use VCS::Git::Torrent::PWP qw(:pwp_constants);
 my $victim = $peer->peers->[0];
 $peer->message($victim, GTP_PWP_CHOKE);
 $peer->hangup($victim);
 $peer->shutdown;

=head1 DESCRIPTION

This module starts a new GitTorrent peer, using L<Coro>.  The
semantics of this module are that the function keeps going until it is
finished, relying on L<Coro::Socket> and friends to magically put it
to sleep when it is finished.

Some people would call using coroutines for writing a network
application "Cheating".  Others would say that this couldn't possibly
be the right way to implement it, because their favourite language
does not have the feature.  However, it is true that it does save a
lot of implementation effort at the expense of a language feature
which is relatively poorly understood and even in Perl (ESPECIALLY in
Perl bray the crowd) is often implemented as an afterthought.

=cut

use Moose;

extends 'VCS::Git::Torrent::Peer';
with 'VCS::Git::Torrent::Peer::Local';
with 'VCS::Git::Torrent::Peer::Async::Socket';

use VCS::Git::Torrent::Peer::Async::Connection;

#has 'torrent' =>
	#isa => "VCS::Git::Torrent",
	#is  => "ro",
	#required => 1,
	#handles => [qw(repo_hash)];

use strict;
use warnings;
use Carp;

# these are for the use of subclasses.
sub _new_conn {
	my $self = shift;
	new VCS::Git::Torrent::Peer::Async::Connection
		( local  => $self,
		  @_,
		);
}
sub _new_peer {
	my $self = shift;
	new VCS::Git::Torrent::Peer
		( repo_hash => $self->repo_hash,
		  @_,
		);
}

sub _start {
	my $self = shift;
	my $socket = $self->socket or return;
	$self->trace(sub{"got a socket!  $socket"});
	while ( my $child = $socket->accept ) {
		$self->trace(sub{"got a connection!  $child"});
		my $remote = $self->_new_peer
			( from_addr => $child->peerhost,
			  from_port => $child->peerport
			);
		$self->connections_insert
			( $self->_new_conn( socket => $child,
					    remote => $remote,
					  ) );
	}
}

sub socket_args {
	my $self = shift;
	( ( $self->has_address
	    ? (LocalAddr => $self->address)
	    : () ),
	  LocalPort => $self->port,
	  Proto     => "tcp",
	  Listen    => 5,
	  ( $self->timeout
	    ? (Timeout   => $self->timeout)
	    : () ),
	);
}

use Socket;

# this don't work; would need to sub-type the subtype
# does::VCS::Git::Torrent::Peer::Connection
#
# has '+connections' =>
#        isa => 'ArrayRef[VCS::Git::Torrent::Peer::Connection::Async]',
#        is => "ro",
#        default => sub { [] };

sub connect {
	my $self = shift;

	my @args = (local => $self);
	my $peer = shift;
	if ( !blessed $peer ) {
		my $address = $peer;
		my $port = shift;
		if ( $address =~ m{^([^:]*):(\d+)$} ) {
			($address,$port) = ($1,$2);
		}
		$peer = $self->_new_peer
			( address => $address,
			  port    => $port );
	}
	push @args, remote => $peer;

	$self->connections_insert( $self->_new_conn(@args) );

}

sub process {
	my $self = shift;
	my $connection = shift;
	my $message = shift;
	$message->action($self, $connection);
}

sub shutdown {
	my $self = shift;
	$self->socket->shutdown;
	for my $child ( @{ $self->connections } ) {
		$child->shutdown;
	}
	@{$self->connections} = ();
}

sub connection {
	my $self = shift;
	my $peer = shift;
	my ($connection) = grep { $_->remote == $peer }
		@{ $self->connections };
	$connection;
}

sub connections_insert {
	my $self = shift;
	my $connection = shift;
	if ( grep { $_ == $connection } @{ $self->connections } ) {
		return 0
	}
	else {
		push @{$self->connections}, $connection;
		return 1;
	}
}

sub connections_remove {
	my $self = shift;
	my $connection = shift;
	@{$self->connections}
		= grep { $_ != $connection }
			@{$self->connections};
}

sub connected_to {
	my $self = shift;
	my $peer = shift;
	if ( blessed $peer ) {
		$peer = $peer->peer_id;
	}
	my ($who) = grep { ($_->remote->peer_id||"") eq $peer }
		@{$self->connections};
	$who;
}

sub hangup {
	my $self = shift;
	my $victim = shift;
	my $connection = $self->connection($victim);
	$connection->shutdown;
	$self->connections_remove($connection);
}

sub send_message {
	my $self = shift;
	my $to = shift;
	my $message = VCS::Git::Torrent::PWP::Message->create(@_);
	my $connection = $self->connected_to($to)
		or return undef;
	$connection->send_message($message);
}

=head1 SEE ALSO

L<VCS::Git::Torrent>, L<VCS::Git::Torrent::Peer>, L<VCS::Git::Torrent::Local>

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

no Moose::Util::TypeConstraints;
no Moose;

1;
