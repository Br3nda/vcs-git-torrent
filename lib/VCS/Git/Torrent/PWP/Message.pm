
=head1 NAME

VCS::Git::Torrent::PWP::Message - role for PWP messages

=head1 SYNOPSIS

 package VCS::Git::Torrent::PWP::Message::Foo;

 extends 'VCS::Git::Torrent::PWP::Message';

 sub pack {
     ...
 }

 sub unpack {
     ...
 }

 1;

=head1 DESCRIPTION

This is a base class for PWP messages.

Messages must define their data members themselves, but critically,
return the body of the message as sent on the wire with "pack", and
accept a message with "unpack", setting up their relevant members.

=cut

