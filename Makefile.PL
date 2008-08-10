use inc::Module::Install;

name            ("VCS-Git-Torrent");
abstract        ("An implementation of GTP/0.1");
author          ("Sam Vilain <samv@cpan.org>");
version_from    ("lib/VCS/Git/Torrent.pm");
license         ("GPL3");

requires        ("perl" => 5.008001);
requires        ("Moose" => 0.32);
requires        ("Sub::Exporter");
requires        ("MooseX::Timestamp" => 0.05);
requires	("IO::Plumbing" => 0.06);

&WriteAll;
