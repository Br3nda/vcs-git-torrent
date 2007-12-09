
=head1 NAME

VCS::Git::Torrent::PWP - Interface to the GitTorrent Peer Wire Protocol

=head1 SYNOPSIS

 use VCS::Git::Torrent::PWP qw( pwp_message pwp_decode );

 my $message = pwp_message(CHOKE);
 $message    = pwp_message(UNCHOKE);
 $message    = pwp_message(INTERESTED);
 $message    = pwp_message(UNINTERESTED);

 # request
 $message    = pwp_message(PEERS);

 # response - %peers is (peer_ID => address)
 $message    = pwp_message(PEERS, %peers);

 # request
 $message    = pwp_message(REFERENCES);

 # announce
 $message    = pwp_message(REFERENCES, $ref_sha1);

 # send references (VCS::Git::Torrent::References objects)
 $message    = pwp_message(REFERENCES, @references_objects);

 # request reels
 $message    = pwp_message(REELS);

 # response (VCS::Git::Torrent::CommitReel objects)
 $message    = pwp_message(REELS, @reels);

 # request block bitmap
 $message    = pwp_message(BLOCKS, $reel, $offset, $length);

 # response - the information is pulled from the $reel object
 $message    = pwp_message(BLOCKS, $reel, $offset, $length, 1);

 # request
 $message    = pwp_message(SCAN, $reel, $offset, $length);

 # response - again pulls from the $reel object
 $message    = pwp_message(SCAN, $reel, $offset, $length, 1);

 # request objects, passing known heads
 $message    = pwp_message(REQUEST, \@objects, \@heads );

 # request playback of a section of reel
 $message    = pwp_message(PLAY, $reel, $offset, $length );

 # response
 $message    = pwp_message(PLAY, $reel, $offset, $length, 1 );

 # generic pack generation
 $message    = pwp_message(PLAY, \@tokens, \@heads, 0, \@objects );

 # stop a block download
 $message    = pwp_message(STOP, $reel, $offset, $length );

 # stop a 'request' download
 $message    = pwp_message(STOP, [$start_sha1, $end_sha1],
                           $offset, $length );

 # send a message down a socket.
 $message->send($socket);

 # decoding wire messages
 $message    = pwp_decode($socket);

=head1 DESCRIPTION

This module provides an interface for encoding and decoding GTP/0.1
PWP messages.

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
