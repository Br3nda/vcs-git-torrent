
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
	required => 0,
	isa => "VCS::Git::Torrent",
	handles => [ "git", "repo_hash", "plumb", "cat_file" ];

use IO::Plumbing qw(bucket);
use Carp;

has 'tag_id' =>
	isa => "VCS::Git::Torrent::git_object_id",
	is => "ro",
	required => 1,
	lazy => 1,
	default => \&buildTag;

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

	my $state = "header";

	my @comment;
	foreach(@{$self->_data}) {
		if ($state eq "header" and $_ eq "") {
			$state = "body";
		}
		elsif ($state eq "body") {
			if ( /^([0-9a-f]{40})\s+(.*)$/ ) {
				$state = "refs";
			}
			else {
				push @comment, $_, "\n";
			}
		}
	}

	join "", @comment;
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
		$epoch += $offset_s;
		$time = timestamp(gmtime $epoch).$offset;
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

# creating a references object from scratch
sub buildTag {
	my $self = shift;
	my $tag_id;
	die if $self->{_data};

#	die "no refs or tag_id given" unless ( $self->{refs} );

	my $tag_generator = sub {
		print map { $_, "\n" }
			('object ' . $self->tagged_object,
			 "type commit",
			 "tag gtp-dummy",
			 'tagger ' . $self->tagger
				 . " " . $self->tagdate_git,
			 "",
			);

		my $comment = $self->comment;
		print $comment;
		if ($comment !~ m{\n\Z}) {
			print "\n";
		}

		my $refs = $self->refs;
		for my $ref (sort keys %$refs) {
			print $refs->{$ref}, " ", $ref, "\n";
		}
	};

	my $bucket = bucket;

	$self->plumb
		([ "hash-object", "-w", "-t", "tag", "--stdin" ],
		 output => $bucket,
		 input => IO::Plumbing::plumb(sub { $tag_generator->() }),
		)->execute;

	$tag_id = $bucket->contents;
	chomp($tag_id);
	$tag_id;
}

1;
