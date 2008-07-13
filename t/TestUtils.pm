#!/usr/bin/perl

package t::TestUtils;

use base qw(Exporter);
BEGIN {
	our @EXPORT = qw(mk_tmp_repo in_empty_repo tmp_git);
}

use File::Temp qw(tempdir);

sub mk_tmp_repo {
	my $temp_dir = tempdir( "t/tmpXXXXX", CLEANUP => 1 );
	system("cd $temp_dir; git-init >/dev/null 2>&1") == 0
		or die "git-init failed; rc=$?";
	$temp_dir;
}

use Cwd;

sub in_empty_repo {
	my $coderef = shift;
	my $old_wd = getcwd;
	my $path = mk_tmp_repo();
	chdir($path);
	$coderef->();
	chdir($old_wd);
}

use Git;
sub tmp_git {
	Git->repository(mk_tmp_repo);
}

1;
