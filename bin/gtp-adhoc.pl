#!/usr/bin/perl

use strict;
use warnings;

use Coro;
use Coro::Event;
use Coro::Socket;
use Getopt::Long qw(:config pass_through);
use Git;
use MooseX::TimestampTZ qw(timestamptz);
use VCS::Git::Torrent;
use VCS::Git::Torrent::CommitReel::Local;
use VCS::Git::Torrent::Reference;
use VCS::Git::Torrent::Peer::Async;

my ($p_host, $p_port);

GetOptions(
	'host|h=s' => \$p_host,
	'port|p=i' => \$p_port,
);

if ( defined $p_host || defined $p_port ) {
	die 'must specify both or neither of host and port'
		unless ( defined $p_host && defined $p_port );
	die 'invalid port' if ( $p_port <= 0 || $p_port >= 65536 );
}

my @refs = scalar(@ARGV) ? @ARGV : ( '--all' );

my $git = Git->repository('.') || die 'failed to find git repo (git init?)';

eval {
	@refs = $git->command(
		['rev-list', '--no-walk', '--date-order', @refs],
		{ STDERR => 0 }
	);
};

@refs = () if ( $@ );

my $torrent = VCS::Git::Torrent->new(
	git => $git,
);

print 'repo_hash: ' . $torrent->repo_hash . "\n";

my $reels = [];
my $references = [];

if ( scalar(@refs) ) {
	# FIXME we need to calculate %refs in a more correct fashion...
	my %refs = map {
		my ($oid, $name) = split(' ');
		( $name => $oid )
	} $git->command('show-ref');

	my $ref = VCS::Git::Torrent::Reference->new(
		torrent => $torrent,
		tagged_object => $refs[0],
		tagger => 'Nobody <dev@null.nil>',
		tagdate => timestamptz(),
		comment => 'Created by ' . $0,
		refs => \%refs,
	);

	push @{ $references }, $ref;

	my $reel = VCS::Git::Torrent::CommitReel::Local->new(
		torrent => $torrent,
		end => $ref,
	);

	push @{ $reels }, $reel;
}

$torrent->reels($reels);
$torrent->references($references);

my $peer = VCS::Git::Torrent::Peer::Async->new(
	torrent => $torrent,
	reels => $reels,
);

if ( $p_host && $p_port ) {
	$peer->connect($p_host, $p_port) || die 'failed to connect to peer';

	Coro::Event::loop(1);
} else {
	Coro::Event::sweep;
	cede;
}

print 'listening on port: ' . $peer->port . "\n";
print '# conns: ' . @{ $peer->connections } . "\n";

Coro::Event::loop(1800);

