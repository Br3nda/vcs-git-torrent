
package VCS::Git::Torrent::PWP::Message::Choke;

use Moose;
with "VCS::Git::Torrent::PWP::Message";
use Carp;

sub payload { }
sub args {
	my $class = shift;
	croak("Choke has no arguments") if @_;
	return();
}

1;
