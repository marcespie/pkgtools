# ex:ts=8 sw=4:
# $OpenBSD: Tty.pm,v 1.7 2019/05/08 09:10:54 espie Exp $
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

use DPB::MiniCurses;

package DPB::Reporter::Tty;
our @ISA = qw(DPB::MiniCurses DPB::Reporter DPB::Limiter);

my $extra = '';
sub handle_window
{
	my $self = shift;
	$self->set_cursor;
	$self->SUPER::handle_window;
}

sub set_sig_handlers
{
	my $self = shift;
	$self->SUPER::set_sig_handlers;
	OpenBSD::Handler->register(sub {
		$self->reset_cursor; });
}

sub filter
{
	'report';
}

sub make_singleton
{
	my ($class, $state) = @_;
	my $self = $class->SUPER::make_singleton($state);
	$self->create_terminal;
	$self->set_sig_handlers;
	# no cursor, to avoid flickering
	$self->set_cursor;
	return $self;
}

sub report
{
	my ($self, $force) = @_;
	if ($self->{force}) {
		$force = 1;
		undef $self->{force};
	}
	$self->limit($force, 150, "REP", 1,
	    sub {
		my $msg = "";
		for my $prod (@{$self->{producers}}) {
			$msg.= $prod->report;
		}
		$msg .= $extra;
		if ($msg ne $self->{msg} || $self->{continued}) {
			if (defined $self->{record}) {
				print {$self->{record}} "@@@", time(), "\n";
				print {$self->{record}} $msg;
			}
			$self->{continued} = 0;
			my $method = $self->{write};
			$self->$method($msg);
			$self->{msg} = $msg;
		}
	    });
}

sub myprint
{
	my $self = shift;
	for my $string (@_) {
		$string =~ s/^\t/       /gm; # XXX dirty hack for warn
		$extra .= $string;
	}
}

1;
