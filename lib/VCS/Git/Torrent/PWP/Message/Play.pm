
package VCS::Git::Torrent::PWP::Message::Play;

=head1 NAME

VCS::Git::Torrent::PWP::Message::Play

=head2 DESCRIPTION

Implements the Play message from the RFC.
L<http://gittorrent.utsl.gen.nz/rfc.html#pwp-play>

=cut

use IO::Plumbing qw(bucket vent);
use Moose;
with "VCS::Git::Torrent::PWP::Message";
use Carp;
use VCS::Git::Torrent::PWP qw(:pwp_constants unpack_hex pack_hex pack_num unpack_num);

has 'data' =>
	isa => 'Value',
	is => 'rw';

has 'data_len' =>
	isa => 'Int',
	is => 'rw';

has 'offset' =>
	isa => 'Int',
	is => 'rw';

has 'reel_sha1_pair' =>
	isa => 'ArrayRef',
	is => 'rw';

sub pack_payload {
	my $self = shift;
	my $payload = '';

	$payload .= join('', map { pack_hex($_ ) } @{ $self->reel_sha1_pair });
	$payload .= pack_num($self->offset);
	$payload .= pack_num($self->data_len) if ( $self->data_len );
	$payload .= $self->data if ( $self->data );

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

	my $offset = unpack_num(substr($payload, 40, 4));
	$self->offset($offset);

	if ( length($payload) > 44 ) {
		my $data_len = unpack_num(substr($payload, 44, 4));
		$self->data_len($data_len);

		my $data = substr($payload, 48, $data_len);
		$self->data($data);
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

	my $offset = shift;
	my $data_len = shift;
	my $data = shift;

	my %args;

	$args{'data'} = $data if ( $data );
	$args{'data_len'} = $data_len if ( $data_len );
	$args{'offset'} = $offset;
	$args{'reel_sha1_pair'} = $reel_sha1_pair;

	return(%args);
}

sub action {
	my $self = shift;
	my $local_peer = shift;
	my $connection = shift;

	my ($start, $end) = @{ $self->reel_sha1_pair };

	if ( $self->data_len && $self->data ) { # we got data
		my $bucket = bucket($self->data);

		my $unpack = $local_peer->torrent->plumb(
			[ 'unpack-objects' ],
			input => $bucket,
			stderr => vent(),
		);

		$unpack->execute();
		$unpack->wait();
	}
	else { # it was a request for data
		my $reel;

		foreach( @{ $local_peer->torrent->reels } ) {
			$reel = $_;

			last if (
				$reel->reel_id->[0] eq $start &&
				$reel->reel_id->[1] eq $end
			);
		}

		if ( $reel ) {
			my $commit = $reel->commit_info->[$self->offset];
			my $prev_commit = (
				  $self->offset
				? $reel->commit_info->[$self->offset - 1]
				: undef
			);

			my @cmd = ( 'rev-list', '--objects-edge' );
			push @cmd, ( '^' . $prev_commit->{'objectid'} )
				if ( $prev_commit );
			push @cmd, ( $commit->{'objectid'} );

			my $rev_list = $local_peer->torrent->plumb(
				\@cmd,
				stderr => vent(),
			);

			$rev_list->output($local_peer->torrent->plumb(
				[ 'pack-objects', '--stdout' ],
				stderr => vent(),
			));

			my $pack = $rev_list->terminus->contents;

			$local_peer->send_message(
				$connection->remote, GTP_PWP_PLAY,
				$start, $end, $self->offset,
				length($pack), $pack
			) if ( length($pack) );
		}
	}
}

1;
