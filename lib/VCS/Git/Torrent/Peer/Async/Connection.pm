
package VCS::Git::Torrent::Peer::Async::Connection;

=head1 NAME

VCS::Git::Torrent::Peer::Async::Connection - Coro-based connection to a remote node

=head1 SYNOPSIS

 # incoming.
 my $conn = VCS::Git::Torrent::Peer::Async::Connection->new
         ( local => $local_peer,
           socket => $socket,
         );

 # outgoing.
 $conn = VCS::Git::Torrent::Peer::Async::Connection->new
         ( local => $local_peer,
           remote => $remote_peer,
         );
 $conn = VCS::Git::Torrent::Peer::Async::Connection->new
         ( local => $local_peer,
           remote_name => $address,
           remote_port => $port,
         );

=head1 DESCRIPTION

This class is used internally by L<VCS::Git::Torrent::Peer::Async>; it
is a class that implements the L<VCS::Git::Torrent::Peer::Connection>
role using Coro.

There is a co-routine which continually waits for messages and
processes them.  It processes the message, which usually would involve
some kind of response, possibly though not always starting a new Coro
to do so.  This usually does not involve much real blocking, due to OS
buffering of sockets etc.

=cut

use Moose;

with 'VCS::Git::Torrent::Peer::Connection';
with 'VCS::Git::Torrent::Peer::Async::Socket';

use strict;
use warnings;
use Carp;

use VCS::Git::Torrent::PWP qw(:pwp_constants pack_hex unpack_hex);
use constant RANDOM_BEHAVIOUR_BITS => "\0" x 8;

=head2 socket_args

Return a hash consisting of the remote addres, port, and protocol used.

=cut

sub socket_args {
	my $self = shift;
	( PeerHost => $self->remote->address,
	  PeerPort => $self->remote->port,
	  Proto    => "tcp",
	);
}

sub _start {
	my $self = shift;

	my $incoming = $self->remote->from_addr;
	$self->trace(sub{
		("processing ".
		 ($incoming?"call from $incoming"
		  :"call to ".$self->remote->address)) });
	( ( $self->remote->from_addr
	    ? $self->handshake && $self->send_handshake
	    : $self->send_handshake && $self->handshake )
	  && do { $self->recv_lock->unlock; 1 }
	  && do { $self->send_lock->unlock; 1 }
	  && $self->loop );

	$self->local->connections_remove($self);
}

has 'error_when' =>
	isa => "Str",
	is => "rw";

has 'error_desc' =>
	isa => "Str",
	is => "rw";

=head2 fail($when, $description)

Debug fail sub.

=cut

sub fail {
	my $self = shift;
	my $when = shift;
	my $description = shift;
	$self->trace(sub {"failed: $description during $when"});
	$self->error_when($when);
	$self->error_desc($description);
	$self->cancel;
	return();
}

=head2 loop

Main async/Coro message-processing loop.

=cut

sub loop {
	my $self = shift;
	my $socket = $self->socket;

	$self->local->send_message($self->remote, GTP_PWP_REELS);
	$self->local->send_message($self->remote, GTP_PWP_REFERENCES);

	$self->trace(sub {"main loop"});
	while ( my $message = do {
		$self->recv_lock->wrlock;
		$self->trace(sub {"listening"});
		$_ = VCS::Git::Torrent::PWP::Message->create_io($socket);
		$self->recv_lock->unlock;
		$_ }
	      ) {

		$self->trace(sub {"got a message: $_ (self = $self)"});
		$self->local->process($self, $message);

	}

	$self->shutdown;
}

=head2 send_handshake

Send a handshake to whatever we're connected to.

=cut

sub send_handshake {
	my $self = shift;
	confess "called from wrong coro" unless Coro::current() == $self->coro;
	my $socket = $self->socket;

	$self->trace(sub {"got a socket - $socket"});

	my $handshake = join "",
		(chr(length(GTP_PWP_PROTO_NAME)),
		 GTP_PWP_PROTO_NAME,
		 RANDOM_BEHAVIOUR_BITS,
		 pack_hex($self->local->repo_hash),
		 $self->local->peer_id);

	$self->trace(sub {"sending handshake: $handshake"});
	my $wrote = $socket->send($handshake);
	$wrote == length($handshake)
		or return $self->fail("handshake", "wrote only $wrote bytes");
}

=head2 handshake

Wait for a handshake from whatever we're connected to.

=cut

sub handshake {
	my $self = shift;
	confess "called from wrong coro" unless Coro::current() == $self->coro;
	my $socket = $self->socket;

	$self->trace(sub {"awaiting handshake"});
	my $buf;

	$socket->read($buf, 1)
		or return $self->fail("handshake", "Nothing received");

	my $proto_len = ord($buf);
	if ( $proto_len != 7 ) {
		return $self->fail("handshake", "Protocol mismatch");
	}
	$socket->read($buf, 7) == 7
		or return $self->fail("handshake", "Short read");

	if ( $buf ne GTP_PWP_PROTO_NAME ) {
		return $self->fail("handshake", "Protocol mismatch");
	}

	$socket->read($buf, 8) == 8
		or return $self->fail("handshake", "Short read");
	if ( $buf ne RANDOM_BEHAVIOUR_BITS ) {
		return $self->fail
			("handshake",
			 "This implementation is deterministic");
	}

	$socket->read($buf, 20) == 20
		or return $self->fail("handshake", "Short read");
	if ( unpack_hex($buf) ne $self->local->repo_hash ) {
		return $self->fail("handshake", "Repository mismatch");
	}

	$socket->read($buf, 20) == 20
		or return $self->fail("handshake", "Short read");

	if ( $self->local->connected_to($buf) ) {
		return $self->fail("handshake", "duplicate peer id");
	}
	$self->trace(sub {"now connected to $buf"});
	$self->remote->peer_id($buf);
}

=head2 send_message

Pack a message and send it off.

=cut

sub send_message {
	my $self = shift;
	my $message = shift;
	$self->send_lock->wrlock;
	$message = $message->pack;
	my $written = $self->socket->write($message);
	($written == length($message))
		or return $self->fail
			("send_message",
			 "Short write - only $written of "
			 .length($message)." bytes written");
	$self->send_lock->unlock;
}

=head2 shutdown

Your socket has performed an illegal operation and must be shut down.

=cut

sub shutdown {
	my $self = shift;
	if ( $self->{socket} ) {
		$self->socket->shutdown;
	}
}

1;
