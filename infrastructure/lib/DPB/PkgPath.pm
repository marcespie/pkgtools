# ex:ts=8 sw=4:
# $OpenBSD: PkgPath.pm,v 1.55 2019/05/11 15:31:12 espie Exp $
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

# Handles PkgPath;
# all this code is *seriously* dependent on unique objects
# everything is done to normalize PkgPaths, so that we have
# one pkgpath object for each distinct flavor/subpackage combination

use DPB::BasePkgPath;
use DPB::Util;

package DPB::PkgPath;
our @ISA = qw(DPB::BasePkgPath);

sub init
{
	my $self = shift;
	# XXX
	$self->{has} = 5;
}

sub forcejunk
{
	return 0;
}

sub path
{
	my $self = shift;
	return $self;
}

sub clone_properties
{
	my ($n, $o) = @_;
	$n->{has} //= $o->{has};
	$n->{info} //= $o->{info};
}

sub sanity_check
{
	my ($class, $state) = @_;

	my $quicklog = $state->logger->append('equiv');
	for my $p ($class->seen) {
		next if defined $p->{category};
		next unless defined $p->{info};
		for my $w ($p->build_path_list) {
			if (!defined $w->{info}) {
				print $quicklog $w->fullpkgpath, 
				    " has no info(", $p->fullpkgpath, ")\n";
				$w->{info} = DPB::PortInfo->stub;
			} elsif (!defined $w->{info}{FULLPKGNAME}) {
				print $quicklog $w->fullpkgpath,
				    " has no fullpkgname(", 
				    $p->fullpkgpath, ")\n";
				$w->{info} = DPB::PortInfo->stub;
			}
		}
	}
}

# XXX All this code knows too much about PortInfo for proper OO

sub fullpkgname
{
	my $self = shift;
	if (defined $self->{info} && defined $self->{info}{FULLPKGNAME}) {
		return ${$self->{info}{FULLPKGNAME}};
	} else {
		DPB::Util->die(
		    $self->fullpkgpath." has no associated fullpkgname", 
		    $self->{info});
	}
}

sub has_fullpkgname
{
	my $self = shift;
	return defined $self->{info} && defined $self->{info}{FULLPKGNAME};
}

# requires flavor as a hash
sub flavor
{
	my $self = shift;
	return $self->{info}{FLAVOR};
}

sub subpackage
{
	my $self = shift;
	if (defined $self->{info} && defined $self->{info}{SUBPACKAGE}) {
		return ${$self->{info}{SUBPACKAGE}};
	} else {
		return undef;
	}
}

sub dump
{
	my ($self, $fh) = @_;
	print $fh $self->fullpkgpath, "\n";
	if (defined $self->{info}) {
		$self->{info}->dump($fh);
	}
}

sub quick_dump
{
	my ($self, $fh) = @_;
	print $fh $self->fullpkgpath, "\n";
	if (defined $self->{info}) {
		$self->{info}->quick_dump($fh);
	}
}

# interface with logger/lock engine
sub logname
{
	my $self = shift;
	return $self->fullpkgpath;
}

sub lockname
{
	my $self = shift;
	return $self->pkgpath;
}

sub print_parent
{
	my ($self, $fh) = @_;
	if (defined $self->{parent}) {
		print $fh "parent=", $self->{parent}->logname, "\n";
	}
}

sub write_parent
{
	my ($self, $lock) = @_;
	if (defined $self->{parent}) {
		$lock->write("parent", $self->{parent}->logname);
	}
}

sub unlock_conditions
{
	my ($v, $engine) = @_;
	if (!$v->{info}) {
		return 0;
	}
	my $sub = $engine->{buildable};
	for my $w ($v->build_path_list) {
		return 0 unless $sub->{builder}->check($w);
	}
	return 1;
}

sub requeue
{
	my ($v, $engine) = @_;
	$engine->requeue($v);
}

sub simplifies_to
{
	my ($self, $simpler, $state) = @_;
	$state->{affinity}->simplifies_to($self, $simpler);
	my $quicklog = $state->logger->append('equiv');
	print $quicklog $self->fullpkgpath, " -> ", $simpler->fullpkgpath, "\n";
}

sub equates
{
	my ($class, $h) = @_;
	DPB::Job::Port->equates($h);
	DPB::Heuristics->equates($h);
}

# in the MULTI_PACKAGES case, some stuff may need to be forcibly removed
sub fix_multi
{
	my ($class, $h) = @_;

	my $multi;
	my $may_vanish;
	my $path;
	for my $v (values %$h) {
		$path //= $v; # one for later
		my $info = $v->{info};
		# share !
		if (defined $info->{BUILD_PACKAGES}) {
			$multi = $info->{BUILD_PACKAGES};
		}
		# and this one is special
		if (defined $info->{MULTI_PACKAGES}) {
			$may_vanish = $info->{MULTI_PACKAGES};
		}
	}
	# in case BUILD_PACKAGES "erases" some multi, we need to
	# stub out the correspond paths, so that dependent ports
	# will vanish
	if (defined $may_vanish) {
		for my $m (keys %$may_vanish) {
			# okay those are actually present
			next if exists $multi->{$m};

			# make a dummy path that will get ignored
			my $stem = $path->pkgpath_and_flavors;
			my $w = DPB::PkgPath->new("$stem,$m");
			if (!defined $w->{info}) {
				$w->{info} = DPB::PortInfo->new($w);
				$w->{info}->stub_name;
			}
			#delete $w->{info}->{IGNORE};
			if (!defined $w->{info}->{IGNORE}) {
				$w->{info}->add('IGNORE', 
				    "vanishes from BUILD_PACKAGES");
			}
			$h->{$w} = $w;
		}
	}
	if (defined $multi) {
		for my $v (values %$h) {
			$v->{info}{BUILD_PACKAGES} = $multi;
		}
	}
}

# we're always called from values corresponding to the same subdir.
sub merge_depends
{
	my ($class, $h) = @_;

	$class->fix_multi($h);

	my $global = bless {}, "AddDepends";
	my $global2 = bless {}, "AddDepends";
	my $global3 = bless {}, "AddDepends";
	my $global4 = bless {}, "AddDepends";
	for my $v (values %$h) {
		my $info = $v->{info};

		# let's allow doing that even for ignore'd stuff so
		# that dpb -F will work
		if (defined $info->{DIST} && !defined $info->{DISTIGNORE}) {
			for my $f (values %{$info->{DIST}}) {
				$info->{FDEPENDS}{$f} = $f;
				bless $info->{FDEPENDS}, "AddDepends";
			}
		}
		# XXX don't grab dependencies for IGNOREd stuff
		next if defined $info->{IGNORE};

		for my $k (qw(LIB_DEPENDS BUILD_DEPENDS)) {
			if (defined $info->{$k}) {
				for my $d (values %{$info->{$k}}) {
					# filter these out like during build
					# simpler to figure out logs from 
					# depends stage that way.
					$d->{wantbuild} = 1;
					next if $d->pkgpath_and_flavors eq 
					    $v->pkgpath_and_flavors;
					$global->{$d} = $d;
				}
			}
		}
		for my $k (qw(LIB_DEPENDS RUN_DEPENDS)) {
			if (defined $info->{$k}) {
				for my $d (values %{$info->{$k}}) {
					$d->{wantbuild} = 1;
					$info->{RDEPENDS}{$d} = $d;
					bless $info->{RDEPENDS}, "AddDepends";
				}
			}
		}
		if (defined $info->{EXTRA}) {
			for my $d (values %{$info->{EXTRA}}) {
				$global3->{$d} = $d;
				$d->{wantinfo} = 1;
			}
	    	}
			
		for my $k (qw(LIB_DEPENDS BUILD_DEPENDS RUN_DEPENDS 
		    SUBPACKAGE FLAVOR EXTRA PERMIT_DISTFILES_FTP 
		    MULTI_PACKAGES PERMIT_DISTFILES_CDROM)) {
			delete $info->{$k};
		}
	}
	if (values %$global > 0) {
		for my $v (values %$h) {
			# remove stuff that depends on itself
			delete $global->{$v};
			$v->{info}{DEPENDS} = $global;
			$v->{info}{BDEPENDS} = $global2;
		}
	}
	if (values %$global3 > 0) {
		for my $v (values %$h) {
			$v->{info}{EXTRA} = $global3;
			$v->{info}{BEXTRA} = $global4;
		}
	}
}

sub build_path_list
{
	my ($v) = @_;
	my @l = ($v);
	my $stem = $v->pkgpath_and_flavors;
	my $w = DPB::PkgPath->new($stem);
	if ($w ne $v) {
		push(@l, $w);
	}
	if (defined $v->{info}) {
		for my $m (keys %{$v->{info}{BUILD_PACKAGES}}) {
			next if $m eq '-';
			my $w = DPB::PkgPath->new("$stem,$m");
			if ($w ne $v) {
				push(@l, $w);
			}
		}
	}
	return @l;
}

sub break
{

	my ($self, $why) = @_;
	if (defined $self->{broken}) {
		$self->{broken} .= " $why";
	} else {
		$self->{broken} = $why;
	}
}

1;
