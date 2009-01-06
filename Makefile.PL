use inc::Module::Install;

name            ("VCS-Git-Torrent");
abstract        ("An implementation of GTP/0.1");
author          ("Sam Vilain <samv@cpan.org>");
version_from    ("lib/VCS/Git/Torrent.pm");
license         ("GPL3");

build_requires  ("Test::Depends" => 0.06);
requires	("Coro" => 4.7);
requires	("Bencode");
requires        ("perl" => 5.008001);
requires        ("Moose" => 0.32);
requires        ("Sub::Exporter");
requires        ("MooseX::Timestamp" => 0.05);
requires	("IO::Plumbing" => 0.06);
requires	("Digest::SHA1");

eval "use Git";
my $git_ok = 1;
if ($@) {
	$git_ok = 0;
}
else {
	my $git_version = Git::command_oneline("version");
	$git_version =~ s{.*?(\d)}{$1};
	my @version_parts = map { 0+$_ } split /\./, $git_version;
	my $mul = 1;
	my $version;
	while (my $v = shift @version_parts) {
		$version += $v * $mul;
		$mul /= 100;
	}
	$git_ok = ( $version >= 1.0500 );
}

unless ($git_ok) {
	print STDERR <<ENOGIT;
**** This program needs git 1.5.0 or later installed.
****   You can get it from http://git.or.cz/
ENOGIT
}

&WriteAll;
