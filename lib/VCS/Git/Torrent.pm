
=head1 NAME

VCS::Git::Torrent - distributed version control swarm

=head1 SYNOPSIS

 use VCS::Git::Torrent qw(make_torrent);

 # to make a torrent
 my $torrent = make_torrent
     ( comment => $comment,
       repo =>
       { alternates => [ $other_torrent->repo_hash ],
         description => "My branches",
         pubkey      => "0xdeadbeef",
       },
       references => VCS::Git::Torrent::References->new
               ( ... ),
       trackers   => [ URI->new(...), ... ],
       # created_by, creation_date generated for you
     );

 print "repo hash is ".$torrent->repo_hash;

 # the repo hash is important; without it you may not join
 # the same swarm.  making it a part of the filename isn't a
 # bad idea.
 my $filename = "myproject-GTP$short_hash.gittorrent";

 # save it to disk
 use IO::All;
 my $short_hash = substr $torrent->repo_hash, 0, 7;
 $torrent->contents > io($filename);

 # load one from disk
 $torrent = VCS::Git::Torrent->new
         ( contents => scalar io($filename)->slurp );

 # connect to the repository.
 $torrent->repository(VCS::Git::Repository->new( ... ));

 # are all the refs present.  This checks all the ref targets are in
 # the repository.
 print "we're a seeder" if $torrent->completed;

 # for starting a Coro-based peer
 use VCS::Git::Torrent qw(start_peer_async);
 my $peer = start_peer_async
               ( address => "git.example.com",  # optional
                 # peer_id is generated for you
                 port => 9419,                  # also optional
                 # capped rates in bytes per second...
                 up_rate => 0,
                 down_rate => 0,
                 max_peers => 16,
                 torrents => [ $torrent ],
                 peers => [ "IP:PORT", ... ],   # optional
               );
 $peer->join;

=head1 DESCRIPTION

This module is a prototype implementation of the B<gittorrent>
protocol, described at L<http://gittorrent.utsl.gen.nz/rfc.html>.

The basic principle is that very large git repositories can take a
while to download, and that many people downloading from a central
repository can make things slower than cold Subversion.  It would be
nice, if there are nearby mirror servers or other people sharing their
connection, to get revisions from there instead.

=head1 IMPLEMENTATION STATUS

Based on an initial set of milestones for a summer of code student.

  - tracker protocol
  - p2p protocol decoding library
  - git repository access library - cat-file and object traversal
  - p2p handshake and peer discovery
  - p2p "references" message
  - git repository access enhancement - arbitrary packfile generation
  - p2p "request" message (and "play" response)
  - p2p "stop" request
  - p2p "reels" request and response
  - commit reel sorting algorithm
  - storing and accessing commit reel indexes
  - p2p "scan" request and response
  - p2p "play" and "blocks" messages
  - git repository access enhancement - "thin" packfiles according to
    commit reel sorting algorithm

=cut

