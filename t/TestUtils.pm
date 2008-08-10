#!/usr/bin/perl

package t::TestUtils;

use Carp;
use base qw(Exporter);
BEGIN {
	our @EXPORT = qw(mk_tmp_repo in_empty_repo tmp_git random_port_pair);
	$SIG{__WARN__} = sub {
	    my $i = 0;
	    while (my $caller = caller($i)) {
		    if ($caller eq "Test::More") {
			    return 0;
		    }
		    $i++;
	    }
	    my $culprit = caller;
	    if ($culprit =~ m{Class::C3}) {
		return 1;
	    }
	    else {
		print STDERR "*** WARNING FROM $culprit FOLLOWS ***\n";
	    }
	    Carp::cluck(@_);
	    print STDERR "*** END OF STACK DUMP ***\n";
	    1
	}
	unless $ENV{NO_WARNING_TRACES};
}

use Cwd qw(fast_abs_path);
use File::Temp qw(tempdir);

sub mk_tmp_repo {
	my $temp_dir = tempdir( "t/tmpXXXXX", CLEANUP => 1 );
	system("cd $temp_dir; git-init >/dev/null 2>&1") == 0
		or die "git-init failed; rc=$?";
	fast_abs_path($temp_dir);
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

# return an array ref of two unprivileged ports
sub random_port_pair {
	my $port = int(rand(2**16-1024-1)+1024);
	[ $port, $port + 1 ];
}

1;
