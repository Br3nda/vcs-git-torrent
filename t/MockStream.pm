
package MockStream;
use Test::Depends qw(IO::String);
use IO::String;

use base qw(Exporter);
BEGIN { our @EXPORT = qw(stream) };

sub stream($) {
	my $string = shift;
	IO::String->new(\$string);
}

1;
