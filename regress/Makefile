# $OpenBSD: Makefile,v 1.73 2019/07/11 07:15:02 espie Exp $

REGRESS_TARGETS=pkgnames pkgpaths signatures depends-check longnames pkgcfl \
	collision-check1 collision-check2 collision-check3 \
	collision-check4 collision-check5 collision-check6 \
	collision-check7 \
	update-check1 partial-update-test conflict-update \
	merge-update split-update big-merge family-circus missing \
	lib-report1 lib-report2 lib-report3 loop1 \
	lib-report4 lib-report5 lib-report6 lib-report7 \
	qttest gstest exotest inter1 manual1 oldlib1 \
	usertest-1 usertest-2 usertest-3 cups-bug nettle-bug \
	tying-1 tying-2 tag-delete setsprint temp-error1 \
	temp-error2 temp-error2-as-root temp-error3 temp-error4

REGRESS_ROOT_TARGETS = temp-error2-as-root

# lots of tests that really require a vstat overhaul
REGRESS_EXPECTED_FAILURES = collision-check1 collision-check2 \
	collision-check5 collision-check6 collision-check7 \
	exotest tying-2

ADD_PKG=perl -I${.CURDIR} ${.CURDIR}/my add
DELETE_PKG=perl -I${.CURDIR} ${.CURDIR}/my delete
INFO_PKG=perl -I${.CURDIR} ${.CURDIR}/my info
CREATE_PKG=perl -I${.CURDIR} ${.CURDIR}/mycreate
LONG1=iamareallongfilenamethatcantberepresentedcorrectlyinatararchivebutwewantittohappenanywaysohmygodaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa42
LONG2=iamanotherreallygfilenamethatcantberepresentedcorrectlyinatararchivebutwewantittohappenanywaysohmygodaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa42
LONG3=iamanotherreallylonglinkthatcantberepresentedcorrectlyinatararchivebutwewantittohappenanywaysohmygodaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa42
LONG4=iamanotherreallylonghardlinkthatcantberepresentedcorrectlyinatararchivebutwewantittohappenanywaysohmygodaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa42

NUMBERS != jot 50
.for i in ${NUMBERS}
S$i ?= ${.OBJDIR}/src$i
SRC$i ?= ${S$i}/usr/local
D$i ?= ${.OBJDIR}/dest$i
DEST$i ?= ${D$i}/usr/local
.endfor

# current maxes (used): D41, SRC26, plist24, rep5
pkgnames:
	perl ${.CURDIR}/check-name

pkgcfl:
	perl ${.CURDIR}/check-cfl

setsprint:
	perl ${.CURDIR}/check-beautify

pkgpaths:
	perl ${.CURDIR}/check-path

signatures: 
	-rm -f signatures.out
	perl ${.CURDIR}/check-sig 2>signatures.out
	diff -u signatures.out ${.CURDIR}/signatures.ref

depends-check: rep0/a-0.tgz rep0/b-0.tgz rep1/a-1.tgz rep1/b-1.tgz
	@-rm -rf ${D1}
	@ROOT=${D1} ${ADD_PKG} rep0/a-0.tgz rep0/b-0.tgz
	@ROOT=${D1} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u a b
	@ROOT=${D1} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} -D downgrade -u a b

longnames: rep1/c-0.tgz
	@-rm -rf ${D2}
	@ROOT=${D2} ${ADD_PKG} rep1/c-0.tgz
	@test -f ${DEST2}/${LONG1}
	@test -f ${DEST2}/${LONG2}
	@cd ${DEST2} && test -h ${LONG3} && test `readlink ${LONG3}` = ${LONG2}
	@cd ${DEST2} && test `stat -f '%i' ${LONG1}` = `stat -f '%i' ${LONG4}`

collision-check1: rep1/d-0.tgz rep1/e-0.tgz
	@-rm -rf ${D3}
	@ROOT=${D3} ${ADD_PKG} rep1/d-0.tgz
	@ROOT=${D3} ${ADD_PKG} rep1/e-0.tgz

collision-check2: rep1/d-0.tgz rep1/e-0.tgz
	@-rm -rf ${D4}
	@ROOT=${D4} ${ADD_PKG} rep1/d-0.tgz
	@-rm -rf ${D4}/pkgdb/d-0
	@ROOT=${D4} ${ADD_PKG} -I rep1/e-0.tgz

collision-check3: rep1/d-0.tgz rep1/f-0.tgz
	@-rm -rf ${D5}
	@ROOT=${D5} ${ADD_PKG} rep1/d-0.tgz rep1/f-0.tgz
	@-rm -rf ${D5}/pkgdb/d-0
	@ROOT=${D5} ${ADD_PKG} -D repair rep1/d-0.tgz
	PKG_DBDIR=${D5}/pkgdb pkg_info -qR d

collision-check4: rep1/d-0.tgz rep1/e-0.tgz
	@-rm -rf ${D6}
	@ROOT=${D6} ${ADD_PKG} rep1/d-0.tgz
	@-rm -rf ${D6}/pkgdb/d-0
	@ROOT=${D6} ${ADD_PKG} -D repair rep1/e-0.tgz

collision-check5: rep1/d-0.tgz rep1/e-0.tgz
	@-rm -rf ${D21}
	@ROOT=${D21} ${ADD_PKG} -n rep1/d-0.tgz rep1/e-0.tgz

collision-check6: rep1/d-0.tgz rep1/e-0.tgz
	@-rm -rf ${D7}
	@ROOT=${D7} ${ADD_PKG} rep1/d-0.tgz
	@-rm -rf ${D7}/pkgdb/d-0
	@ROOT=${D7} ${ADD_PKG} -D removecollisions rep1/d-0.tgz

collision-check7: rep0/cola-0.tgz rep1/cola-1.tgz rep1/colb-0.tgz
	@-rm -rf ${D32}
	@ROOT=${D32} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} cola-0
	@ROOT=${D32} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -r cola-1

update-check1: rep0/g-0.tgz rep1/g-0.tgz rep0/ga-0.tgz rep1/ga-0.tgz \
	rep0/gb-0.tgz rep1/gb-0p0.tgz rep0/gc-0.tgz rep1/gc-0.tgz \
	rep0/gd-0.tgz rep1/gd-1.tgz rep0/ge-0.tgz rep1/ge-1.tgz \
	rep0/gf-1.tgz rep1/gf-0.tgz rep0/gg-0.tgz rep1/gg-0.tgz
	@-rm -rf ${D8}
	@ROOT=${D8} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} g ga gb gc gd ge gf gg
	@-ROOT=${D8} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -Iu
	@PKG_DBDIR=${D8}/pkgdb pkg_info |diff - ${.CURDIR}/list7.out
	@ROOT=${D8} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u -Dupdate_gd
	@PKG_DBDIR=${D8}/pkgdb pkg_info |diff - ${.CURDIR}/list8.out

list-check: rep1/a-1.tgz rep1/b-1.tgz rep1/c-0.tgz rep1/d-0.tgz \
	rep1/e-0.tgz rep1/f-0.tgz rep1/g-0.tgz
	@-rm -rf ${D9}
	@ROOT=${D9} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -l ${.CURDIR}/list
	@PKG_DBDIR=${D9}/pkgdb pkg_info -q|diff - ${.CURDIR}/list.out

partial-update-test: rep0/h-0.tgz rep0/i-0.tgz rep0/j-0.tgz \
	rep1/h-1.tgz rep1/i-1.tgz rep1/j-1.tgz
	@-rm -rf ${D10}
	@ROOT=${D10} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} h j
	@ROOT=${D10} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u h
	@PKG_DBDIR=${D10}/pkgdb pkg_info -q|diff - ${.CURDIR}/list2.out

conflict-update: rep0/k-0.tgz rep0/l-0.tgz rep1/k-1.tgz rep1/l-1.tgz
	@-rm -rf ${D11}
	@ROOT=${D11} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} k l
	@ROOT=${D11} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u k
	@PKG_DBDIR=${D11}/pkgdb pkg_info -q|diff - ${.CURDIR}/list3.out

merge-update: rep0/m-0.tgz rep0/n-0.tgz rep1/m-1.tgz rep1/n-1.tgz
	@-rm -rf ${D12}
	@ROOT=${D12} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} m n
	@ROOT=${D12} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u n
	@PKG_DBDIR=${D12}/pkgdb pkg_info -q|diff - ${.CURDIR}/list4.out

split-update: rep0/o-0.tgz rep1/o-1.tgz rep1/p-0.tgz
	@-rm -rf ${D13}
	@ROOT=${D13} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} o
	@ROOT=${D13} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u o
	@PKG_DBDIR=${D13}/pkgdb pkg_info -q |diff - ${.CURDIR}/list5.out

big-merge: rep0/q1-0.tgz rep0/q2-0.tgz rep0/q3-0.tgz rep0/q4-0.tgz \
	rep0/q5-0.tgz rep0/q6-0.tgz rep1/q5-1.tgz rep1/q6-1.tgz \
	rep1/q1-1.tgz rep1/q2-1.tgz rep1/q3-1.tgz rep1/q4-1.tgz
	@-rm -rf ${D14}
	@ROOT=${D14} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} q1 q2 q3 q4 q5 q6
	@ROOT=${D14} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -x -D update -u 2>&1 |fgrep XXX|fgrep -v @|diff - ${.CURDIR}/list6.out

family-circus: rep0/glib-0.tgz rep0/fam-0.tgz rep1/fam-1.tgz rep1/glib-1.tgz rep1/gamin-0.tgz
	@-rm -rf ${D15}
	@ROOT=${D15} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} glib
	@ROOT=${D15} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u glib

missing: rep1/missa-0.tgz rep1/missb-0.tgz rep1/missc-0.tgz rep1/missd-0.tgz rep1/missf-0.tgz
	@-rm -rf ${D16}
	@ROOT=${D16} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} missc
	@-ROOT=${D15} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} missa missb missf

lib-report1: rep0/o1-0.tgz rep1/o1-1.tgz rep1/p1-0.tgz
	@-rm -rf ${D17}
	@ROOT=${D17} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} o1
	-@ROOT=${D17} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u o1

lib-report2: rep0/o2-0.tgz rep1/o2-1.tgz rep1/p2-0.tgz
	@-rm -rf ${D18}
	@ROOT=${D18} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} o2
	-@ROOT=${D18} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u o2

lib-report3: rep0/o3-0.tgz
	@-rm -rf ${D19}
	-@ROOT=${D19} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} o3

lib-report4: rep0/o4-0.tgz rep0/p4-0.tgz
	@-rm -rf ${D22}
	-@ROOT=${D22} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} o4

lib-report5: rep0/o5-0.tgz rep0/p4-0.tgz
	@-rm -rf ${D23}
	-@ROOT=${D23} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} o5

lib-report6: rep0/o6-0.tgz rep0/p4-0.tgz rep0/oo6-0.tgz
	@-rm -rf ${D24}
	-@ROOT=${D24} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} o6 oo6

lib-report7: rep0/o7-0.tgz rep0/p4-0.tgz
	@-rm -rf ${D25}
	-@ROOT=${D25} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} o7

oldlib1: rep0/ol-0.tgz rep1/ol-1.tgz
	@-rm -rf ${D33}
	-@ROOT=${D33} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} ol
	-@ROOT=${D33} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u ol
	@ROOT=${D33} ${INFO_PKG} -f .libs-ol-0|grep '^lib/subdir/$$'

loop1: rep0/ocaml-3.11.1.tgz rep0/tcl-8.5.7.tgz rep0/tk-8.5.7.tgz
	@-rm -rf ${D20}
	-@ROOT=${D20} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} -z ocaml-3.11.1p0 tcl-8.5.8 tk-8.5.8

qttest: rep0/qt-0.tgz rep1/qt-1.tgz
	@-rm -rf ${D26}
	@ROOT=${D26} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} qt
	@ROOT=${D26} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u qt

gstest: rep0/gs-0.tgz rep0/gs-0-no_x11.tgz rep0/purple-0.tgz
	@-rm -rf ${D27}
	-@ROOT=${D27} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} purple-0
	@if ROOT=${D27} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} -rI gs-0-no_x11; then exit 1; fi

exotest: rep0/exo-0.tgz rep1/exo-1.tgz
	@-rm -rf ${D28}
	@ROOT=${D28} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} exo
	@ROOT=${D28} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -Iu exo

thunarvfstest: rep0/thunar-0.tgz rep0/q-0.tgz rep1/thunar-vfs-1.tgz rep1/q-1.tgz rep1/thunar-1.tgz
	@-rm -rf ${D29}
	@ROOT=${D29} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} q
	@ROOT=${D29} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u q

# test for manual install
manual1: rep0/ma-0.tgz rep0/mb-0.tgz rep0/mc-0.tgz rep0/md-0.tgz \
	rep1/ma-1.tgz rep1/mb-1.tgz rep1/me-1.tgz rep1/md-1.tgz
	@-rm -rf ${D30}
	@ROOT=${D30} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} md mb
	@ROOT=${D30} ${INFO_PKG} -mq|diff -u - ${.CURDIR}/list9.out
	@-ROOT=${D30} PKG_PATH=${.OBJDIR}/rep1 ${ADD_PKG} -u
	@ROOT=${D30} ${INFO_PKG} -mq|diff -u - ${.CURDIR}/list10.out
	@ROOT=${D30} ${DELETE_PKG} -a
	@ROOT=${D30} ${INFO_PKG} -q|diff -u - ${.CURDIR}/list11.out

inter1: rep0/inta-0.tgz rep0/intb-0.tgz
	-rm -rf ${D31}
	@ROOT=${D31} PKG_PATH=${.OBJDIR}/rep0 ${ADD_PKG} inta intb
	@ROOT=${D31} ${DELETE_PKG} inta intb

plist1:
	@echo "@owner "`id -un` >$@
	@echo "@group "`id -gn` >>$@
	@echo ${LONG1} >>$@
	@echo ${LONG2} >>$@
	@echo ${LONG3} >>$@
	@echo ${LONG4} >>$@

plist2:
	@echo "@owner "`id -un` >$@
	@echo "@group "`id -gn` >>$@
	@echo a >>$@
	@echo b >>$@
	@echo c >>$@
	@echo f >>$@
	@echo g >>$@

plist3:
	@echo "@owner "`id -un` >$@
	@echo "@group "`id -gn` >>$@
	@echo a >>$@
	@echo c >>$@
	@echo d >>$@
	@echo f >>$@
	@echo g >>$@

plist4:
	@echo "@option always-update" >$@

plist5:
	@echo "@ask-update gd-<1 Make sure yadada is backed up" >$@

plist6:
	@echo "@conflict l-<1" >$@

plist7:
	@echo "@conflict m-<1" >$@
	@echo "@pkgpath t/m" >>$@

plist8:
	@echo "@conflict o-<1" >$@
	@echo "@pkgpath t/o" >>$@
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo '@lib lib/libcoincoin.so.$${LIBcoincoin_VERSION}' >>$@

plist9:
	@echo "@conflict gamin-*" >$@

plist10:
	@echo "@conflict fam-*" >$@
	@echo "@pkgpath t/fam" >>$@

plist11:
	@echo "@conflict missc-*" >$@

plist12:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo '@lib lib/liba.so.$${LIBa_VERSION}' >>$@

plist13:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo phonon/ >>$@
	@echo phonon/a >>$@

plist14:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo phonon >>$@

plist15:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo foo/ >>$@
	@echo foo/a >>$@
	@echo bar >>$@

plist16:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo foo/ >>$@
	@echo foo/a >>$@
	@echo bar/ >>$@
	@echo bar/a >>$@

plist17:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo '@lib lib/libthunar-vfs.so.$${LIBthunar-vfs_VERSION}' >>$@

plist18:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo "@conflict thunar-<1" >>$@
	@echo '@lib lib/libthunar-vfs.so.$${LIBthunar-vfs_VERSION}' >>$@

plist19:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo a >>$@

plist20:
	@echo "@owner "`id -un` >>$@
	@echo "@group "`id -gn` >>$@
	@echo "@conflict cola-<1" >>$@
	@echo a >>$@

plist21:
	@echo "@owner "`id -un` >$@
	@echo "@group "`id -gn` >>$@
	@echo '@lib lib/subdir/libol.so.$${LIBol_VERSION}' >>$@

rep0/a-0.tgz:
	@${CREATE_PKG} -P't/b:b-*:b-0' -f ${.CURDIR}/empty $@

rep1/a-1.tgz rep0/b-0.tgz rep0/i-0.tgz rep0/j-0.tgz rep1/j-1.tgz \
rep1/i-1.tgz rep0/k-0.tgz rep0/l-0.tgz rep1/l-1.tgz rep0/m-0.tgz \
rep0/n-0.tgz rep1/m-1.tgz rep0/o-0.tgz rep0/fam-0.tgz \
rep0/o1-0.tgz rep0/o2-0.tgz rep0/ga-0.tgz \
rep0/gb-0.tgz rep1/gb-0p0.tgz rep0/gd-0.tgz rep0/ge-0.tgz \
rep0/gf-1.tgz rep1/gf-0.tgz \
rep1/missc-0.tgz rep0/q5-0.tgz rep1/q5-1.tgz \
rep0/ma-0.tgz rep1/ma-1.tgz rep0/mc-0.tgz rep1/me-1.tgz \
rep0/tcl-8.5.7.tgz:
	@${CREATE_PKG} -f ${.CURDIR}/empty $@

rep0/md-0.tgz:
	@${CREATE_PKG} -P't/ma:ma-*:ma-0' -P't/mb:mb-*:mb-0' -P't/mc:mc-*:mc-0' -f ${.CURDIR}/empty $@
rep1/md-1.tgz:
	@${CREATE_PKG} -P't/ma:ma-*:ma-1' -P't/mb:mb-*:mb-1' -P't/me:me-*:me-1' -f ${.CURDIR}/empty $@
rep0/mb-0.tgz:
	@${CREATE_PKG} -P't/ma:ma-*:ma-0' -f ${.CURDIR}/empty $@
rep1/mb-1.tgz:
	@${CREATE_PKG} -P't/ma:ma-*:ma-1' -f ${.CURDIR}/empty $@

rep0/inta-0.tgz:
	@${CREATE_PKG} -P't/intb:intb-*:intb-0' -f ${.CURDIR}/empty $@
rep0/intb-0.tgz:
	@${CREATE_PKG} -P't/inta:inta-*:inta-0' -f ${.CURDIR}/empty $@
 
rep1/o-1.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -P't/p:p-*:p-0' -W'coincoin.0.0' -f ${.CURDIR}/empty $@

rep1/o1-1.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -P't/p1:p1-*:p1-0' -W'coincoin.0' -f ${.CURDIR}/empty $@

rep1/o2-1.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -P't/p2:p2-*:p2-0' -W'coincoin.0' -f ${.CURDIR}/empty $@

rep0/o3-0.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -W'unlikelylibraryname.0.0' -f ${.CURDIR}/empty $@

rep1/p-0.tgz rep1/p1-0.tgz: plist8
	@mkdir -p ${SRC13}/lib
	@touch ${SRC13}/lib/libcoincoin.so.0.0
	@${CREATE_PKG} -B src13 -DLIBcoincoin_VERSION=0.0 -f plist8 $@

rep1/p2-0.tgz: plist8
	@mkdir -p ${SRC14}/lib
	@touch ${SRC14}/lib/libcoincoin.so.0
	@${CREATE_PKG} -DREGRESSION_TESTING -B src14 -DLIBcoincoin_VERSION=0 -f plist8 $@

rep0/p4-0.tgz: plist12
	@mkdir -p ${SRC15}/lib
	@touch ${SRC15}/lib/liba.so.0.0
	@${CREATE_PKG} -B src15 -DLIBa_VERSION=0.0 -f plist12 $@

rep0/o4-0.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -W'a.1.0' -P't/p4:p4-*:p4-0' -f ${.CURDIR}/empty $@

rep0/o5-0.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -W'a.0.2' -P't/p4:p4-*:p4-0' -f ${.CURDIR}/empty $@

rep0/o6-0.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -W'a.0.0' -P't/p4:p4-*:p4-0' -f ${.CURDIR}/empty $@

rep0/oo6-0.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -W'a.0.0' -f ${.CURDIR}/empty $@

rep0/o7-0.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -W'dir/a.0.0' -P't/p4:p4-*:p4-0' -f ${.CURDIR}/empty $@

rep1/b-1.tgz:
	@${CREATE_PKG} -P't/a:a-*:a-1' -f ${.CURDIR}/empty $@

rep0/qt-0.tgz: plist13
	@mkdir -p ${SRC17}/phonon
	touch ${SRC17}/phonon/a
	@${CREATE_PKG} -B src17 -f plist13 $@

rep1/qt-1.tgz: plist14
	@mkdir -p ${SRC16}
	touch ${SRC16}/phonon
	@${CREATE_PKG} -B src16 -f plist14 $@

rep0/exo-0.tgz: plist15
	@mkdir -p ${SRC18}/foo
	touch ${SRC18}/foo/a
	cd ${SRC18} && ln -s foo bar
	@${CREATE_PKG} -B src18 -f plist15 $@

rep1/exo-1.tgz: plist16
	@mkdir -p ${SRC19}/{foo,bar}
	touch ${SRC19}/{bar,foo}/a
	@${CREATE_PKG} -B src19 -f plist16 $@

rep0/thunar-0.tgz: plist17
	@mkdir -p ${SRC20}/lib
	@touch ${SRC20}/lib/libthunar-vfs.so.0.0
	@${CREATE_PKG} -B src20 -DLIBthunar-vfs_VERSION=0.0 -f plist17 $@

rep1/thunar-vfs-1.tgz: plist18
	@mkdir -p ${SRC20}/lib
	@touch ${SRC20}/lib/libthunar-vfs.so.0.0
	@${CREATE_PKG} -B src20 -DLIBthunar-vfs_VERSION=0.0 -f plist18 $@

rep1/thunar-1.tgz:
	@${CREATE_PKG} -f ${.CURDIR}/empty $@


rep0/q-0.tgz:
	@${CREATE_PKG} -P't/thunar:thunar-*:thunar-0' -f ${.CURDIR}/empty $@

rep1/q-1.tgz:
	@${CREATE_PKG} -P't/thunar-vfs:thunar-vfs-*:thunar-vfs-1' -f ${.CURDIR}/empty $@

rep0/gs-0.tgz:
	@${CREATE_PKG} -f ${.CURDIR}/empty $@
rep0/gs-0-no_x11.tgz:
	@${CREATE_PKG} -f ${.CURDIR}/empty $@

rep0/purple-0.tgz:
	@${CREATE_PKG} -P't/gs:gs-*-!no_x11:gs-0' -f ${.CURDIR}/empty $@

rep1/c-0.tgz: plist1
	@mkdir -p ${SRC1}
	@touch ${SRC1}/${LONG1}
	@touch ${SRC1}/${LONG2}
	@cd ${SRC1} && ln -sf ${LONG2} ${LONG3}
	@cd ${SRC1} && ln -f ${LONG1} ${LONG4}
	@${CREATE_PKG} -B src1 -f plist1 $@

rep1/k-1.tgz: plist6
	@${CREATE_PKG} -f plist6 $@

rep1/n-1.tgz: plist7
	@${CREATE_PKG} -f plist7 $@

rep1/d-0.tgz: plist2
	@mkdir -p ${SRC2}
	@touch ${SRC2}/a ${SRC2}/b ${SRC2}/c
	@echo "coucou" >${SRC2}/f
	@echo "not coucou" >${SRC2}/g
	@${CREATE_PKG} -B src2 -f plist2 $@

rep1/e-0.tgz: plist3
	@mkdir -p ${SRC3}
	@touch ${SRC3}/a ${SRC3}/c ${SRC3}/d
	@echo "coucou" >${SRC3}/f
	@echo "coucou" >${SRC3}/g
	@${CREATE_PKG} -B src3 -f plist3 $@

rep1/f-0.tgz:
	@${CREATE_PKG} -P't/d:d-*:d-0' -f ${.CURDIR}/empty $@

rep0/g-0.tgz: plist4
	@${CREATE_PKG} -f plist4 $@

rep1/g-0.tgz: plist4
	@PACKAGE_COMMENT=updated ${CREATE_PKG} -f plist4 $@

rep0/gg-0.tgz: plist4 
	@${CREATE_PKG} -P't/g:g-*:g-1' -f plist4 $@

rep1/gg-0.tgz: plist4 
	@PACKAGE_COMMENT=updated ${CREATE_PKG} -P't/g:g-*:g-0' -f plist4 $@

rep1/gd-1.tgz rep1/ge-1.tgz: plist5
	@${CREATE_PKG} -f plist5 $@

rep1/ga-0.tgz:
	@PACKAGE_COMMENT=updated ${CREATE_PKG} -f ${.CURDIR}/empty $@

rep0/gc-0.tgz:
	@${CREATE_PKG} -P't/ga:gb-*:gb-0' -f ${.CURDIR}/empty $@

rep1/gc-0.tgz:
	@PACKAGE_COMMENT=updated ${CREATE_PKG} -P't/ga:gb-*:gb-0p0' -f ${.CURDIR}/empty $@

rep0/h-0.tgz:
	@${CREATE_PKG} -P't/i:i-*:i-0' -f ${.CURDIR}/empty $@

rep1/h-1.tgz:
	@${CREATE_PKG} -P't/j:j->=1:j-1' -f ${.CURDIR}/empty $@

rep0/cola-0.tgz: plist19
	@mkdir -p ${SRC22}
	@touch ${SRC22}/a
	@${CREATE_PKG} -B src22 -f plist19 $@

rep1/cola-1.tgz: plist19
	@mkdir -p ${SRC22}
	@touch ${SRC22}/a
	@${CREATE_PKG} -B src22 -P't/colb:colb-*:colb-0' -f plist19 $@

rep1/colb-0.tgz: plist20
	@mkdir -p ${SRC22}
	@touch ${SRC22}/a
	@${CREATE_PKG} -B src22 -f plist20 $@

depend_q1=-P't/q5:q5-*:q5-0'
depend_q2=${depend_q1} -P't/q1:q1-*:q1-0'
depend_q3=${depend_q1} -P't/q2:q2-*:q2-0'
depend_q4=${depend_q1} -P't/q3:q3-*:q3-0'

.for n in q1 q2 q3 q4
plist-rep0-$n:
	@echo "@unexec echo 1>&2 'XXXrep0 $n'" >$@

rep0/$n-0.tgz: plist-rep0-$n
	@${CREATE_PKG} ${depend_$n} -f plist-rep0-$n $@
rep1/$n-1.tgz: plist-rep1-$n
	@${CREATE_PKG} ${depend_$n} -f plist-rep1-$n $@

plist-rep1-$n:
	@echo "@conflict q1-0" >$@
	@echo "@conflict q2-0" >>$@
	@echo "@conflict q3-0" >>$@
	@echo "@conflict q4-0" >>$@
	@echo "@exec echo 1>&2 'XXXrep1 $n'" >>$@

.endfor
	
rep0/q6-0.tgz:
	@${CREATE_PKG} -P't/q3:q3-*:q3-0' -f ${.CURDIR}/empty $@

rep1/q6-1.tgz:
	@${CREATE_PKG} -P't/q3:q3-*:q3-0' -f ${.CURDIR}/empty $@

rep0/glib-0.tgz:
	@${CREATE_PKG} -P't/fam:fam-*:fam-0' -f ${.CURDIR}/empty $@

rep1/glib-1.tgz:
	@${CREATE_PKG} -P't/gamin:gamin-*:gamin-0' -f ${.CURDIR}/empty $@

rep1/fam-1.tgz: plist9
	@${CREATE_PKG} -f plist9 $@

rep1/gamin-0.tgz: plist10
	@${CREATE_PKG} -f plist10 $@

rep1/missa-0.tgz:
	@${CREATE_PKG} -P't/misse:misse-*:misse-0' -f ${.CURDIR}/empty $@

rep1/missb-0.tgz:
	@${CREATE_PKG} -P't/missd:missd-*:missd-0' -f ${.CURDIR}/empty $@

rep1/missd-0.tgz: plist11
	@${CREATE_PKG} -f plist11 $@

rep1/missf-0.tgz:
	@${CREATE_PKG} -P't/misse:misse-*:misse-0' -f ${.CURDIR}/empty $@

rep0/ocaml-3.11.1.tgz:
	@${CREATE_PKG} -P'test/tcl:tcl->=8.5,<8.6:tcl-8.5.7' \
		-P'test/tk:tk->=8.5,<8.6:tk-8.5.7' -f ${.CURDIR}/empty $@

rep0/tk-8.5.7.tgz:
	@${CREATE_PKG} -P'test/tcl:tcl->=8.5.7,<8.5.8:tcl-8.5.7' \
		-f ${.CURDIR}/empty $@

rep0/ol-0.tgz: plist21
	@mkdir -p ${SRC23}/lib/subdir
	@touch ${SRC23}/lib/subdir/libol.so.0.0
	@${CREATE_PKG} -B src23 -DLIBol_VERSION=0.0 -f plist21 $@

rep1/ol-1.tgz: plist21
	@mkdir -p ${SRC23}/lib/subdir
	@touch ${SRC23}/lib/subdir/libol.so.1.0
	@${CREATE_PKG} -B src23 -DLIBol_VERSION=1.0 -f plist21 $@

.for o in cups-2.2.7p1 cups-filters-1.20.3 cups-libs-2.2.7 ghostscript-9.07p7
CUPS_FILES += rep2/$o.tgz
rep2/$o.tgz: ${.CURDIR}/oldcups/$o/+CONTENTS
	mkdir -p rep2
	cd rep2 && pkg_create -DREGRESSION_TESTING -Dstub -f ${.CURDIR}/oldcups/$o/+CONTENTS
.endfor

.for n in cups-2.2.8 cups-filters-1.20.3 cups-libs-2.2.8 ghostscript-9.07p7
CUPS_FILES += rep3/$n.tgz
rep3/$n.tgz: ${.CURDIR}/newcups/$n/+CONTENTS
	mkdir -p rep3
	cd rep3 && pkg_create -DREGRESSION_TESTING -Dstub -f ${.CURDIR}/newcups/$n/+CONTENTS
.endfor

cups-bug: ${CUPS_FILES}
	rm -rf ${D36}
	mkdir -p ${D36}/vardbpkg ${D36}/usr/local
	ROOT=${D36} PKG_PATH=${.OBJDIR}/rep2 INJECT=inject-order ${ADD_PKG} -Dstub cups
	ROOT=${D36} PKG_PATH=${.OBJDIR}/rep3 INJECT=inject-order ${ADD_PKG} -Dstub -u

usertest-1:
	@if ${CREATE_PKG} -u ${.CURDIR}/baduser1 \
	    -f ${.CURDIR}/empty truc-0.tgz; then \
	    	exit 1; \
	else \
		exit 0; \
	fi

usertest-2:
	@if ${CREATE_PKG} -u ${.CURDIR}/baduser2 \
	    -f ${.CURDIR}/empty truc-0.tgz; then \
	    	exit 1; \
	else \
		exit 0; \
	fi

usertest-3:
	@if ${CREATE_PKG} -u ${.CURDIR}/baduser3 \
	    -f ${.CURDIR}/empty truc-0.tgz; then \
	    	exit 1; \
	else \
		exit 0; \
	fi
keys:
	mkdir signify
	signify -G -n -s signify/test-pkg.sec -p signify/test-pkg.pub

plist22:
	@echo "@owner "`id -un` >$@
	@echo "@group "`id -gn` >>$@
	@echo '@lib lib/libnettle.so.$${LIBnettle_VERSION}' >>$@

rep4/libnettle-0.tgz: plist22
	@mkdir -p ${SRC24}/lib
	@touch ${SRC24}/lib/libnettle.so.0.0
	@${CREATE_PKG} -B src24 -DLIBnettle_VERSION=0.0 -f plist22 $@

rep4/cups-libs-0.tgz:
	@${CREATE_PKG} -P't/gnutls:gnutls-*:gnutls-0' -f ${.CURDIR}/empty $@

rep5/cups-libs-0.tgz:
	@${CREATE_PKG} -P't/gnutls:gnutls-*:gnutls-0' -f ${.CURDIR}/empty $@

rep4/gnutls-0.tgz:
	@${CREATE_PKG} -P't/libnettle:libnettle-*:libnettle-0' -f ${.CURDIR}/empty $@

rep5/gnutls-0.tgz:
	@${CREATE_PKG} -P't/libnettle:libnettle-*:libnettle-1' -f ${.CURDIR}/empty $@

rep4/gtk+3-cups-0.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -W nettle.0.0 -P't/cups-libs:cups-libs-*:cups-libs-0' -f ${.CURDIR}/empty $@

rep5/gtk+3-cups-0.tgz:
	@${CREATE_PKG} -DREGRESSION_TESTING -W nettle.1.0 -P't/cups-libs:cups-libs-*:cups-libs-0' -f ${.CURDIR}/empty $@

rep5/libnettle-1.tgz: plist22
	@mkdir -p ${SRC24}/lib
	@touch ${SRC24}/lib/libnettle.so.1.0
	@${CREATE_PKG} -B src24 -DLIBnettle_VERSION=1.0 -f plist22 $@

nettle-bug: rep4/cups-libs-0.tgz rep4/gtk+3-cups-0.tgz rep4/gnutls-0.tgz \
	rep4/libnettle-0.tgz rep5/cups-libs-0.tgz rep5/gtk+3-cups-0.tgz \
	rep5/gnutls-0.tgz rep5/libnettle-1.tgz
	@-rm -rf ${D37}
	@ROOT=${D37} ${ADD_PKG} rep4/gtk+3-cups
	@ROOT=${D37} PKG_PATH=${.OBJDIR}/rep5 ${ADD_PKG} -u gtk+3-cups

plist23:
	@echo "@owner "`id -un` >$@
	@echo "@group "`id -gn` >>$@
	@echo "share/" >>$@
	@echo "share/bg/" >>$@
	@echo "share/bg/portrait" >>$@
	@echo "share/bg/pictures/" >>$@
	@echo "share/bg/pictures/a/" >>$@
	@echo "share/bg/pictures/a/zoinx" >>$@

plist24:
	@echo "@owner "`id -un` >$@
	@echo "@group "`id -gn` >>$@
	@echo "share/" >>$@
	@echo "share/bg/" >>$@
	@echo "share/bg/portrait/" >>$@
	@echo "share/bg/portrait/a/" >>$@
	@echo "share/bg/portrait/a/zoinx" >>$@

rep0/bg-0.tgz: plist23
	@mkdir -p ${SRC25}/share/bg ${SRC25}/share/bg/pictures/a
	@echo "a file" >${SRC25}/share/bg/portrait
	@echo "zoinx" >${SRC25}/share/bg/pictures/a/zoinx
	@${CREATE_PKG} -B src25 -f plist23 $@

rep0/bg-1.tgz: plist24
	@mkdir -p ${SRC26}/share/bg/portrait/a
	@echo "zoinx" >${SRC26}/share/bg/portrait/a/zoinx
	@${CREATE_PKG} -B src26 -f plist24 $@

# these exemplify issues with directory moving around
tying-1: rep0/bg-0.tgz rep0/bg-1.tgz
	@-rm -rf ${D38}
	@ROOT=${D38} ${ADD_PKG} rep0/bg-0.tgz
	@ROOT=${D38} ${ADD_PKG} -r rep0/bg-1.tgz

tying-2: rep0/bg-0.tgz rep0/bg-1.tgz
	@-rm -rf ${D39}
	@ROOT=${D39} ${ADD_PKG} rep0/bg-1.tgz
	@ROOT=${D39} ${ADD_PKG} -r rep0/bg-0.tgz

# this comes from solve_tags
# pkg_delete finds new dependencies, and so the solver needs to be made
# "safe" when it can't find them
tag-delete: rep1/d-0.tgz
	@-rm -rf ${D40}
	@ROOT=${D40} ${ADD_PKG} rep1/d-0.tgz
	# needs a tag to trigger the bug
	echo "@tag zoinx" >> ${D40}/pkgdb/d-0/+CONTENTS
	# and an "unsolved" dependency for DeleteSet to look harder
	echo "@depend graphics/zoinx:zoinx-*:zoinx-2" >> ${D40}/pkgdb/d-0/+CONTENTS
	@ROOT=${D40} ${DELETE_PKG} d

SED_PIPE = sed -n -e s/`whoami`/USER/ -e 1p -e '$$p'
SED_PIPE2 = { u=`whoami`; case $$u in root) u=_pkgfetch;; esac; sed -n -e s/$$u/USER/ -e 1p -e '$$p'; }


XXXD=${D40}
XXXBASE=temp2

temp-error1: rep0/a-0.tgz rep0/b-0.tgz temp1.ref
	@-rm -rf ${D40}
	@{ INJECT=inject-temp1 ROOT=${D40} SILENT=1 ${ADD_PKG} rep0/a-0.tgz 1>/dev/null|| echo $$? ; } 2>&1|${SED_PIPE} >temp1.out
	@diff -u temp1.out ${.CURDIR}/temp1.ref

temp-error2: 
	@-rm -rf ${XXXD}
	@{ INJECT=inject-temp2 ROOT=${XXXD} SILENT=1 PKG_PATH=https://www.google.com/ ${ADD_PKG} rep0/a-0.tgz 1>/dev/null|| echo $$? ; } 2>&1|${SED_PIPE2} >${XXXBASE}.out
	@diff -u ${XXXBASE}.out ${.CURDIR}/temp2.ref

temp-error2-as-root: 
	@# XXX thx tedu for not allowing env thru
	@${SUDO} make -C ${.CURDIR} temp-error2 XXXBASE=temp2bis XXXD=${D41}

temp-error3: rep1/d-0.tgz temp3.ref
	@-rm -rf ${D42}
	@{ INJECT=inject-temp3 ROOT=${D42} SILENT=1 ${ADD_PKG} rep1/d-0.tgz 1>/dev/null|| echo $$?; } 2>&1|${SED_PIPE} >temp3.out
	@diff -u temp3.out ${.CURDIR}/temp3.ref

temp-error4: rep0/qt-0.tgz rep1/qt-1.tgz
	@-rm -rf ${D43}
	@ROOT=${D43} SILENT=1 ${ADD_PKG} rep0/qt-0.tgz
	@rm -f ${D43}/usr/local/phonon/a
	@echo zoinx >${D43}/usr/local/phonon/a
	@{ INJECT=inject-temp4 PKG_PATH=${.OBJDIR}/rep1 SILENT=1 ROOT=${D43} ${ADD_PKG} -Dchecksum -u qt || echo $$?; } 2>&1|${SED_PIPE} >temp4.out

.PHONY: ${REGRESS_TARGETS}

clean:
	-rm -rf rep* dest* plist* src* signatures.out *.ref *.out
	-${SUDO} rm -rf rep* dest* plist* src* signatures.out *.ref *.out

.include <bsd.regress.mk>
