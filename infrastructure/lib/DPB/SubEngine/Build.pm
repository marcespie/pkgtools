# ex:ts=8 sw=4:
# $OpenBSD: Build.pm,v 1.24 2019/05/12 14:09:11 espie Exp $
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

package DPB::SubEngine::Build;
our @ISA = qw(DPB::SubEngine::BuildBase);
sub new
{
	my ($class, $engine, $builder) = @_;
	my $o = $class->SUPER::new($engine, $builder);
	$o->{toinstall} = [];
	$o->{nfs} = {};
	return $o;
}


sub preempt_core
{
	my ($self, $core) = @_;

	if ($self->SUPER::preempt_core($core)) {
		return 1;
	}
	if ($self->start_install($core)) {
		return 1;
	}
	# note we don't actually remove stuff from the queue until needed, 
	# so mismatches holds a copy of stuff that's still there.
	$self->{mismatches} = [];
	$self->{tag_mismatches} = [];
	$self->{klogged} = {};
	return 0;
}

sub can_start_build
{
	my ($self, $v, $core) = @_;

	if ($self->check_for_memory_hogs($v, $core)) {
		push(@{$self->{mismatches}}, $v);
		return 0;
	}
	# if the tag mismatch, we keep it for much much later.
	# currently, we don't even try to recuperate, so this will
	# fail abysmally if there's no junking going on
	my $reason = $core->prop->taint_incompatible($v);
	if (defined $reason) {
		my $core2 = DPB::Core->get_compatible($v);
		if (defined $core2) {
			if ($self->lock_and_start_build($core2, $v)) {
				return 0;
			} else {
				$core2->mark_ready;
			}
		}
		if (!$self->{klogged}{$v->pkgpath}) {
			$self->log('K', $v, " ".$core->hostname." ".$reason);
			$self->{klogged}{$v->pkgpath} = 1;
		}
		push(@{$self->{tag_mismatches}}, $v);
		return 0;
	}
	# keep affinity mismatches for later
	if (defined $v->{affinity} && !$core->matches_affinity($v)) {
		my $s = " ".$core->hostname;
		$s .= " ".$v->{affinity};
		$self->log('A', $v, $s);
		# try to start them anyways, on the "right" core
		my $core2 = DPB::Core->get_affinity($v);
		if (defined $core2) {
			if ($self->lock_and_start_build($core2, $v)) {
				return 0;
			} else {
				$core2->mark_ready;
			}
		}
		push(@{$self->{mismatches}}, $v);
		return 0;
	}
	# if there's no external lock, we can build
	if ($self->lock_and_start_build($core, $v)) {
		return 1;
	}
}

# we cheat a bit to standardize built paths
sub can_really_start_build
{
	my ($self, $v, $core) = @_;
	for my $w (sort {$a->fullpkgpath cmp $b->fullpkgpath} 
	    $v->build_path_list) {
	    	next unless $self->{queue}->contains($w);
		if ($self->SUPER::can_really_start_build($w, $core)) {
			for my $k ($w->build_path_list) {
				$self->remove($k);
			}
			return 1;
		}
	}
	return 0;
}

sub check_for_memory_hogs
{
	my ($self, $v, $core) = @_;
	if ($v->{info}->has_property('memoryhog')) {
		for my $job ($core->same_host_jobs) {
			if ($job->{v}{info}->has_property('memoryhog')) {
				return 1;
			}
		}
	}
	return 0;
}

sub can_be_junked
{
	my ($self, $v, $core) = @_;
	my $tag = $v->{info}->has_property('tag');
	for my $job ($core->same_host_jobs) {
		if ($job->{nojunk}) {
			return 0;
		}
		if ($job->{v}{info}->has_property('tag') &&
		    $job->{v}{info}->has_property('tag') ne $tag) {
		    	return 0;
		}
	}
	my ($nojunk, $h) = 
	    $self->{engine}{locker}->find_dependencies($core->hostname);
	if ($nojunk) {
		return 0;
	}
	return 1;
}

sub recheck_mismatches
{
	my ($self, $core) = @_;

	# first let's try to force junking
	if (@{$self->{tag_mismatches}} > 0) {
		for my $v (@{$self->{tag_mismatches}}) {
			# XXX there's probably a race condition there
			# we check for junking (which is okay)
			# then we FORCE the re-tagging BEFORE junking
			# if anything starts up at the same time with nojunk
			# then junking won't happen (for instance)
			# to fix, it requires a "pseudo" junk first 
			# to untaint the host, THEN we can try building.
			next unless $self->can_be_junked($v, $core);
			$self->force_junk($core);
			return 1;
		}
	}
	# let's make sure we don't have something else first
	if (@{$self->{mismatches}} > 0) {
		if ($self->{engine}->check_buildable(1)) {
			return $self->use_core($core, 1);
		}
	}
	# second pass, affinity mismatches
	for my $v (@{$self->{mismatches}}) {
		if (defined $core->prop->taint_incompatible($v)) {
			next;
		}
		if ($self->lock_and_start_build($core, $v)) {
			$self->log('Y', $v, 
			    " ".$core->hostname." ".$v->{affinity});
			return 1;
		}
	}
	return 0;
}

sub will_install
{
	my ($self, $v) = @_;
	push(@{$self->{toinstall}}, $v);
}

sub start_install
{
	my ($self, $core) = @_;
	return 0 unless $core->is_local;
	if (my $v = pop @{$self->{toinstall}}) {
		$self->{builder}->install($v, $core);
		return 1;
	} else {
		return 0;
	}
}

sub non_empty
{
	my $self = shift;
	return  $self->SUPER::non_empty || @{$self->{toinstall}} > 0;
}

sub mark_as_done
{
	my ($self, $v) = @_;
	$self->{engine}{affinity}->unmark($v);
	delete $self->{engine}{tobuild}{$v};
	delete $v->{info}{DIST};
#	$self->{heuristics}->done($v);
	if (defined $self->{later}{$v}) {
		$self->log('V', $v);
		delete $self->{later}{$v};
	}
	if (!defined $self->{engine}{built}{$v}) {
		$self->{engine}{built}{$v}= $v;
		$self->log('B', $v);
	}
	$self->remove($v);
}

# special case: some of those paths can't be built
sub remove_stub
{
	my ($self, $v) = @_;
	if ($v->{info}->is_stub) {
		$self->{engine}{affinity}->unmark($v);
		delete $self->{engine}{tobuild}{$v};
		$self->remove($v);
		return 1;
	}
	return 0;
}

sub is_done_or_enqueue
{
	my ($self, $v) = @_;
	my $okay = 1;
	for my $w ($v->build_path_list) {
		next if $self->remove_stub($w);
		if ($self->{builder}->end_check($w)) {
			$self->mark_as_done($w);
		} else {
			$self->{nfs}{$v}{$w} = $w;
			$okay = 0;
		}
	}
	return $okay;
}

sub is_done
{
	my ($self, $v) = @_;
	if ($self->{builder}->check($v)) {
		for my $w ($v->build_path_list) {
			next if $v eq $w;
			next if $self->remove_stub($w);
			next unless $self->{builder}->check($w);
			$self->mark_as_done($w);
		}
	}
	return $self->is_done_quick($v);
}

sub is_done_quick
{
	my ($self, $v) = @_;
	if ($self->{builder}->check($v)) {
		$self->mark_as_done($v);
		return 1;
	} else {
		return 0;
	}
}

sub key_for_doing
{
	my ($self, $v) = @_;
	return $v->pkgpath;
}

sub already_done
{
	my ($self, $v) = @_;
	$self->{engine}{logger}->make_log_link($v);
}

sub start_build
{
	my ($self, $v, $core, $lock) = @_;
	$self->log('J', $v, " ".$core->hostname);
	$core->prop->taint($v);
	$self->{builder}->build($v, $core, $lock, 
	    sub {
	    	my $fail = shift;
	    	$self->end($core, $v, $fail);
	    });
}

sub start_wipe
{
	my ($self, $v, $core) = @_;
	$self->log('W', $v, " ".$core->hostname);
	$self->{builder}->wipe($v, $core,
	    sub {
	    	my $fail = shift;
	    	$self->end_build($v);
		$self->log('N', $v);
		$self->{engine}{locker}->unlock($v);
	    });
}

sub force_junk
{
	my ($self, $core) = @_;
	my $v = JunkPath->new;
	$self->log('J', $v, " ".$core->hostname);
	$self->{builder}->force_junk($v, $core,
	    sub {
		my $fail = shift;
		$self->log($fail ? 'E': 'B' , $v, " ".$core->hostname);
	    });
}

sub end_build
{
	my ($self, $v) = @_;
	$self->{engine}{affinity}->finished($v);
	$self->{engine}{sizer}->finished($v);
}

sub sorted
{
	my ($self, $core) = @_;
	return $self->{engine}{affinity}->sorted($self->{queue}, $core);
}

sub add
{
	my ($self, $v) = @_;
	$self->{engine}{affinity}->has_in_queue($v);
	$self->SUPER::add($v);
}

package JunkPath;
our @ISA = qw(DPB::PkgPath);
sub new
{
	my $class = shift;
	my $v = bless {}, $class;
	DPB::PortInfo->new($v);
	return $v;
}

sub fullpkgpath
{
	return "junk-proxy";
}

sub forcejunk
{
	return 1;
}

1;
