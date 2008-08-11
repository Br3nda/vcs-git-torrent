
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
		$pipe_write->flush();

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

# temporary variable for the time between unpack_payload and action
# we need a Git object which unpack_payload doesn't have access to
my $temp_refs;

sub unpack_payload {
	my $self = shift;
	my $payload = shift;
	my ($ref_sha1, $ref_size, $ref_blob);

	while ( length($payload) ) {
		$ref_sha1 = unpack_hex(substr($payload, 0, 20));
		$ref_size = unpack_num(substr($payload, 20, 4));
		die 'invalid size' if ( 24 + $ref_size > length($payload) );
		$ref_blob = substr($payload, 24, $ref_size);

		substr($payload, 0, 24 + $ref_size) = '';

		push @{ $temp_refs }, [ $ref_sha1, $ref_size, $ref_blob ];
	}
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

	if ( $temp_refs ) { # we got some references from a peer
		my @references;

		foreach(@{$temp_refs}) {
			my ($ref_sha1, $ref_size, $ref_blob) = @{ $_ };

			my $plumb = $local_peer->torrent->plumb
			    ( [ "hash-object", 
				'-w', '--stdin', '-t', 'tag' ],
			    );
			$plumb->input(sub { print $ref_blob });
			$plumb->execute;
			my $o_sha1 = $plumb->output->contents;

			chomp($o_sha1);
			die 'invalid Reference hash'
				unless ( $o_sha1 eq $ref_sha1 );

			push @references, VCS::Git::Torrent::Reference->new(
				torrent => $local_peer->torrent,
				tag_id => $ref_sha1,
			);
		}

		# add to torrent's global list of all references
		push @{ $local_peer->torrent->references }, @references;
		# add to this connection's local peer's list
		push @{ $local_peer->references }, @references;
		# add to this connection's remote peer's list
		push @{ $connection->remote->references }, @references;
	}
	else { # it's a request for our references
		$local_peer->send_message(
			$connection->remote, GTP_PWP_REFERENCES,
			$local_peer->torrent->references
		) if ( # make sure we have references to send
			scalar(@{ $local_peer->torrent->references })
		);
	}
}

1;
