TNBVER := $(shell awk '/ProvidesExplPackage\{tcbnestbreak\}/{getline; split($$0, a, "[{}]"); print a[4]}' tcbnestbreak.sty)

## The tcbpagefootnote package (v1.4 or later) for test-footnote.tex;
## the test is skipped if it is not there.
TPF ?= ../tcbpagefootnote

.PHONY: ctanzip
ctanzip: tcbnestbreak.zip ## Archive for CTAN upload
tcbnestbreak.zip: clean
	git archive --format=tar --prefix=tcbnestbreak/ HEAD | gtar -x
	## remove unpacked files
	cd tcbnestbreak/ && \
		rm -f .gitignore Makefile
	## then, now just make archive
	zip -9 -r tcbnestbreak.zip tcbnestbreak/*
	rm -rf tcbnestbreak
	@echo finished

## Run the test suite ($(TNBVER)):
##  * every test compiles without errors and without an overfull page
##  * TESTS: TNB-RESULT OK and no TNB-* NG: every box that flows has
##    its frames (unbroken, or first, middle, ..., last) on pages that
##    follow each other, and the frames are as high as what has flowed
##    (see test-common.tex)
##  * PLAIN: test-plain.tex gives the same text (pdftotext -layout)
##    with and without tcbnestbreak
##  * FOOTNOTE (with tcbpagefootnote in $(TPF)): the same as TESTS, no
##    split footnote ("% split" of \tracingpages), and the seven
##    footnote texts are in the PDF
## A test is "<engine>:<jobname>:<input>".  The output of the engine and
## of (x)dvipdfmx is kept in <jobname>.term.
TESTS := \
  pdflatex:test-basic-pdflatex:'\input test-basic' \
  xelatex:test-basic-xelatex:'\input test-basic' \
  lualatex:test-basic-lualatex:'\input test-basic' \
  lualatex:test-basic-ltjsarticle-lualatex:'\def\CLS{ltjsarticle}\input test-basic' \
  platex:test-basic-platex:'\def\CLS{jarticle}\input test-basic' \
  platex:test-basic-jsarticle-platex:'\def\CLS{jsarticle}\input test-basic' \
  uplatex:test-basic-uplatex:'\def\CLS{ujarticle}\input test-basic' \
  pdflatex:test-twocolumn-pdflatex:'\PassOptionsToClass{twocolumn}{article}\input test-basic'

PLAIN := \
  pdflatex:test-plain-pdflatex:'\input test-plain' \
  lualatex:test-plain-lualatex:'\input test-plain' \
  platex:test-plain-platex:'\def\CLS{jarticle}\input test-plain'

FOOTNOTE := \
  pdflatex:test-footnote-pdflatex:'\input test-footnote' \
  xelatex:test-footnote-xelatex:'\input test-footnote' \
  lualatex:test-footnote-lualatex:'\input test-footnote' \
  platex:test-footnote-platex:'\def\CLS{jarticle}\input test-footnote' \
  uplatex:test-footnote-uplatex:'\def\CLS{ujarticle}\input test-footnote'

## Compile $$in with $$eng as $$job once (+ (x)dvipdfmx), and check
## for errors and overfull pages
RUN = \
  rm -f $$job.aux $$job.dvi $$job.xdv; \
  opt=; if [ $$eng = xelatex ]; then opt=-no-pdf; fi; \
  $$eng $$opt -interaction=nonstopmode -jobname=$$job "$$in" >$$job.term 2>&1 || true; \
  if [ -f $$job.dvi ]; then dvipdfmx $$job.dvi >>$$job.term 2>&1; fi; \
  if [ -f $$job.xdv ]; then xdvipdfmx $$job.xdv >>$$job.term 2>&1; fi; \
  if grep -q '^!' $$job.log; then echo "NG: error in $$job.log"; exit 1; fi; \
  if grep 'Overfull .vbox' $$job.log; then echo "NG: overfull page in $$job.log"; exit 1; fi

## Check the result of test-common.tex in $$job.log
RESULT = \
  if grep -q '^TNB-.* NG' $$job.log; then grep '^TNB-.* NG' $$job.log; exit 1; fi; \
  grep -q '^TNB-RESULT OK' $$job.log || \
    { echo "NG: no TNB-RESULT OK in $$job.log"; exit 1; }

.PHONY: test
test:
	@set -e; \
	for t in $(TESTS); do \
	  eng=$${t%%:*}; rest=$${t#*:}; job=$${rest%%:*}; in=$${rest#*:}; \
	  echo "== $$eng $$job"; \
	  $(RUN); \
	  $(RESULT); \
	done; \
	for t in $(PLAIN); do \
	  eng=$${t%%:*}; rest=$${t#*:}; on=$${rest%%:*}; input=$${rest#*:}; \
	  echo "== $$eng $$on"; \
	  job=$$on; in="$$input"; $(RUN); \
	  job=$$on-off; in="\def\TNBoff{1}$$input"; $(RUN); \
	  pdftotext -layout $$on.pdf $$on.txt; \
	  pdftotext -layout $$on-off.pdf $$on-off.txt; \
	  cmp $$on.txt $$on-off.txt || \
	    { echo "NG: $$on.pdf differs from $$on-off.pdf"; exit 1; }; \
	done; \
	if [ -f $(TPF)/tcbpagefootnote.sty ]; then \
	  export TEXINPUTS=".:$(TPF):" LUAINPUTS="$(TPF):"; \
	  for t in $(FOOTNOTE); do \
	    eng=$${t%%:*}; rest=$${t#*:}; job=$${rest%%:*}; in=$${rest#*:}; \
	    echo "== $$eng $$job"; \
	    $(RUN); \
	    $(RESULT); \
	    if grep '^% split' $$job.log; then echo "NG: split footnote in $$job.log"; exit 1; fi; \
	    n=`pdftotext $$job.pdf - | grep -c 'Footnote text [1-7]\.' || true`; \
	    [ $$n -eq 7 ] || { echo "NG: $$n footnote texts in $$job.pdf, want 7"; exit 1; }; \
	  done; \
	else \
	  echo "== test-footnote skipped: no $(TPF)/tcbpagefootnote.sty"; \
	fi; \
	echo "All tests passed ($(TNBVER))"

.PHONY: clean
clean: ## Clean this repository
	rm -rf tcbnestbreak.zip tcbnestbreak
	rm -f *.aux *.log *.out *.toc *.dvi *.xdv *.synctex.gz *.term
	rm -f test-*.pdf test-*.txt
	find . -type f -name "*~" -delete
