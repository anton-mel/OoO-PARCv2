#=========================================================================
# Toplevel Makefile for Maven Assembly Test Programs
#=========================================================================
# This makefile is derrived from the Modular C++ Build System, so
# reading the documenation in 'mcppbs-doc.txt' may be helpful. Instead
# of subprojects we use the concept of test modules.

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

project_name := parc-test
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

install_exes_dir := $(DESTDIR)/test

#-------------------------------------------------------------------------
# Setup test module lists and include makefile fragments
#-------------------------------------------------------------------------

tmods    := parcv1 parcv2 
VPATH    := $(addprefix $(src_dir)/, $(tmods))

tmods_mk := $(join $(addprefix $(src_dir)/, $(tmods)), \
            $(patsubst %, /%.mk, $(tmods)))

include $(tmods_mk)

#-------------------------------------------------------------------------
# Programs and flags
#-------------------------------------------------------------------------

# Standard flags
#  - CPPFLAGS : flags for the preprocessor (eg. -I,-D)
#  - CFLAGS   : flags for C compiler (eg. -Wall,-g,-O3)
#  - LDFLAGS  : flags for the linker (eg. -L)

CPPFLAGS    := 
CFLAGS      := -Wall
LDFLAGS     := 

# Test build

CC := maven-gcc
TESTBUILD := \
  $(CC) $(CFLAGS) $(LDFLAGS) \
        -T $(scripts_dir)/test.ld -nostartfiles \
        -MMD -MP -I. $(addprefix -I $(src_dir)/, $(tmods)) $(CPPFLAGS)

# Host simulator

RUN           := maven-isa-testrun
RUNFLAGS      := 

# Installation

MKINSTALLDIRS := $(scripts_dir)/mk-install-dirs.sh
INSTALL       := /usr/bin//install -c
INSTALL_EXE   := $(INSTALL) -m 555
STOW          := 

#-------------------------------------------------------------------------
# Template for per test module rules
#-------------------------------------------------------------------------

# The template is instantiated for each of the test modules. It relies
# on test modules defining a certain set of make variables which are all
# prefixed with the test module name. Since test module names can have
# dashes in them (and the make variables are assumed to only use
# underscores) the template takes two arguments - one with the regular
# test module name and one with dashes replaced with underscores.
#
# Arguments:
#  $(1) : real test module name (ie with dashes)
#  $(2) : normalized test module name (ie dashes replaced by underscores)
#

define tmod_template

# Build test binaries

$(2)_deps := $$(patsubst %.S, %.d, $$($(2)_srcs))
$(2)_exes := $$(patsubst %.S, %,   $$($(2)_srcs))

$$($(2)_exes) : % : %.S
	$(TESTBUILD) -o $$@ $$<

$(2)_junk += $$($(2)_exes) $$($(2)_deps)

# Run test binaries

$(2)_outs := $$(patsubst %, %.out, $$($(2)_exes))
$$($(2)_outs) : %.out : %
	$(RUN) $(RUNFLAGS) ./$$< 2>&1 | tee $$@

$(2)_junk += $$($(2)_outs)

# Install test binaries

install-exes-$(1) : $$($(2)_exes)
	$(MKINSTALLDIRS) $(install_exes_dir)
	for file in $$($(2)_exes); do \
    $(INSTALL_EXE) $$$$file $(install_exes_dir); \
  done

install-exes : install-exes-$(1)
.PHONY : install-exes-$(1)

# Other subproject specific targets

all-$(1) : $$($(2)_exes)

check-$(1) : $$($(2)_outs)
	$(scripts_dir)/check-summary.rb $$^

vcheck-$(1) : $$($(2)_outs)
	$(scripts_dir)/check-summary.rb -v $$^

install-$(1) : install-exes-$(1)

clean-$(1) :
	rm -rf $$($(2)_junk)

.PHONY : all-$(1) check-$(1) install-$(1) clean-$(1)

# Update running variables

exes += $$($(2)_exes)
deps += $$($(2)_deps)
outs += $$($(2)_outs)
junk += $$($(2)_junk)

endef

# Call template for each test module

$(foreach tmod,$(tmods), \
  $(eval $(call tmod_template,$(tmod),$(subst -,_,$(tmod)))))

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
	$(scripts_dir)/check-summary.rb $^

vcheck : $(outs)
	$(scripts_dir)/check-summary.rb -v $^

.PHONY : check

#-------------------------------------------------------------------------
# Installation
#-------------------------------------------------------------------------

install : install-exes
ifeq ($(enable_stow),yes)
	$(MKINSTALLDIRS) $(stow_pkg_dir)
	cd $(stow_pkg_dir) && \
    $(STOW) --delete $(project_name)-* && \
    $(STOW) $(project_name)-$(project_ver)
endif

.PHONY : install install_exes

#-------------------------------------------------------------------------
# Regenerate configure information
#-------------------------------------------------------------------------

configure_prereq = \
  $(src_dir)/configure.ac \
  $(src_dir)/aclocal.m4 \

$(src_dir)/configure : $(configure_prereq)
	cd $(src_dir) && autoconf

config.status : $(src_dir)/configure
	./config.status --recheck

makefile_prereq = \
  config.status \
  $(src_dir)/Makefile.in \

Makefile : $(makefile_prereq)
	./config.status

dist_junk += \
  config.status Makefile config.log

#-------------------------------------------------------------------------
# Distribution
#-------------------------------------------------------------------------
# The distribution tarball is named project-ver.tar.gz and it includes
# all test modules.

dist_files = \
  $(tmods) \
  README \
  scripts \
  configure.ac \
  aclocal.m4 \
  configure \
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

all : $(exes)
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

