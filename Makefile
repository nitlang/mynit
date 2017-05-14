# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2008 Jean Privat <jean@pryen.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

project_bindir = ./bin
project_docdir = ./doc
project_mandir = ./share/man

contrib_dir = ./contrib
examples_dir = ./examples
lib_dir = ./lib
srcdir = ./src
all_contribs = $(dir $(wildcard $(contrib_dir)/*/Makefile))

# Additional program directories (contrib and examples) that are buildable
extras = $(filter-out $(contrib_dir)/nitc/,$(all_contribs))
extras += $(dir $(wildcard $(examples_dir)/*/Makefile))

# Libraries with a `Makefile`.
# Only used for cleaning.
libs = $(dir $(wildcard $(lib_dir)/*/Makefile))

.PHONY: all
all: tools man
	@echo ""
	@echo "Congratulations! Nit was succesfully compiled."
	@echo "To configure your shell environment, execute the following command:"
	@echo "    source misc/nit_env.sh install"

# Compile all programs in `contrib`, `examples` and `src`.
#
# Furthermore, build the toolchain’s `man` pages.
.PHONY: full
full: all
	for directory in $(extras); do \
		(cd "$${directory}" && $(MAKE)) || exit 1; \
	done

.PHONY: docs
docs: $(project_docdir)/stdlib/index.html $(project_docdir)/nitc/index.html

.PHONY: tools $(project_bindir)
tools $(project_bindir):
	cd $(srcdir) && $(MAKE)

# These targets are not phony in order to avoid rebuilding the documentation
# tools each time the documentation is generated.
$(project_bindir)/%: _phony_nop
	cd $(srcdir) && $(MAKE) ../$@
# Implicit rules can not be phony directly. So, we use a empty phony dependency
# to workaround this limitation.
.PHONY: _phony_nop
_phony_nop:

$(project_docdir)/stdlib/index.html: $(project_bindir)/nitdoc $(project_bindir)/nitls
	@echo '***************************************************************'
	@echo '* Generate doc for NIT standard library                       *'
	@echo '***************************************************************'
	$(project_bindir)/nitdoc lib -d $(project_docdir)/stdlib \
		--custom-title "Nit Standard Library" \
		--custom-brand "<a href=\"http://nitlanguage.org/\">Nitlanguage.org</a>" \
		--custom-overview-text "<p>Documentation for the standard library of Nit<br/>Version $$(git describe)<br/>Date: $$(git show --format="%cd" | head -1)</p>" \
		--custom-footer-text "Nit standard library. Version $$(git describe)." \
		--github-upstream "nitlang:nit:master" \
		--github-base-sha1 "$$(git rev-parse HEAD)" \
		--github-gitdir "." \
		--source "https://github.com/nitlang/nit/blob/$$(git rev-parse HEAD)/%f#L%l-%L" \
		--piwik-tracker "pratchett.info.uqam.ca/piwik/" \
		--piwik-site-id "2" \

$(project_docdir)/nitc/index.html: $(project_bindir)/nitdoc $(project_bindir)/nitls
	$(project_bindir)/nitdoc lib $(srcdir)/nit*.nit $(srcdir)/test_*.nit -d $(project_docdir)/nitc \
		--private \
		--custom-title "Nit Compilers and Tools" \
		--custom-brand "<a href=\"http://nitlanguage.org/\">Nitlanguage.org</a>" \
		--custom-overview-text "<p>Documentation for the Nit tools<br/>Version $$(git describe)<br/>Date: $$(git show --format="%cd" | head -1)</p>" \
		--custom-footer-text "Nit tools. Version $$(git describe)." \
		--github-upstream "nitlang:nit:master" \
		--github-base-sha1 "$$(git rev-parse HEAD)" \
		--github-gitdir "." \
		--source "https://github.com/nitlang/nit/blob/$$(git rev-parse HEAD)/%f#L%l-%L" \
		--piwik-tracker "pratchett.info.uqam.ca/piwik/" \
		--piwik-site-id "3"

.PHONY: man $(project_mandir)
man $(project_mandir):
	# Setup PATH to find nitc
	export PATH="$$(cd $(project_bindir) && pwd):$$PATH" && \
	cd $(project_mandir) && $(MAKE)

# `clean` `distclean` and `mostlyclean` avoid deleting files usually provided by
# the maintainers.
# `maintainer-clean` deletes all files that can be regenerated by this Makefile.
#
# WARNING: The `maintainer-clean` target is intended for maintainers to use; it
# deletes files that may need special tools to rebuild.
#
# See also: https://www.gnu.org/prep/standards/html_node/Standard-Targets.html
.PHONY: clean distclean mostlyclean maintainer-clean
clean distclean mostlyclean maintainer-clean:
	rm -rf -- $(project_docdir)/stdlib $(project_docdir)/nitc
	# Clean everything in `./contrib/` and `./examples/`,
	# except `./contrib/nitc` (because `nitls` is required by some `Makefile`s)
	for directory in $(extras) $(libs); do \
		(cd "$$directory" && { $(MAKE) $@ || $(MAKE) clean; }); \
	done
	cd ./c_src && $(MAKE) clean
	cd $(srcdir) && $(MAKE) $@
	cd ./tests && $(MAKE) $@
	cd $(project_mandir) && $(MAKE) $@
	if [ $@ '!=' mostlyclean ]; then rm -f ./c_src/nitc; fi
