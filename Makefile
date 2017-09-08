# Makefile for Sphinx documentation
#

# You can set these variables from the command line.
# -a  write all files; default is to only write new and changed files
SPHINXOPTS    = -a -j 2
SPHINXBUILD   = python -msphinx
SPHINXPROJ    = codex
SOURCEDIR     = docs
BUILDDIR      = build

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Copy $(BUILDDIR)/html $(BUILDDIR)/codex because the ultimate destination is
# a subfolder website www.starkandwayne.com/codex
# This, in combination with the manifest.yml setting "path: build" put the
# static files in the right place.
deploy:
	$(SPHINXBUILD) -M html "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
	rm -rf $(BUILDDIR)/codex
	cp -R $(BUILDDIR)/html $(BUILDDIR)/codex
	cf push $(SPHINXPROJ)
	rm -rf $(BUILDDIR)/codex
