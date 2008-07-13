
package VCS::Git::Torrent::Reference;

use Moose;
use VCS::Git::Torrent;
use MooseX::TimestampTZ;

has 'torrent' =>
	is => "rw",
	weak_ref => 1,
	isa => "VCS::Git::Torrent",
	handles => [ "git", "repo_hash" ];

has 'tag_id' =>
	isa => "VCS::Git::Torrent::git_object_id",
	is => "ro",
	required => 1;

has 'tagged_object' =>
	isa => "VCS::Git::Torrent::git_object_id",
	is => "ro",
	required => 1,
	lazy => 1,
	default => \&buildTaggedObject;

has 'tagger' =>
	isa => "Str",
	is => "ro",
	required => 1,
	lazy => 1,
	default => \&buildTagger;

has 'tagdate' =>
	isa => "Str",
#	isa => "TimestampTZ",
	is => "ro",
	required => 1,
	lazy => 1,
#	coerce => 1,
	default => \&buildTagDate;

has 'comment' =>
	isa => "Str",
	is => "ro",
	required => 1,
	lazy => 1,
	default => \&buildComment;

has 'refs' =>
	isa => "HashRef[VCS::Git::Torrent::sha1_hex]",
	is => "ro",
	required => 1,
	lazy => 1,
	default => \&buildRefs;

sub buildComment {
	my $self = shift;
	my @data;
	my $comment;

	if ( $self->tag_id ) {
		unless ( $self->{_data} ) {
			@data = $self->git->command('cat-file', 'tag', $self->tag_id);
			$self->{_data} = \@data;
		}

		foreach(@{$self->{_data}}) {
			if ( /^tag (.*)$/ ) {
				$comment = $1;
				last;
			}
		}
	}

	$comment;
}

sub buildRefs {
	my $self = shift;
	my @data;
	my %refs;

	if ( $self->tag_id ) {
		unless ( $self->{_data} ) {
			@data = $self->git->command('cat-file', 'tag', $self->tag_id);
			$self->{_data} = \@data;
		}

		foreach(@{$self->{_data}}) {
			if ( /^([0-9a-f]{40})\s+(.*)$/ ) {
				$refs{$2} = $1;
			}
		}
	}

	\%refs;
}

sub buildTagDate {
	my $self = shift;
	my @data;
	my $time;

	if ( $self->tag_id ) {
		unless ( $self->{_data} ) {
			@data = $self->git->command('cat-file', 'tag', $self->tag_id);
			$self->{_data} = \@data;
		}

		foreach(@{$self->{_data}}) {
			if ( /^tagger\s+(.*)$/ ) {
				(undef, undef, $time) = $self->git->ident($1);
				last;
			}
		}
	}

	$time;
}

sub buildTaggedObject {
	my $self = shift;
	my @data;
	my $tobj;

	if ( $self->tag_id ) {
		unless ( $self->{_data} ) {
			@data = $self->git->command('cat-file', 'tag', $self->tag_id);
			$self->{_data} = \@data;
		}

		foreach(@{$self->{_data}}) {
			if ( /^object ([0-9a-f]{40})$/ ) {
				$tobj = $1;
				last;
			}
		}
	}

	$tobj;
}

sub buildTagger {
	my $self = shift;
	my @data;
	my ($name, $email);
	my $tagger;

	if ( $self->tag_id ) {
		unless ( $self->{_data} ) {
			@data = $self->git->command('cat-file', 'tag', $self->tag_id);
			$self->{_data} = \@data;
		}

		foreach(@{$self->{_data}}) {
			if ( /^tagger\s+(.*)$/ ) {
				($name, $email, undef) = $self->git->ident($1);
				$tagger = "$name <$email>";
				last;
			}
		}
	}

	$tagger;
}

sub buildTag {
	my $self = shift;
	my $tag_id = $self->tag_id;
	my $line;

	if ( $tag_id ) {
	}
	else {
		# creating a references object from scratch
		die "no refs or tag_id given"
			unless $self->refs;
	}
}

1;
