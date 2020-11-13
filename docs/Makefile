# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SOURCEDIR     = source
BUILDDIR      = build

.PHONY: help Makefile html pdf

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help $(SPHINXOPTS) "$(SOURCEDIR)" "$(BUILDDIR)"

# Make all available formats
all: html pdf

# Make building pdf with rinoh easier to run
pdf:
	@$(SPHINXBUILD) -b rinoh $(SPHINXOPTS) "$(SOURCEDIR)" "$(BUILDDIR)/pdf"

# Make building html
html:
	$(SPHINXBUILD) -b html $(SPHINXOPTS) "$(SOURCEDIR)" "$(BUILDDIR)/html"

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ $(SPHINXOPTS) "$(SOURCEDIR)" "$(BUILDDIR)" $(O)