
package VCS::Git::Torrent::PWP::Message::References;

=head1 NAME

VCS::Git::Torrent::PWP::Message::References

=head2 DESCRIPTION

Implements the References message from the RFC.
L<http://gittorrent.utsl.gen.nz/rfc.html#pwp-references>

=cut

use Moose;
with "VCS::Git::Torrent::PWP::Message";
use Carp;
use VCS::Git::Torrent::PWP qw(:pwp_constants unpack_hex pack_hex pack_num unpack_num);

has 'references' =>
	isa => 'ArrayRef[VCS::Git::Torrent::Reference]',
	is => 'rw';

sub pack_payload {
	my $self = shift;
	my $payload = '';
	my ($pipe_read, $pipe_write);
	my ($ref_type, $ref_size);
	my $ref_contents;
	my $rv;

	for my $reference ( @{ $self->references } ) {
		$payload .= pack_hex($reference->tag_id);

		$pipe_read  = $reference->cat_file->[1];
		$pipe_write = $reference->cat_file->[2];

		print $pipe_write $reference->tag_id . "\n";

		(undef, $ref_type, $ref_size) = split(/\s/, <$pipe_read>);
		die 'Reference tag_id does not exist in git repo?'
			if ( $ref_type eq 'missing' );

		$rv = read $pipe_read, $ref_contents, $ref_size;
		die "only read $rv of $ref_size bytes for Reference object"
			if ( $rv != $ref_size );

		$payload .= pack_num($ref_size);
		$payload .= $ref_contents;
	}

	$payload;
}

sub unpack_payload {
	my $self = shift;
	my @references;

	$self->references(\@references);
}

sub args {
	my $class = shift;
	my $references;

	if ( ref($_[0]) eq 'ARRAY' ) {
		$references = shift;
	}
	else {
		$references = [ @_ ];
	}

	return( references => $references );
}

sub action {
	my $self = shift;
	my $local_peer = shift;
	my $connection = shift;

	if ( @{ $self->references } ) {
		$connection->remote->references($self->references);
	}
	else { # it's a request for our references
		$local_peer->send_message(
			$connection->remote, GTP_PWP_REFERENCES,
			$local_peer->torrent->references
		);
	}
}

1;
