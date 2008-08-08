
package VCS::Git::Torrent::PWP::Message::Reels;

=head1 NAME

VCS::Git::Torrent::PWP::Message::Reels

=head1 SYNOPSIS

 use VCS::Git::Torrent::PWP qw(:all);
 my $reels_message = pwp_message( GTP_PWP_REELS, @reels );

=head2 DESCRIPTION

Implements the Reels message from the RFC.
L<http://gittorrent.utsl.gen.nz/rfc.html#pwp-reels>

=cut

use Moose;
with "VCS::Git::Torrent::PWP::Message";
use Carp;
use VCS::Git::Torrent::PWP qw(:pwp_constants unpack_hex pack_hex pack_num unpack_num);

has 'reels' =>
	isa => "ArrayRef[VCS::Git::Torrent::CommitReel]",
	is => "rw",
#	trigger => sub {
#		my $self = shift;
#		$self->payload($self->pack_payload);
#	};
;

sub pack_payload {
	my $self = shift;
	my $payload = "";

	for my $reel ( @{ $self->reels } ) {
		my (@sha1_pair) = @{ $reel->reel_id };
		$payload .= join("", (map { pack_hex($_) } @sha1_pair));
		$payload .= pack_num($reel->size);
	}

	$payload;
}

sub unpack_payload {
	my $self = shift;
	my $payload = shift;

	(length($payload) % 44) == 0
		or croak "bad Reels payload length ".length($payload);

	my %args;
	my @reels;
	while ( length($payload) ) {
		my (@sha1_pair) = map { unpack_hex($_) }
			(substr($payload, 0, 20),
			 substr($payload, 20, 20));

		$args{'start'} = $sha1_pair[0];
		$args{'end'} = $sha1_pair[1];

		my $size = unpack_num(substr($payload, 40, 4));
		substr($payload, 0, 44)="";

		$args{'size'} = $size;
		push @reels,
			VCS::Git::Torrent::CommitReel->new(%args);
	}

	$self->reels(\@reels);
}

sub args {
	my $class = shift;
	my $reels;

	if ( ref($_[0]) eq 'ARRAY' ) {
		$reels = shift;
	}
	else {
		$reels = [ @_ ];
	}

	return( reels => $reels );
}

sub action {
	my $self = shift;
	my $local_peer = shift;
	my $connection = shift;

	if ( @{$self->reels} ) { # we got some reels from someone
		$connection->remote->reels($self->reels);
	}
	else { # it was a request for our reels
		$local_peer->send_message($connection->remote, GTP_PWP_REELS,
			$local_peer->torrent->reels
		);
	}
}

1;
