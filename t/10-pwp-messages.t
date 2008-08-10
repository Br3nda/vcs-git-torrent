#!/usr/bin/perl -w

use strict;
use lib "t";
use MockStream;
use HexString;
use Test::Depends qw(VCS::Git::Torrent::PWP::Message);

use Test::More qw(no_plan);

BEGIN { use_ok('VCS::Git::Torrent::PWP::Message::Choke') }

use_ok("VCS::Git::Torrent::PWP" => "-pwp_constants");

ok(defined &GTP_PWP_CHOKE, "imported constants");
is(&GTP_PWP_CHOKE,   0, "imported GTP_PWP_CHOKE");
is(&GTP_PWP_UNCHOKE, 1, "imported GTP_PWP_UNCHOKE");
is(&GTP_PWP_PLAY,   10, "imported GTP_PWP_PLAY");

my $choke = VCS::Git::Torrent::PWP::Message::Choke->new;
ok($choke, "make a Choke object");

my $wire = $choke->pack;
is(hex_string($wire), "0000000400000000",
   "pack - choke encoded OK");

is(length($wire), 8, "pack - choke right size");

VCS::Git::Torrent::PWP->import("pwp_message", "pwp_decode");

$choke = &pwp_message(&GTP_PWP_CHOKE);
ok($choke, "Made a CHOKE message with pwp_message()");
isa_ok($choke, "VCS::Git::Torrent::PWP::Message::Choke",
       "CHOKE message");
eval { &pwp_message(&GTP_PWP_CHOKE, 1) };
like($@, qr/no arguments/, "CHOKE has no arguments");

my $stream = stream($wire."leftovers");
$choke = &pwp_decode($stream);
is(<$stream>, "leftovers", "ate correct number of bytes");
ok($choke, "Made a CHOKE message with pwp_decode()");
isa_ok($choke, "VCS::Git::Torrent::PWP::Message::Choke",
       "decoded CHOKE message");
