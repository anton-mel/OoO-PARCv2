#=========================================================================
# Toplevel Makefile for the Modular C++ Build System
#=========================================================================
# Please read the documenation in 'mcppbs-doc.txt' for more details on
# how the Modular C++ Build System works. For most projects, a developer
# will not need to make any changes to this makefile. The key targets
# are as follows:
#
#  - default   : build all libraries and programs
#  - check     : build and run all unit tests
#  - install   : install headers, project library, and some programs
#  - clean     : remove all generated content (except autoconf files)
#  - dist      : make a source tarball
#  - distcheck : make a source tarball, untar it, check it, clean it
#  - distclean : remove everything
#

#-------------------------------------------------------------------------
# Basic setup
#-------------------------------------------------------------------------

# Remove all default implicit rules since they can cause subtle bugs
# and they just make things run slower
.SUFFIXES:
% : %,v
% : RCS/%,v
% : RCS/%
% : s.%
% : SCCS/s.%

# Default is to build the prereqs of the all target (defined at bottom)
default : all
.PHONY : default

project_name := ubmark
src_dir      := ..
scripts_dir  := $(src_dir)/scripts

# If the version information is not in the configure script, then we
# assume that we are in a working directory. We use the vcs-version.sh
# script in the scripts directory to generate an appropriate version
# string. Currently the way things are setup we have to run this script
# everytime we run make so the script needs to be as fast as possible.

ifeq (?,?)
  project_ver:=$(shell $(scripts_dir)/vcs-version.sh $(src_dir))
else
  project_ver:=?
endif

#-------------------------------------------------------------------------
# Installation directory setup
#-------------------------------------------------------------------------

prefix       := /usr/local
enable_stow  := no

ifeq ($(enable_stow),yes)
  stow_pkg_dir := $(prefix)/pkgs
  DESTDIR ?= $(stow_pkg_dir)/$(project_name)-$(project_ver)
else
  DESTDIR ?= $(prefix)
endif

install_hdrs_dir := $(DESTDIR)/include
install_libs_dir := $(DESTDIR)/lib
install_pkcs_dir := $(DESTDIR)/share/pkgconfig
install_exes_dir := $(DESTDIR)/bin

#-------------------------------------------------------------------------
# Programs and flags 
#-------------------------------------------------------------------------

# Standard flags
#  - CPPFLAGS : flags for the preprocessor (eg. -I,-D)
#  - CFLAGS   : flags for C compiler (eg. -Wall,-g,-O3)
#  - CXXFLAGS : flags for C++ compiler (eg. -Wall,-g,-O3)
#  - LDFLAGS  : flags for the linker (eg. -L)

CPPFLAGS    := 
CFLAGS      := -Wall -g -O3
CXXFLAGS    := -Wall -g -O3 -D_MIPS_ARCH_LLFU
LDFLAGS     := 

# C compiler and linker

CC          := maven-gcc
COMPILE_C   := $(CC) $(CFLAGS) -funroll-loops -MMD -MP -I. $(CPPFLAGS)
LD_C        := $(CC)
LINK_C      := $(LD_C) -L. $(LDFLAGS)

# C++ compiler and linker

CXX         := maven-g++
COMPILE_CXX := $(CXX) $(CXXFLAGS) -MMD -MP -I. $(CPPFLAGS)
LD_CXX      := $(CXX)
LINK_CXX    := $(LD_CXX) -L. $(LDFLAGS)

# Library creation

AR          := maven-ar
RANLIB      := maven-ranlib

# Host simulator

RUN         := maven-isa-run
RUNFLAGS    := 

# Installation

MKINSTALLDIRS := $(scripts_dir)/mk-install-dirs.sh
INSTALL       := /usr/bin//install -c
INSTALL_HDR   := $(INSTALL) -m 444
INSTALL_LIB   := $(INSTALL) -m 644
INSTALL_EXE   := $(INSTALL) -m 555
STOW          := 

#-------------------------------------------------------------------------
# Setup subproject lists and include makefile fragments
#-------------------------------------------------------------------------

sprojs_internal    := ubmark 
sprojs_internal_en := ubmark 
sprojs_install     := 

sprojs_mk := $(addsuffix .mk, $(sprojs_internal_en))

-include $(sprojs_mk)
VPATH := $(addprefix $(src_dir)/, $(sprojs_internal_en))

# The utst subproject is special since the makefile explicitly uses the
# utst compiler and linking flags when building unit tests. If we are
# using a globally installed utst library then the utst make variables
# will not have been set in the utst make fragment. So we set them here
# (from the configure script) if they were not set in the make fragment.

utst_cppflags ?= @utst_cppflags@
utst_ldflags  ?= @utst_ldflags@
utst_libs     ?= @utst_libs@

#-------------------------------------------------------------------------
# Template for per subproject rules
#-------------------------------------------------------------------------
# The template is instantiated for each of the subprojects. It relies on
# subprojects defining a certain set of make variables which are all
# prefixed with the subproject name. Since subproject names can have
# dashes in them (and the make variables are assumed to only use
# underscores) the template takes two arguments - one with the regular 
# subproject name and one with dashes replaced with underscores.
#
# Arguments:
#  $(1) : real subproject name (ie with dashes)
#  $(2) : normalized subproject name (ie dashes replaced with underscores)
#

define subproject_template

# In some (rare) cases, a subproject might not have any actual object
# files. It might only include header files or program sources. To keep
# things consistent we still want a library for this subproject, so in
# this spectial case we create a dummy source file and thus the build
# system will create a library for this subproject with just the
# corresponding dummy object file.

ifeq ($$(strip $$($(2)_srcs)),)
$(2)_srcs += $(1)_.cc
$(2)_junk += $(1)_.cc
endif

$(1)_.cc :
	echo "int $(2)_( int arg ) { return arg; }" > $$@

# Build the object files from assembly sources for this subproject

$(2)_asm_srcs := $$(filter %.S, $$($(2)_srcs))
$(2)_asm_objs := $$(patsubst %.S, %.o, $$($(2)_asm_srcs))
$(2)_asm_deps := $$(patsubst %.S, %.d, $$($(2)_asm_srcs))

$$($(2)_asm_objs) : %.o : %.S
	$(COMPILE_C) $$($(2)_cppflags) -c $$<

$(2)_objs += $$($(2)_asm_objs)
$(2)_deps += $$($(2)_asm_deps)
$(2)_junk += $$($(2)_asm_deps) $$($(2)_asm_objs)

# Build the object files from C sources for this subproject

$(2)_c_srcs := $$(filter %.c, $$($(2)_srcs))
$(2)_c_objs := $$(patsubst %.c, %.o, $$($(2)_c_srcs))
$(2)_c_deps := $$(patsubst %.c, %.d, $$($(2)_c_srcs))

$$($(2)_c_objs) : %.o : %.c
	$(COMPILE_C) $$($(2)_cppflags) -c $$<

$(2)_objs += $$($(2)_c_objs)
$(2)_deps += $$($(2)_c_deps)
$(2)_junk += $$($(2)_c_deps) $$($(2)_c_objs)

# Build the object files from C++ sources for this subproject

$(2)_cxx_srcs := $$(filter %.cc, $$($(2)_srcs))
$(2)_cxx_objs := $$(patsubst %.cc, %.o, $$($(2)_cxx_srcs))
$(2)_cxx_deps := $$(patsubst %.cc, %.d, $$($(2)_cxx_srcs))

$$($(2)_cxx_objs) : %.o : %.cc
	$(COMPILE_CXX) $$($(2)_cppflags) -c $$<

$(2)_objs += $$($(2)_cxx_objs)
$(2)_deps += $$($(2)_cxx_deps)
$(2)_junk += $$($(2)_cxx_deps) $$($(2)_cxx_objs)

# Build a library for this subproject

$(2)_libname = lib$(1).a
$$($(2)_libname) : $$($(2)_objs)
	$(AR) rcv $$@ $$^
	$(RANLIB) $$@

$(2)_junk += $$($(2)_libname)

# Use the list of internal subprojects which this subproject depends on
# to create a list of prerequisite libraries (including this
# subproject's library).

$(2)_intdeps_libnames := $$(patsubst %, lib%.a, $$($(2)_intdeps))
$(2)_link_prereqs     := $$($(2)_libname) $$($(2)_intdeps_libnames)

# Build unit tests

$(2)_test_objs := $$(patsubst %.cc,   %.o,    $$($(2)_test_srcs))
$(2)_test_deps := $$(patsubst %.cc,   %.d,    $$($(2)_test_srcs))
$(2)_test_exes := $$(patsubst %.t.cc, %-utst, $$($(2)_test_srcs))
$(2)_test_outs := $$(patsubst %,      %.out,  $$($(2)_test_exes))

$$($(2)_test_objs) : %.o : %.cc
	$(COMPILE_CXX) $$($(2)_cppflags) $(utst_cppflags) -c $$<

$$($(2)_test_exes) : %-utst : %.t.o $$($(2)_link_prereqs) $(utst_libname) 
	$(LINK_CXX) $$($(2)_ldflags) $(utst_ldflags) -o $$@ $$< \
    $$($(2)_libs) $(utst_libs)

$(2)_deps += $$($(2)_test_deps)
$(2)_junk += \
	$$($(2)_test_deps) $$($(2)_test_objs) \
  $$($(2)_test_exes) *.junk-dat

# Run unit tests

$$($(2)_test_outs) : %.out : %
	$(RUN) $(RUNFLAGS) ./$$< default 2>&1 | tee $$@

$(2)_junk += $$($(2)_test_outs)

# Build C programs

$(2)_prog_c_srcs := $$(filter %.c, $$($(2)_prog_srcs))
$(2)_prog_c_srcs += $$(filter %.c, $$($(2)_install_prog_srcs))
$(2)_prog_c_objs := $$(patsubst %.c, %.o, $$($(2)_prog_c_srcs))
$(2)_prog_c_deps := $$(patsubst %.c, %.d, $$($(2)_prog_c_srcs))
$(2)_prog_c_exes := $$(patsubst %.c, %,   $$($(2)_prog_c_srcs))

$$($(2)_prog_c_objs) : %.o : %.c
	$(COMPILE_C) $$($(2)_cppflags) -c $$<

$$($(2)_prog_c_exes) : % : %.o $$($(2)_link_prereqs)
	$(LINK_C) $$($(2)_ldflags) -o $$@ $$< $$($(2)_libs) 

$(2)_exes += $$($(2)_prog_c_exes) 
$(2)_deps += $$($(2)_prog_c_deps)
$(2)_junk += \
  $$($(2)_prog_c_objs) $$($(2)_prog_c_deps) $$($(2)_prog_c_exes)

# Build C++ programs

$(2)_prog_cxx_srcs := $$(filter %.cc, $$($(2)_prog_srcs))
$(2)_prog_cxx_srcs += $$(filter %.cc, $$($(2)_install_prog_srcs))
$(2)_prog_cxx_objs := $$(patsubst %.cc, %.o, $$($(2)_prog_cxx_srcs))
$(2)_prog_cxx_deps := $$(patsubst %.cc, %.d, $$($(2)_prog_cxx_srcs))
$(2)_prog_cxx_exes := $$(patsubst %.cc, %,   $$($(2)_prog_cxx_srcs))

$$($(2)_prog_cxx_objs) : %.o : %.cc
	$(COMPILE_CXX) $$($(2)_cppflags) -c $$<

$$($(2)_prog_cxx_exes) : % : %.o $$($(2)_link_prereqs)
	$(LINK_CXX) $$($(2)_ldflags) -o $$@ $$< $$($(2)_libs) 

$(2)_exes += $$($(2)_prog_cxx_exes) 
$(2)_deps += $$($(2)_prog_cxx_deps)
$(2)_junk += \
  $$($(2)_prog_cxx_objs) $$($(2)_prog_cxx_deps) $$($(2)_prog_cxx_exes)

# Install subproject's header (.h), inline (.inl), source (.cc), and
# package config (.pc) files if this subproject is on the sproj_install
# list.

ifneq ($$(filter $(1),$(sprojs_install)),)

$(2)_install_hdrs_wdir := \
  $$(addprefix $$(src_dir)/$(1)/, $$($(2)_hdrs)) \
  $$(addprefix $$(src_dir)/$(1)/, $$($(2)_inls)) \
  $(2)-config.h \

install-libs-$(1) : $$($(2)_install_hdrs_wdir) $$($(2)_libname) $(1).pc
	$(MKINSTALLDIRS) $(install_hdrs_dir)/$(1) \
    $(install_libs_dir) $(install_pkcs_dir)
	for file in $$($(2)_install_hdrs_wdir); do \
    $(INSTALL_HDR) $$$$file $(install_hdrs_dir)/$(1); \
  done
	$(INSTALL_LIB) $$($(2)_libname) $(install_libs_dir)
	$(INSTALL_LIB) $(1).pc $(install_pkcs_dir)/$(1).pc

install-libs : install-libs-$(1)
.PHONY : install-libs-$(1)

endif

# We always install executables which have been placed in
# sproj_install_prog_exes regardless of whether or not subproject is on
# the sprojs_install list.

$(2)_install_prog_exes = $$(basename $$($(2)_install_prog_srcs))

install-exes-$(1) : $$($(2)_install_prog_exes)
	$(MKINSTALLDIRS) $(install_exes_dir)
	for file in $$($(2)_install_prog_exes); do \
    $(INSTALL_EXE) $$$$file $(install_exes_dir); \
  done

install-exes : install-exes-$(1)
.PHONY : install-exes-$(1)

# Other subproject specific targets

all-$(1) : $$($(2)_libname) $$($(2)_prog_exes) $$($(2)_install_prog_exes)

check-$(1) : $$($(2)_test_outs)
	echo; grep -h -e'Unit Tests' -e'FAILED' \
    -e'Segementation' -e'ERROR' $$^; echo

install-$(1) : install-libs-$(1) install-exes-$(1)

clean-$(1) :
	rm -rf $$($(2)_junk)

.PHONY : all-$(1) check-$(1) install-$(1) clean-$(1)

# Update running variables

libs += $$($(2)_libname)
objs += $$($(2)_objs)
exes += $$($(2)_exes)
outs += $$($(2)_test_outs)
junk += $$($(2)_junk)
deps += $$($(2)_deps)

endef

# Call template for each enabled internal subproject

$(foreach sproj,$(sprojs_internal_en), \
  $(eval $(call subproject_template,$(sproj),$(subst -,_,$(sproj)))))

#-------------------------------------------------------------------------
# Autodependency files
#-------------------------------------------------------------------------

-include $(deps)

deps : $(deps)
.PHONY : deps

#-------------------------------------------------------------------------
# Check
#-------------------------------------------------------------------------

check : $(outs)
	echo; grep -h -e'Unit Tests' -e'FAILED' \
    -e'Segementation' -e'ERROR' $^; echo

.PHONY : check

#-------------------------------------------------------------------------
# Installation
#-------------------------------------------------------------------------

install : install-libs install-exes
ifeq ($(enable_stow),yes)
	$(MKINSTALLDIRS) $(stow_pkg_dir)
	cd $(stow_pkg_dir) && \
    $(STOW) --delete $(project_name)-* && \
    $(STOW) $(project_name)-$(project_ver)
endif

.PHONY : install install-libs install_exes

#-------------------------------------------------------------------------
# Regenerate configure information
#-------------------------------------------------------------------------

configure_prereq = \
  $(src_dir)/configure.ac \
  $(src_dir)/aclocal.m4 \
  $(join $(addprefix $(src_dir)/, $(sprojs_internal_en)), \
         $(patsubst  %, /%.ac, $(sprojs_internal_en)))

$(src_dir)/configure : $(configure_prereq)
	cd $(src_dir) && autoconf && autoheader

config.status : $(src_dir)/configure
	./config.status --recheck

makefile_prereq = \
  config.status \
  $(src_dir)/Makefile.in \
  $(join $(addprefix $(src_dir)/, $(sprojs_internal_en)), \
         $(patsubst  %, /%.mk.in, $(sprojs_internal_en))) \
  $(join $(addprefix $(src_dir)/, $(sprojs_install)), \
         $(patsubst  %, /%.pc.in, $(sprojs_install))) \

Makefile : $(makefile_prereq)
	./config.status

dist_junk += \
  config.status Makefile config.log \
  $(addsuffix -config.h, $(sprojs_internal_en)) \
  $(addsuffix .mk, $(sprojs_internal_en)) \
  $(addsuffix .pc, $(sprojs_install)) \

#-------------------------------------------------------------------------
# Distribution
#-------------------------------------------------------------------------
# The distribution tarball is named project-ver.tar.gz and it includes
# both enabled and disabled subprojects. 

dist_files = \
  $(sprojs_internal) \
  README \
  style-guide.txt \
  mcppbs-uguide.txt \
  scripts \
  configure.ac \
  aclocal.m4 \
  configure \
  config.h.in \
  Makefile.in \

dist_dir := $(project_name)-$(project_ver)
dist_tgz := $(project_name)-$(project_ver).tar.gz

# Notice that when we make the distribution we rewrite the configure.ac
# script with the current version and we rerun autoconf in the new
# source directory so that the distribution will have the proper version
# information. We also rewrite the "Version : " line in the README.

dist :
	rm -rf $(dist_dir)
	mkdir $(dist_dir)
	tar -C $(src_dir) -cf - $(dist_files) | tar -C $(dist_dir) -xpf -
	sed -i.bak 's/^\(# Version :\).*/\1 $(project_ver)/' $(dist_dir)/README
	sed -i.bak 's/\( proj_version,\).*/\1 [$(project_ver)])/' $(dist_dir)/configure.ac
	cd $(dist_dir) && \
    autoconf && autoheader && \
    rm -rf autom4te.cache configure.ac.bak README.bak
	tar -czvf $(dist_tgz) $(dist_dir)
	rm -rf $(dist_dir)

# You can use the distcheck target to try untarring the distribution and
# then running configure, make, make check, and make distclean. A
# "directory is not empty" error means distclean is not removing
# everything.

distcheck : dist
	rm -rf $(dist_dir)
	tar -xzvf $(dist_tgz)
	mkdir -p $(dist_dir)/build
	cd $(dist_dir)/build; ../configure; make; make check; make distclean
	rm -rf $(dist_dir)

junk += $(project_name)-*.tar.gz

.PHONY : dist distcheck

#-------------------------------------------------------------------------
# Default
#-------------------------------------------------------------------------

all : $(libs) $(exes)
.PHONY : all

#-------------------------------------------------------------------------
# Makefile debugging
#-------------------------------------------------------------------------
# This handy rule will display the contents of any make variable by
# using the target debug-<varname>. So for example, make debug-junk will
# display the contents of the junk variable.

debug-% :
	@echo $* = $($*)

#-------------------------------------------------------------------------
# Clean up junk
#-------------------------------------------------------------------------

clean :
	rm -rf *~ \#* $(junk)

distclean :
	rm -rf *~ \#* $(junk) $(dist_junk)

.PHONY : clean distclean
