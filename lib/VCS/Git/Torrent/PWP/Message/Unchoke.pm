
package VCS::Git::Torrent::PWP::Message::Unchoke;

=head1 NAME

VCS::Git::Torrent::PWP::Message::Unchoke

=head2 DESCRIPTION

Implements the Unchoke message from the RFC.
L<http://gittorrent.utsl.gen.nz/rfc.html#pwp-unchoke>

=cut

use Moose;
with "VCS::Git::Torrent::PWP::Message";
use Carp;

sub pack_payload { }
sub unpack_payload { }

sub args {
	my $class = shift;
	croak("Unchoke has no arguments") if @_;
	return();
}
sub action {
	my $self = shift;
	my $local_peer = shift;
	my $connection = shift;
	$connection->choked_in(0);
}

1;
