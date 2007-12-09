
=head1 NAME

VCS::Git::Torrent::PWP::Message - role for PWP messages

=head1 SYNOPSIS

 package VCS::Git::Torrent::PWP::Message::Foo;

 extends 'VCS::Git::Torrent::PWP::Message';

 sub pack {
     ...
 }

 sub unpack {
     ...
 }

 1;

=head1 DESCRIPTION

This is a base class for PWP messages.

Messages must define their data members themselves, but critically,
return the body of the message as sent on the wire with "pack", and
accept a message with "unpack", setting up their relevant members.

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
