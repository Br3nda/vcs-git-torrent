
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
use VCS::Git::Torrent::PWP qw(unpack_hex pack_hex pack_num unpack_num);

has 'reels' =>
	isa => "ArrayRef[VCS::Git::Torrent::CommitReel]",
	is => "rw",
	trigger => sub {
		my $self = shift;
		$self->payload($self->pack_payload);
	};

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

	my @reels;
	while ( length($payload) ) {
		my (@sha1_pair) = map { unpack_hex($_) }
			(substr($payload, 0, 20),
			 substr($payload, 20, 20));

		my @args =
			( start => $sha1_pair[0],
			  end => $sha1_pair[1] );

		my $size = unpack_num(substr($payload, 40, 4));
		substr($payload, 0, 44)="";

		push @args, ( size => $size );
		push @reels,
			VCS::Git::Torrent::CommitReel::Remote->new(@args);
	}

	$self->reels(\@reels);
}

sub args {
	my $class = shift;
	my $reels = [ @_ ];
	croak("Choke has no arguments") if @_;
	return( reels => $reels );
}

sub action {
	my $self = shift;
	my $local_peer = shift;
	my $connection = shift;

	$connection
}

1;
