# ex:ts=8 sw=4:
# $OpenBSD: Reporter.pm,v 1.30 2019/05/08 09:10:54 espie Exp $
#
# Copyright (c) 2010-2013 Marc Espie <espie@openbsd.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use strict;
use warnings;

use OpenBSD::Error;
use DPB::Util;
use DPB::Clock;

package DPB::Reporter;
my $singleton;

sub ttyclass() 	
{
	require DPB::Reporter::Tty;
	return "DPB::Reporter::Tty";
}

sub term_send
{
}

sub reset_cursor
{
	my $self = shift;
	print $self->{visible} if defined $self->{visible};
}

sub set_cursor
{
	my $self = shift;
	print $self->{invisible} if defined $self->{invisible};
}

sub reset
{
	my $self = shift;
	$self->reset_cursor;
	print $self->{clear} if defined $self->{clear};
}

sub set_sigtstp
{
	my $self =shift;
	$SIG{TSTP} = sub {
		$self->reset_cursor;
		DPB::Clock->stop;
		$SIG{TSTP} = 'DEFAULT';
		local $> = 0;
		kill TSTP => $$;
	};
}

sub set_sig_handlers
{
	my $self = shift;
	$self->set_sigtstp;
}

sub sig_received
{
	my ($self, $iscont) = @_;
	if ($iscont) {
		$self->set_sigtstp;
		$self->{continued} = 1;
		DPB::Clock->restart;
	}
	$self->handle_window;
}

sub refresh
{
}

sub handle_window
{
}

sub filter_add
{
	my ($self, $l, $r, $method) = @_;
	for my $prod (@$r) {
		push @$l, $prod if $prod->can($method);
	}
}

sub new
{
	my $class = shift;
	my $state = shift;
	my $dotty;
	if ($state->opt('x')) {
		$dotty = 0;
	} elsif ($state->opt('m')) {
		$dotty = 1;
	} else {
		$dotty = -t STDOUT;
	}
		
	if ($dotty) {
		$class = $class->ttyclass;
	}
	$class->make_singleton($state)->add_producers(@_);
}

sub make_singleton
{
	my ($class, $state) = @_;
	return if defined $singleton;
	$singleton = bless {msg => '',
	    producers => [],
	    timeout => $state->{display_timeout} // 10,
	    state => $state,
	    continued => 0}, $class;
	$state->{reporter} = $singleton;
    	if ($state->{record}) {
		$singleton->{record} =
		    $state->{log_user}->open('>>', $state->{record});
	}
	return $singleton;
}

sub add_producers
{
	my $self = shift;
	$self->filter_add($self->{producers}, \@_, $self->filter);
	return $self;
}

sub filter
{
	'important';
}
sub timeout
{
	my $self = shift;
	return $self->{timeout};
}

sub report
{
	my $self = shift;
	for my $prod (@{$self->{producers}}) {
		my $important = $prod->important;
		if ($important) {
			print $important;
		}
	}
}

sub myprint
{
	my $self = shift;
	if (!ref $self) {
		$singleton->myprint(@_);
	} else {
		print @_;
	}
}

1;
