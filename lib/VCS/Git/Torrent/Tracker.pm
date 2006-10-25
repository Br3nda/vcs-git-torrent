
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

=cut

