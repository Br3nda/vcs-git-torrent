
package VCS::Git::Torrent::PWP::Message::Choke;

=head1 NAME

VCS::Git::Torrent::PWP::Message::Choke

=head2 DESCRIPTION

Implements the Choke message from the RFC.
L<http://gittorrent.utsl.gen.nz/rfc.html#anchor33>

=cut

use Moose;
with "VCS::Git::Torrent::PWP::Message";
use Carp;

sub payload { }
sub args {
	my $class = shift;
	croak("Choke has no arguments") if @_;
	return();
}
sub action {
	my $self = shift;
	my $local_peer = shift;
	my $connection = shift;
	$connection->choked_in(1);
}

1;
