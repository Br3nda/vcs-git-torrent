#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

# This test script tests the VCS::Git::Torrent::References class

BEGIN { use_ok('t::TestUtils') }
BEGIN { use_ok('VCS::Git::Torrent') }
BEGIN { use_ok('VCS::Git::Torrent::Reference') }

my $path = mk_tmp_repo();
chdir($path);
my $repo = Git->repository();
my $tag_id = $repo->command('hash-object', '-w', '-t', 'tag', '../41-peer-references/01-simple.tag');
chomp $tag_id;

my $t = VCS::Git::Torrent->new(
	repo_hash => '1415' x 10,
	git => $repo,
);

my $ref = VCS::Git::Torrent::Reference->new(
	torrent => $t,
	tag_id => $tag_id,
);

my $tagged_object = '5e8f6a7807a378259daa3b91314c8c9775fa160e';
my $sam = 'Sam Vilain <sam@vilain.net>';
my $tagdate = '2008-07-13 15:45:13+1200';

is($ref->tag_id, $tag_id, 'tag_id matches');
is($ref->tagged_object, $tagged_object, 'tagged_object matches');
is($ref->tagger, $sam, 'tagger matches');
is($ref->tagdate, $tagdate, 'tagdate matches');
is($ref->comment, "Simple tag object\n\n", 'comment matches');

#foreach(keys(%{$ref->refs})) {
#	print $_ . "\t" . $ref->{refs}->{$_} . "\n";
#}

is($ref->refs->{'refs/heads/master'}, $tagged_object, 'refs matches');

# now the reverse
my $tag = VCS::Git::Torrent::Reference->new
	( torrent => $t,
	  tagged_object => $tagged_object,
	  tagger => $sam,
	  tagdate => $tagdate,
	  comment => "Created by $0\n\n",
	  refs => { 'refs/heads/master' => $tagged_object },
	);

ok($tag->tag_id, "can write tag");
$tag_id = $tag->tag_id;

my $type = $repo->command_oneline("cat-file", "-t", $tag_id);
is($type, "tag", "wrote a tag OK");
if ( -t STDOUT ) {
	my $data = $repo->command("cat-file", "tag", $tag_id);
	diag($data);
}
