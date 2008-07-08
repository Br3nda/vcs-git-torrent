
package VCS::Git::Torrent::Peer::Async::Socket;

use Moose::Role;
with 'VCS::Git::Torrent::Peer::Async::State';

use Coro::RWLock;

BEGIN {
	# clean import workaround for bug:
	# Bareword "Coro::Semaphore::guard::" refers to nonexistent package
	# known to exist in perl 5.8.8, and not trappable via $SIG{__WARN__}
	#local ($^W) = 0;
	local($Coro::State::WARNHOOK) = sub { };
	require Coro::Socket;
	Coro::Socket->import();
}

has 'socket' =>
	isa      => "Coro::Socket",
	is       => "ro",
	required => 1,
	lazy     => 1,
	default => sub {
		my $self = shift;
		confess "something tried to grab my socket too soon"
			unless Coro::current == $self->coro;
		$self->trace(sub{"creating socket - @{[$self->socket_args]}"});
		new Coro::Socket
			( ( defined($self->timeout)
			    ? ( Timeout => $self->timeout )
			    : () ),
			  $self->socket_args );
	};

requires 'socket_args';

has 'send_lock' =>
	isa => 'Coro::RWLock',
	is => "ro",
	lazy => 1,
	default => sub { my $x = new Coro::RWLock; $x->wrlock; $x };

has 'recv_lock' =>
	isa => 'Coro::RWLock',
	is => "ro",
	lazy => 1,
	default => sub { my $x = new Coro::RWLock; $x->wrlock; $x };

has 'timeout' =>
	isa => "Int",
	is  => "rw",
	default => "120",
	trigger => sub {
		my $self = shift;
		if ( $self->{socket} ) {
			$self->{socket}->timeout($self->timeout);
		}
	};

1;

