#!/usr/bin/perl -w

use strict;
use Test::More qw(no_plan);

use FindBin qw($Bin);
use File::Find;

my @modules;
my %uses;

finddepth(sub {
	m{\.pm$} && do {
		my $module = $File::Find::name;
		$module =~ s{.*/lib.}{};
		$module =~ s{[/\\]}{::}g;
		$module =~ s{.pm$}{};
		push @modules, $module;
		open MODULE, "<", $_ or die $!;
		while(<MODULE>) {
			if (m{^use (\S+)}) {
				$uses{$module}{$1}++;
			}
			if (m{^(?:extends|with) (["'])?(\S+)\1}) {
				$uses{$module}{$2}++;
			}
		}
		close MODULE;
	};
}, "$Bin/../lib");

my %done;
while (@modules) {
	my (@winners) = grep {!$uses{$_} or !keys %{$uses{$_}}} @modules;
	if (!@winners) {
		@winners = shift @modules;
	}
 	for my $module (sort @winners) {
		use_ok($module);
		$done{$module}++;
		delete $uses{$module};
		delete $_->{$module} for values %uses;
	}
	@modules = grep { !$done{$_} } @modules;
}

# Copyright (C) 2007  Sam Vilain
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program, as the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.
