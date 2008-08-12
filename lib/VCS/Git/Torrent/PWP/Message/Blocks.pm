
package VCS::Git::Torrent::PWP::Message::Blocks;

=head1 NAME

VCS::Git::Torrent::PWP::Message::Blocks

=head2 DESCRIPTION

Implements the Blocks message from the RFC.
L<http://gittorrent.utsl.gen.nz/rfc.html#pwp-blocks>

=cut

use Moose;
with "VCS::Git::Torrent::PWP::Message";
use Carp;
use VCS::Git::Torrent::PWP qw(:pwp_constants unpack_hex pack_hex pack_num unpack_num);

has 'bits' =>
	isa => 'Value',
	is => 'rw',
	required => 0;

has 'num_bits' =>
	isa => 'Int',
	is => 'rw',
	required => 0;

has 'reel_sha1_pair' =>
	isa => 'ArrayRef',
	is => 'rw';

sub pack_payload {
	my $self = shift;
	my $payload = '';

	$payload .= join('', map { pack_hex($_ ) } @{ $self->reel_sha1_pair });
	$payload .= pack_num($self->num_bits) if ( $self->num_bits );
	$payload .= $self->bits if ( $self->bits );

	$payload;
}

sub unpack_payload {
	my $self = shift;
	my $payload = shift;

	my @sha1_pair = map { unpack_hex($_) } (
		substr($payload, 0, 20),
		substr($payload, 20, 20)
	);
	$self->reel_sha1_pair(\@sha1_pair);

	if ( length($payload) > 40 ) {
		my $num_bits = unpack_num(substr($payload, 40, 4));
		$self->num_bits($num_bits);

		my $bits = substr($payload, 44);
		$self->bits($bits);
	}
}

sub args {
	my $class = shift;
	my $reel;
	my $reel_sha1_pair;

	if ( ref($_[0]) eq 'VCS::Git::Torrent::CommitReel' ) {
		$reel = shift;
		$reel_sha1_pair = $reel->reel_id;
	}
	else {
		$reel_sha1_pair = [ shift, shift ];
	}

	my $num_bits = shift;
	my $bits = shift;

	my %args;

	$args{'bits'} = $bits if ( $bits );
	$args{'num_bits'} = $num_bits if ( $num_bits );
	$args{'reel_sha1_pair'} = $reel_sha1_pair;

	return(%args);
}

sub action {
	my $self = shift;
	my $local_peer = shift;
	my $connection = shift;

	my ($start, $end) = @{ $self->reel_sha1_pair };

	if ( $self->bits ) {
		# HACK
		for(my $i = 0; $i < $self->num_bits; $i++) {
			$local_peer->send_message(
				$connection->remote, GTP_PWP_PLAY,
				$start, $end, $i
			);
		}
	}
	else {
		my $reel;

		foreach( @{ $local_peer->torrent->reels } ) {
			$reel = $_;

			last if (
				$reel->reel_id->[0] eq $start &&
				$reel->reel_id->[1] eq $end
			);
		}

		if ( $reel ) {
			my @bits = map {
				$_->{'in_repo'}
			} @{ $reel->commit_info };

			my $bits = pack('b' . scalar(@bits), join('', @bits));

			$local_peer->send_message(
				$connection->remote, GTP_PWP_BLOCKS,
				$start, $end, scalar(@bits), $bits
			);
		}
	}
}

1;
