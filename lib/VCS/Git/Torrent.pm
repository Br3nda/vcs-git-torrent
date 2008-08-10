
package VCS::Git::Torrent;

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
       references => [ VCS::Git::Torrent::References->new( ... ) ],
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

  - p2p protocol decoding library

Sketched out, 'Choke' implemented

  - p2p handshake and peer discovery

Handshake yes, peer disovery no.

  - tracker protocol
  - git repository access library - cat-file and object traversal
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

=head1 LICENSE

  VCS::Git::Torrent - distributed version control swarm.
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

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::TimestampTZ;

use 5.008001;
use utf8;

BEGIN {
subtype 'VCS::Git::Torrent::peer_id'
	=> as Str
	=> where {
		if (utf8::is_utf8($_)) {
			my $x = $_;
			utf8::encode($x);
			length($x) == 20
		}
		else {
			length($_) == 20;
		}
	};

subtype "VCS::Git::Torrent::sha1_hex"
	=> as "Str"
	=> where { length($_) == 40 and !m{[^0-9a-f]}i };

subtype "VCS::Git::Torrent::git_object_id"
	=> as "VCS::Git::Torrent::sha1_hex";

subtype "VCS::Git::Torrent::repo_hash"
	=> as "VCS::Git::Torrent::sha1_hex";

# a sure candidate for inclusion in MooseX::Socket :)
subtype 'VCS::Git::Torrent::port'
	=> as Int
	=> where {
		($_&65535) && !($_>>16);
	};
}

has 'comment' =>
	isa => "Str",
	is  => "rw";

has 'created_by' =>
	isa => "Str",
	is  => "rw";

has 'creation_date' =>
	isa => "time_t",
	is  => "ro";

use VCS::Git::Torrent::Repo;

has 'repo' =>
	isa => "VCS::Git::Torrent::Repo",
	#required => 1,
	is  => "ro";

use Digest::SHA1 qw(sha1_hex);
use Bencode qw(bencode);

has 'repo_hash' =>
	is => "ro",
	isa => "VCS::Git::Torrent::sha1_hex",
	required => 1,
	lazy => 1,
	default => sub {
		my $self = shift;
		my $repo_hash = $self->repo->marshall;
		sha1_hex(bencode($repo_hash));
	};

use VCS::Git::Torrent::Reference;

has 'references' =>
	isa => "ArrayRef[VCS::Git::Torrent::Reference]",
	#required => 1,
	is  => "rw",
	trigger => sub {
		my $self = shift;
		my $value = shift;
		for my $x ( @$value ) {
			$x->torrent($self);
		}
	};

has 'reels' =>
	isa => "ArrayRef[VCS::Git::Torrent::CommitReel]",
	is => "rw",
	trigger => sub {
		my $self = shift;
		my $value = shift;
		for my $x ( @$value ) {
			$x->torrent($self);
		}
	};

has 'trackers' =>
	isa => "ArrayRef[URI]",
	#required => 1,
	is  => "rw";

=head2 marshall() returns HashRef

Return a reference to a data structure suitable for bencoding, or for
hashing with SHA1 to produce a repo_hash.

=cut

sub marshall {
	my $self = shift;

	my %marshalled;
	for my $key ( qw(comment created_by creation_date
			 repo references trackers) ) {
		if ( my $val = $self->$key ) {
			$key =~ s{_}{ };
			if ( blessed $val and
			     $val->can("marshall") ) {
				$val = $val->marshall;
			}
			$marshalled{$key} = $val;
		}
	}
	\%marshalled;
}

use IO::Plumbing ();
use Git;
has 'git' =>
	isa => 'Git',
	is  => 'ro',
	required => 1;

sub _git_plumb_args {
	my $self = shift;
	@{ $self->{_git_args} ||= do {
		#my %env = %ENV;
		#$env{GIT_DIR} = $self->git->repo_path;
		my $path = $self->git->wc_path;
		if (my $subdir = $self->git->wc_subdir) {
			$path .= "/" . $subdir;
		}
		[ cwd => $path,
		  env => { GIT_DIR => $self->git->repo_path },
		 ];
	} };
}

sub plumb {
	my $self = shift;
	my $args = shift;
	IO::Plumbing->new
		  ( program => "git", $self->_git_plumb_args,
		    args => $args,
		    @_
		   );
}

=head1 EXPORTS

Currently nothing is exported by default by this module.

=head2 start_peer_async(HASHREF) returns VCS::Git::Torrent::Peer::Async

Starts a new VCS::Git::Torrent::Peer::Async in an asynchronous thread
using Coro.

=cut

use Sub::Exporter -setup =>
	{ exports => [ qw(start_peer_async) ],
	};

sub start_peer_async {
	my %arguments = shift;

	require VCS::Git::Torrent::Peer::Async;
	my $peer = VCS::Git::Torrent::Peer::Async->new(%arguments);
	return $peer;
}

1;
