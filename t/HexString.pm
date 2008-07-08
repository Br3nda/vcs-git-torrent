
package HexString;

use base qw(Exporter);
our @EXPORT = qw(hex_string string_hex);

use utf8;

sub hex_string {
	my $string = shift;
	utf8::downgrade($string);
	$string =~ s{(.)}{sprintf("%.2x", ord($1))}eg;
	$string;
}

sub string_hex {
	my $string = shift;
	$string =~ s{(..)}{chr(hex($1))}eg;
	$string;
}

1;
