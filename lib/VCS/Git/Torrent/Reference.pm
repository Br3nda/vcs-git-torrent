
package VCS::Git::Torrent::Reference;

=head1 NAME

VCS::Git::Torrent::Reference - git repository state, encapsulated in a tag

=head1 SYNOPSIS

 use VCS::Git::Torrent::Reference;

 # in this form, the other parameters are pulled from the specified tag
 my $ref = VCS::Git::Torrent::Reference->new(
     torrent => $t, # VCS::Git::Torrent object
     tag_id  => $tagid,
 );

 print $ref->tagged_object . "\n";
 print $ref->tagger . "\n";
 print $ref->tagdate . "\n";
 print $ref->comment . "\n";

 foreach(keys(%{$ref->refs})) {
     print $_ . " => " . $ref->refs->{$_} . "\n";
 }

=head1 DESCRIPTION

This module provides a representation of the reference object, AKA the signed
repository reference list encapsulated in a git tag.

=cut

use strict;
use warnings;

use Moose;
use VCS::Git::Torrent;
use MooseX::Timestamp qw(timestamp);
use MooseX::TimestampTZ qw(offset_s epochtz zone);

has 'torrent' =>
	is => "rw",
	weak_ref => 1,
	required => 1,
	isa => "VCS::Git::Torrent",
	handles => [ "git", "repo_hash" ];

has 'tag_id' =>
	isa => "VCS::Git::Torrent::git_object_id",
	is => "ro",
#	required => 1;
	;

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
#	isa => "Str",
	isa => "TimestampTZ",
	is => "ro",
	required => 1,
	lazy => 1,
	coerce => 1,
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

=head2 buildComment

=head2 buildRefs

=head2 buildTagDate

=head2 buildTaggedObject

=head2 buildTagger

Internal functions to populate any uninitialized parameters, when possible.

=cut

sub _data {
	my $self = shift;
	if ( $self->{tag_id} ) {
		return $self->{_data} ||= do {
			my @data = $self->git->command
				('cat-file', 'tag', $self->tag_id);
			\@data;
		};
	}
	else {
		croak "missing fields on Reference";
	}
}

sub buildComment {
	my $self = shift;
	my $comment;

	foreach(@{$self->_data}) {
		if ( /^tag (.*)$/ ) {
			$comment = $1;
			last;
		}
	}

	$comment;
}

sub buildRefs {
	my $self = shift;
	my %refs;

	foreach(@{$self->_data}) {
		if ( /^([0-9a-f]{40})\s+(.*)$/ ) {
			$refs{$2} = $1;
		}
	}

	\%refs;
}

sub tagdate_git {
	my $self = shift;
	my ($epoch, $offset) = epochtz $self->tagdate;
	$epoch . " " . zone($offset);
}

sub buildTagDate {
	my $self = shift;
	my @data;
	my $time;

	foreach(@{$self->_data}) {
		if ( /^tagger\s+(.*)$/ ) {
			(undef, undef, $time) = $self->git->ident($1);
			last;
		}
	}

	if (my ($epoch, $offset) = ($time =~ m{(\d+)\s*([+\-]\d+)})) {
		my $offset_s = offset_s($offset);
		$epoch += $offset;
		$time = timestamp($epoch).$offset;
	}

	$time;
}

sub buildTaggedObject {
	my $self = shift;
	my @data;
	my $tobj;

	foreach(@{$self->_data}) {
		if ( /^object ([0-9a-f]{40})$/ ) {
			$tobj = $1;
			last;
		}
	}

	$tobj;
}

sub buildTagger {
	my $self = shift;
	my @data;
	my ($name, $email);
	my $tagger;

	foreach(@{$self->_data}) {
		if ( /^tagger\s+(.*)$/ ) {
			($name, $email, undef) = $self->git->ident($1);
			$tagger = "$name <$email>";
			last;
		}
	}

	$tagger;
}

#sub buildTag {
#	my $self = shift;
#	my $tag_id = $self->tag_id;
#	my $line;
#
#	if ( $tag_id ) {
#	}
#	else {
#		# creating a references object from scratch
#		die "no refs or tag_id given"
#			unless $self->refs;
#	}
#}

1;
