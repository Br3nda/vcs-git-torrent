
package VCS::Git::Torrent::PWP::Message::Peers;

=head1 NAME

VCS::Git::Torrent::PWP::Message::Peers

=head2 DESCRIPTION

Implements the Peers message from the RFC.
L<http://gittorrent.utsl.gen.nz/rfc.html#pwp-peers>

=cut

use Moose;
with "VCS::Git::Torrent::PWP::Message";
use Carp;
use VCS::Git::Torrent::PWP qw(:pwp_constants unpack_hex pack_hex pack_num unpack_num);

has 'peers' =>
	isa => "ArrayRef[VCS::Git::Torrent::Peer]",
	is => "rw",
;

sub pack_payload {
	my $self = shift;
	my $payload = "";

	for my $peer ( @{ $self->peers } ) {
		$payload .= $peer->peer_id;
		$payload .= pack('n', $peer->port);
		$payload .= pack_num(length($peer->address));
		$payload .= $peer->address;
	}

	$payload;
}

my $temp_peers = [];

sub unpack_payload {
	my $self = shift;
	my $payload = shift;

	while ( length($payload) ) {
		my $peer_id = substr($payload, 0, 20);
		my $peer_port = unpack('n', substr($payload, 20, 2));
		my $addr_len = unpack_num(substr($payload, 22, 4));
		die 'invalid size' if ( 26 + $addr_len > length($payload) );
		my $peer_addr = substr($payload, 26, $addr_len);

		substr($payload, 0, 26 + $addr_len) = '';

		push @{ $temp_peers }, [ $peer_id, $peer_port, $peer_addr ];
	}
}

sub args {
	my $class = shift;
	my $peers;

	if ( ref($_[0]) eq 'ARRAY' ) {
		foreach(@_) {
			push @{ $peers }, @{ $_ };
		}
	}
	else {
		$peers = [ @_ ];
	}

	return( peers => $peers );
}

sub action {
	my $self = shift;
	my $local_peer = shift;
	my $connection = shift;

	if ( scalar(@{ $temp_peers }) ) { # we got some peers from someone
		my @peers = ();

		for my $peer (@{ $temp_peers }) {
			push @peers, VCS::Git::Torrent::Peer->new(
				repo_hash => $local_peer->repo_hash,
				peer_id   => $peer->[0],
				peer_port => $peer->[1],
				peer_addr => $peer->[2],
			);
		}

		$self->peers(\@peers);

		# check for duplicates
		my @new_peers = map {
			my $peer = $_;

			my $num = grep {
				$peer->peer_id eq $_->peer_id # && ?
			} @{ $local_peer->knows };

			$num ? () : ($peer)
		} @{ $self->peers };

		push @{ $local_peer->knows }, @new_peers;
#		push @{ $connection->remote->peers }, @{ $self->peers };
	}
	else { # it was a request for our peers
		my @remotes = map {
			$_->remote->port ? $_->remote : ()
		} @{ $local_peer->connections };

		$local_peer->send_message($connection->remote, GTP_PWP_PEERS,
			$local_peer->knows,
			\@remotes,
		) if (
			scalar(@{ $local_peer->knows }) ||
			scalar(@remotes)
		);
	}
}

1;
