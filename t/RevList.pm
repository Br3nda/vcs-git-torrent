#!/usr/bin/perl

use strict;
use warnings;

use Git;

my $repo = Git->repository();

my @revs = $repo->command('rev-list', '--topo-order', '--all', '--reverse');

my $offset = 0;

foreach(@revs)
{
	my $o_hash = (split(/\s+/))[0];
	my $o_size = $repo->command('cat-file', '-s', $o_hash);
	my $o_type = $repo->command('cat-file', '-t', $o_hash);
	chomp($o_type);

	my @deps = $repo->command('rev-list', '--topo-order', '--objects', '--reverse', $o_hash . '^!');
	shift @deps;

	foreach my $d (@deps)
	{
		my $d_hash = (split(/\s+/, $d))[0];
		my $d_size = $repo->command('cat-file', '-s', $d_hash);
		my $d_type = $repo->command('cat-file', '-t', $d_hash);
		chomp($d_type);

		printf "%8i %8s %8i %s\n", $offset, $d_type, $d_size, $d_hash;
		$offset += $d_size;
	}

	printf "%8i %8s %8i %s\n", $offset, $o_type, $o_size, $o_hash;
	$offset += $o_size;
}
