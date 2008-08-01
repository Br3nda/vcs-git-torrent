
package VCS::Git::Torrent::PWP;

=head1 NAME

VCS::Git::Torrent::PWP - Interface to the GitTorrent Peer Wire Protocol

=head1 SYNOPSIS

 use VCS::Git::Torrent::PWP
       qw( pwp_message pwp_decode :pwp_constants );

 my $message = pwp_message(GTP_PWP_CHOKE);
 $message    = pwp_message(GTP_PWP_UNCHOKE);
 $message    = pwp_message(GTP_PWP_INTERESTED);
 $message    = pwp_message(GTP_PWP_UNINTERESTED);

 # request
 $message    = pwp_message(GTP_PWP_PEERS);

 # response - %peers is (peer_ID => address)
 $message    = pwp_message(GTP_PWP_PEERS, %peers);

 # request
 $message    = pwp_message(GTP_PWP_REFERENCES);

 # announce
 $message    = pwp_message(GTP_PWP_REFERENCES, $ref_sha1);

 # send references (VCS::Git::Torrent::References objects)
 $message    = pwp_message(GTP_PWP_REFERENCES, @references_objects);

 # request reels
 $message    = pwp_message(GTP_PWP_REELS);

 # response (VCS::Git::Torrent::CommitReel objects)
 $message    = pwp_message(GTP_PWP_REELS, @reels);

 # request block bitmap
 $message    = pwp_message(GTP_PWP_BLOCKS, $reel, $offset, $length);

 # response - the information is pulled from the $reel object
 $message    = pwp_message(GTP_PWP_BLOCKS, $reel, $offset, $length, 1);

 # request
 $message    = pwp_message(GTP_PWP_SCAN, $reel, $offset, $length);

 # response - again pulls from the $reel object
 $message    = pwp_message(GTP_PWP_SCAN, $reel, $offset, $length, 1);

 # request objects, passing known heads
 $message    = pwp_message(GTP_PWP_REQUEST, \@objects, \@heads );

 # request playback of a section of reel
 $message    = pwp_message(GTP_PWP_PLAY, $reel, $offset, $length );

 # response
 $message    = pwp_message(GTP_PWP_PLAY, $reel, $offset, $length, 1 );

 # generic pack generation
 $message    = pwp_message(GTP_PWP_PLAY, \@tokens, \@heads, 0, \@objects );

 # stop a block download
 $message    = pwp_message(GTP_PWP_STOP, $reel, $offset, $length );

 # stop a 'request' download
 $message    = pwp_message(STOP, [$start_sha1, $end_sha1],
                           $offset, $length );

 # send a message down a socket.
 $socket->send(scalar $message->pack);

 # decoding wire messages
 $message    = pwp_decode($handle);

=head1 DESCRIPTION

This module provides an interface for encoding and decoding GTP/0.1
PWP messages.

=cut

use VCS::Git::Torrent::PWP::Message qw(:constants);

use strict 'vars', 'subs';

use constant GTP_PWP_PROTO_NAME => "GTP/0.1";

use Sub::Exporter -setup =>
	{ exports =>
	  [ qw(pwp_message pwp_decode unpack_hex pack_hex pack_num unpack_num),
	    grep { m{^GTP_PWP_} } keys %{__PACKAGE__."::"},
	  ],
	  groups =>
	  [ pwp_constants =>
	    [ grep { m{^GTP_PWP_} } keys %{__PACKAGE__."::"} ]
	  ],
	};

use Carp;

=head2 pack_hex

=head2 unpack_hex

Wrappers to pack and unpack hex to and from bits

=cut

sub pack_hex {
	croak "Can't hexpack '$_[0]'" if $_[0] =~ m{[^a-fA-F0-9]}
		or length($_[0]) & 1;
	my $rv = pack("C*", map { hex($_) } $_[0] =~ m{(..)}g);
}

sub unpack_hex {
	join("", map { sprintf("%.2x", $_) } unpack("C*", $_[0]));
}

=head2 pack_num

=head2 unpack_num

Wrappers to pack and unpack numbers to and from network-order, 32-bit
integers.

=cut

sub pack_num {
	my $num = shift;
	croak "can't pack $num" unless int($num) == $num and $num >= 0 and $num < 2**32;
	pack("N", $num);
}

sub unpack_num {
	my $num_quad = shift;
	croak "bad input to unpack_num" unless length($num_quad) == 4;
	(unpack("N", $num_quad))[0];
}

=head2 pwp_message

=head2 pwp_decode

Create and decode PWP messages

=cut

sub pwp_message {
	VCS::Git::Torrent::PWP::Message->create ( @_ )
}

sub pwp_decode {
	VCS::Git::Torrent::PWP::Message->create_io ( @_ )
}

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
