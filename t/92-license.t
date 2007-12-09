#!/usr/bin/perl -w

use strict;
use Test::More;
plan skip_all => 'set TEST_LICENSE to enable this test'
	unless $ENV{TEST_LICENSE};
plan "no_plan";

use FindBin qw($Bin);
use File::Find;

find(sub {
	if (m{\.(pm|pl|t)$}) {
		open FILE, "<", $_ or die $!;
		while ( <FILE> ) {
			m{Copyright} && do {
				pass("$File::Find::name mentions Copyright");
				return;
			};
		}
		close FILE;
		fail("$File::Find::name missing license text");
	}
}, $Bin, "$Bin/../lib");

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
