# Makefile for generating HTML and PDF documents from TeXinfo source

# main TeXinfo file (without .texi extension)
BASENAME=index

# CSS file to be used for HTML generation
CSS_FILE=texinfo.css

# output directory name for split HTML output 
HTML_SPLIT_DIR=reconos_ug

# output filename for single-file monolithic HTML output
HTML_SINGLE_FILE=reconos_ug.html

# output filename for PDF output
PDF_FILE=reconos_ug.pdf

TEXI_MAIN_FILE=${BASENAME}.texi

# display available make targets
help:
	@echo "Available targets:"
	@echo "    html         HTML output, one file per node."
	@echo "    html_single  HTML output, single monolithic file"
	@echo "    pdf          PDF output"
	@echo ""
	@echo "    clean        remove all generated files"

# generate split HTML output
html:
	makeinfo --html ${TEXI_MAIN_FILE} --css-include=${CSS_FILE}

# generate monolithic HTML output
html_single:
	makeinfo --no-split --output ${HTML_SINGLE_FILE} --html ${TEXI_MAIN_FILE} --css-include=${CSS_FILE}

# generate PDF output
pdf:
	texi2pdf ${TEXI_MAIN_FILE}
	mv $(BASENAME).pdf ${PDF_FILE}

clean:
	rm -rf ${HTML_SPLIT_DIR}
	rm -f ${HTML_SINGLE_FILE}
	rm -f ${PDF_FILE} *.cp *.fn *.ky *.pg *.tp *.vr *.aux *.log *.toc

