
package VCS::Git::Torrent::Tracker;

=head1 NAME

VCS::Git::Torrent::Tracker - implement logic for a gittorrent tracker

=head1 SYNOPSIS

 my $tracker = VCS::Git::Torrent::Tracker->new
                 ( torrents => [ $torrent, ... ],
                 );

 my $form = { repo_hash  => "xxxx",
              peer_id    => "xxxx",
              port       => 12345,
              uploaded   => 0,
              downloaded => 0,
              completed  => 0,
              address    => "git.example.com",
              port       => 9419,
              peers      => 10,
              references => 10,
              event      => "started",
            };

 my $rs = $tracker->track($form);

 # always "application/x-gittorrent"
 $r->content_type($rs->content_type);
 $r->content_length($rs->content_length);

 # or whatever
 $r->header_out;

 # done...
 print $r->response;

=head1 DESCRIPTION

The tracker keeps a list of peers and their download/upload status.

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
