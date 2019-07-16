# ex:ts=8 sw=4:
# $OpenBSD: Serialize.pm,v 1.2 2018/01/07 10:49:15 espie Exp $
#
# Copyright (c) 2013 Marc Espie <espie@openbsd.org>
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

# use to read/write some log files in a sensible fashion
package DPB::Serialize;

sub read
{
	my ($class, $line) = @_;

	chomp $line;
	my @list = $class->list;
	my $r = {};
	my @e = split(/\s+/, $line);
	if (@e >= 1) {
		$r->{pkgpath} = shift @e;
		if ($r->{pkgpath} =~ m/^(.*)\((.*)\)$/) {
			($r->{pkgpath}, $r->{pkgname}) = ($1, $2);
		}
		while (@e > 0) {
			my $v = shift @e;
			if ($v =~ m/^(\w+)\=(.*)$/) {
				$r->{$1} = $2;
			} else {
				my $k = shift @list or return;
				$r->{$k} = $v;
			}
		}
    	}
	return $r;
}

sub write
{
	my ($class, $r) = @_;

	my @r = ();
	if ($r->{pkgname}) {
		push(@r, "$r->{pkgpath}($r->{pkgname})");
	} else {
		push(@r, $r->{pkgpath});
	}
	for my $k ($class->list) {
		if (defined $r->{$k}) {
			push(@r, "$k=$r->{$k}");
		}
	}
	return join(' ', @r);
}

package DPB::Serialize::Build;
our @ISA = qw(DPB::Serialize);
sub list
{
	return (qw(host time size ts));
}

package DPB::Serialize::Size;
our @ISA = qw(DPB::Serialize);
sub list
{
	return (qw(size ts));
}

1;
