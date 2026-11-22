TNBVER := $(shell awk '/ProvidesExplPackage\{tcbnestbreak\}/{getline; split($$0, a, "[{}]"); print a[4]}' tcbnestbreak.sty)

DOCS := tcbnestbreak.pdf

## The TeX Live to test with: the directory of its binaries, e.g.
##   make test TEXBIN=/usr/local/texlive/2025/bin/universal-darwin
## (default: the one in PATH)
TEXBIN ?=

## The tcbpagefootnote package (v1.4 or later) for test-footnote.tex;
## the tests with it are skipped if it is not there.
TPF ?= ../tcbpagefootnote

## The pxpgftate package for the tests in tate with pLaTeX and upLaTeX,
## used if the TeX Live does not have it (TeX Live 2025); these tests
## are skipped if it is in neither place.
PXPGFTATE ?= ../pxpgftate

.PHONY: ctanzip
ctanzip: tcbnestbreak.zip ## Archive for CTAN upload
tcbnestbreak.zip: clean $(DOCS)
	git archive --format=tar --prefix=tcbnestbreak/ HEAD | gtar -x
	## remove unpacked files
	cd tcbnestbreak/ && \
		rm -f .gitignore Makefile ctan.toml
	## then, now just make archive
	zip -9 -r tcbnestbreak.zip tcbnestbreak/*
	rm -rf tcbnestbreak
	@echo finished

.PHONY: tcbnestbreak.pdf
tcbnestbreak.pdf: tcbnestbreak.tex tcbnestbreak.sty
	pdflatex -interaction=nonstopmode -halt-on-error $<
	pdflatex -interaction=nonstopmode -halt-on-error $<

## Run the test suite ($(TNBVER)):
##  * every test compiles without errors and without an overfull page
##  * TESTS: TNB-RESULT OK and no TNB-* NG: every box that flows has
##    its frames (unbroken, or first, middle, ..., last) on pages that
##    follow each other, with the segmentation in one of them if the
##    box has a lower part, and the frames are as high as what has
##    flowed (see test-common.tex)
##  * test-tate-*: vertical writing (tarticle, utarticle, ltjtarticle);
##    the same checks as in yoko
##  * PLAIN: test-plain.tex gives the same text (pdftotext -layout)
##    with and without tcbnestbreak
##  * FOOTNOTE (with tcbpagefootnote in $(TPF)): the same as TESTS, no
##    split footnote ("% split" of \tracingpages), the page footnotes
##    are on the pages of their marks (TNB-NOTE), and the ten footnote
##    texts are in the PDF
## A test is "<engine>:<jobname>:<input>".  The output of the engine and
## of (x)dvipdfmx is kept in <jobname>.term.
## $(TPF) and $(PXPGFTATE) are put into TEXINPUTS only for the tests
## that need them: a directory with files of the same job names (as
## the tests of tcbpagefootnote have) must not be searched by the
## other tests.
TESTS := \
  pdflatex:test-basic-pdflatex:'\input test-basic' \
  xelatex:test-basic-xelatex:'\input test-basic' \
  lualatex:test-basic-lualatex:'\input test-basic' \
  lualatex:test-basic-ltjsarticle-lualatex:'\def\CLS{ltjsarticle}\input test-basic' \
  platex:test-basic-platex:'\def\CLS{jarticle}\input test-basic' \
  platex:test-basic-jsarticle-platex:'\def\CLS{jsarticle}\input test-basic' \
  uplatex:test-basic-uplatex:'\def\CLS{ujarticle}\input test-basic' \
  pdflatex:test-twocolumn-pdflatex:'\PassOptionsToClass{twocolumn}{article}\input test-basic' \
  platex:test-tate-platex:'\input test-tate' \
  uplatex:test-tate-uplatex:'\def\CLS{utarticle}\input test-tate' \
  lualatex:test-tate-lualatex:'\input test-tate'

PLAIN := \
  pdflatex:test-plain-pdflatex:'\input test-plain' \
  lualatex:test-plain-lualatex:'\input test-plain' \
  platex:test-plain-platex:'\def\CLS{jarticle}\input test-plain'

FOOTNOTE := \
  pdflatex:test-footnote-pdflatex:'\input test-footnote' \
  xelatex:test-footnote-xelatex:'\input test-footnote' \
  lualatex:test-footnote-lualatex:'\input test-footnote' \
  platex:test-footnote-platex:'\def\CLS{jarticle}\input test-footnote' \
  uplatex:test-footnote-uplatex:'\def\CLS{ujarticle}\input test-footnote' \
  platex:test-tate-footnote-platex:'\def\TNBfile{test-footnote}\input test-tate' \
  lualatex:test-tate-footnote-lualatex:'\def\TNBfile{test-footnote}\input test-tate'

HASTPF := $(wildcard $(TPF)/tcbpagefootnote.sty)

## Choose the TeX Live, and find pxpgftate: $$pxp is "kpse" if the TeX
## Live has it, the directory $(PXPGFTATE) if it is there, else empty
SETUP = \
  $(if $(TEXBIN),export PATH="$(TEXBIN):$$PATH";) \
  echo "== `pdflatex --version | head -1`"; \
  if kpsewhich pxpgftate.sty >/dev/null 2>&1; then pxp=kpse; \
  elif [ -f $(PXPGFTATE)/pxpgftate.sty ]; then pxp=$(PXPGFTATE); \
  else pxp=; fi

## Compile $$in with $$eng as $$job once (+ (x)dvipdfmx), and check
## for errors and overfull pages.  A test in tate with pTeX is skipped
## ($$skip) without pxpgftate.
RUN = \
  skip=; ti=.; pre=; \
  case $$job in test-*footnote-*) ti="$$ti:$(TPF)"; pre="LUAINPUTS=$(TPF):$$LUAINPUTS";; esac; \
  case $$job in test-tate-*platex) \
    case "$$pxp" in "") skip=1;; kpse) ;; *) ti="$$ti:$$pxp";; esac;; \
  esac; \
  if [ -n "$$skip" ]; then echo "   skipped: no pxpgftate.sty"; else \
  rm -f $$job.aux $$job.dvi $$job.xdv; \
  opt=; if [ $$eng = xelatex ]; then opt=-no-pdf; fi; \
  env TEXINPUTS="$$ti:$$TEXINPUTS" $$pre $$eng $$opt -interaction=nonstopmode -jobname=$$job "$$in" >$$job.term 2>&1 || true; \
  if [ -f $$job.dvi ]; then dvipdfmx $$job.dvi >>$$job.term 2>&1; fi; \
  if [ -f $$job.xdv ]; then xdvipdfmx $$job.xdv >>$$job.term 2>&1; fi; \
  if grep -q '^!' $$job.log; then echo "NG: error in $$job.log"; exit 1; fi; \
  if grep 'Overfull .vbox' $$job.log; then echo "NG: overfull page in $$job.log"; exit 1; fi; \
  fi

## Check the result of test-common.tex in $$job.log
RESULT = \
  if [ -z "$$skip" ]; then \
  if grep -q '^TNB-.* NG' $$job.log; then grep '^TNB-.* NG' $$job.log; exit 1; fi; \
  grep -q '^TNB-RESULT OK' $$job.log || \
    { echo "NG: no TNB-RESULT OK in $$job.log"; exit 1; }; \
  fi

.PHONY: test
test:
	@set -e; \
	$(SETUP); \
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
	$(if $(HASTPF),,echo "== test-footnote skipped: no $(TPF)/tcbpagefootnote.sty";) \
	for t in $(if $(HASTPF),$(FOOTNOTE)); do \
	  eng=$${t%%:*}; rest=$${t#*:}; job=$${rest%%:*}; in=$${rest#*:}; \
	  echo "== $$eng $$job"; \
	  $(RUN); \
	  $(RESULT); \
	  if [ -z "$$skip" ]; then \
	  if grep '^% split' $$job.log; then echo "NG: split footnote in $$job.log"; exit 1; fi; \
	  n=`pdftotext $$job.pdf - | grep -c 'Footnote text [0-9]*\.' || true`; \
	  [ $$n -eq 10 ] || { echo "NG: $$n footnote texts in $$job.pdf, want 10"; exit 1; }; \
	  fi; \
	done; \
	echo "All tests passed ($(TNBVER))"

.PHONY: clean
clean: ## Clean this repository
	rm -rf tcbnestbreak.zip tcbnestbreak
	rm -f *.aux *.log *.out *.toc *.dvi *.xdv *.synctex.gz *.term
	rm -f test-*.pdf test-*.txt
	find . -type f -name "*~" -delete
