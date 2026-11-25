# tcbnestbreak Package

**LaTeX: Breakable tcolorboxes inside breakable tcolorboxes**

tcolorbox typesets the content of a `breakable` box as one vbox and splits it with `\vsplit`. A box inside is one picture in this vbox and cannot be split, so tcolorbox ignores `breakable` for a box inside another box.

With the tcbnestbreak package, `breakable` works for a box at the top level of the content of a breakable box, and for such a box inside one that is already broken in this way, to any depth. No new key is needed:

```latex
\usepackage{tcbnestbreak}

\begin{tcolorbox}[breakable, title=Outer]
  ...
  \begin{tcolorbox}[breakable, title=Inner]
    ... % broken across pages together with the outer box
  \end{tcolorbox}
  ...
\end{tcolorbox}
```

The inner box can have a title and a lower part (`\tcblower`), and it can be defined with `\newtcolorbox`. Where the outer box is broken, the frame of the inner box is open and goes on into the padding of the outer box, so that it is seen to continue on the next page.

**Footnotes.** With the tcbpagefootnote package (v1.4 or later), the footnotes of a box with `page footnote` are put at the bottom of the page, also for each part of a breakable box. With tcbnestbreak, this holds for the boxes inside as well: if the outer box and a box inside have `page footnote`, each footnote of the inner box is put on the page of its mark. This is also tested together with the footnotenosplit package, which keeps TeX from splitting a footnote.

**Vertical writing.** The package also works in tate, with the tate classes of pLaTeX and upLaTeX (with the pxpgftate package) and of LuaTeX-ja.

* **Supported formats/engines:** pdfLaTeX, XeLaTeX, LuaLaTeX (with or without LuaTeX-ja), pLaTeX, upLaTeX (+ dvipdfmx); yoko and tate; one run, no Lua code

## How it works

1. **The inner box flows.** Its content is typeset indented, as in a list (`\@totalleftmargin`, `\linewidth`, `\parshape`), and put line by line into the list of the box around it, with the space of its frame above and below. A TeX mark (`\marks` of a class of its own) is put at its start, at its end and between its upper and its lower part. tcolorbox then splits the outer box between these lines as usual.
2. **The positions are measured.** Before a part of the outer box is drawn, a copy of the part is taken apart with `\vsplit ... to -1sp`, piece by piece. The heights of the pieces and of what is discarded between them (`\splitdiscards`) add up to the position of each mark.
3. **The frames are drawn.** For each inner box in the part, tcolorbox draws the frame with the options of that box and without text: as an unbroken box, or as a first, middle or last part of the height that is needed, with the segmentation line if the part has it. The frames are put behind the text of the part.

The text color of an inner box (`coltext`, `colupper`, `collower`) is set again at the top of the next part.

## Files

| File | Description |
|---|---|
| `tcbnestbreak.sty` | The package |
| `tcbnestbreak.tex` / `.pdf` | Documentation |
| `test-*.tex` | Test suite (see below) |

## Requirements

* `tcolorbox` (the `breakable` and `skins` libraries are loaded by the package)
* Tested with TeX Live 2025 (frozen: LaTeX2e 2025-11-01, tcolorbox 6.9.0) and TeX Live 2026 (LaTeX2e 2026-11-01, tcolorbox 6.10.0). The package uses internal macros of tcolorbox; they are listed at the top of `tcbnestbreak.sty`.
* For tate with pLaTeX and upLaTeX: `pxpgftate` (in TeX Live from 2026 on; with TeX Live 2025, install it from CTAN)

## Installation

Copy `tcbnestbreak.sty` to your local TeX tree:
`$TEXMF/tex/latex/tcbnestbreak/`

## Limitations

* A box flows only at the top level of the content of a breakable box or of a box that flows: not in a `minipage`, a `\parbox` or a cell of a `tabular`, and not with `float`, `sidebyside` or `\tcbox`. Such a box is an ordinary unbreakable box, as without the package.
* Where the outer box is broken, the frame of the inner box is always open: a part of a box of the `standard` skin is drawn with the skins `enhancedfirst`, `enhancedmiddle` and `enhancedlast`, and `toprule at break`, `bottomrule at break`, `topsep at break` and `bottomsep at break` of the inner box are not used.
* The frame is drawn when the part of the outer box is drawn, with the options of the inner box applied again. Colors or styles that are defined inside the content of the outer box are not known then. `height` and the `enlarge ... by` keys of a box that flows are not used.
* The content is indented like the content of a list. Material that does not follow `\parshape` (e.g. an `\hrule` in vertical mode) is not indented.
* The text color of the box (`coltext`, `colupper`, `collower`) is continued after a break; a `\color` inside the content is not.

## Testing

`make test` compiles the tests with pdfLaTeX, XeLaTeX, LuaLaTeX, pLaTeX and upLaTeX (+ dvipdfmx). `make test TEXBIN=<directory of the binaries>` runs them with another TeX Live than the one in `PATH`; `PXPGFTATE=<directory>` (default: `../pxpgftate`) and `FNS=<directory>` (default: `../footnotenosplit`) are where pxpgftate and footnotenosplit are taken from if that TeX Live does not have them. The tests check:

* no error and no overfull page;
* `TNB-RESULT OK`: every box that flows has its frames (one `unbroken` frame, or a `first` frame, `middle` frames and a `last` frame) on pages that follow each other; a box with a lower part has the segmentation in exactly one frame, with frames of the upper part before it and of the lower part after it; and the frames together are as high as what has flowed (recorded through the hooks `tcbnestbreak/flow` and `tcbnestbreak/frame`; see `test-common.tex`);
* `test-plain`: the text of the PDF is the same with and without the package;
* `test-footnote` (if tcbpagefootnote v1.4 or later is in `../tcbpagefootnote`, or in `TPF=<directory>`): every page footnote is on the page of its mark (`TNB-NOTE OK`), no footnote is split, and all footnote texts are in the PDF;
* `test-tate`: the same checks as for `test-basic` and `test-footnote`, in tate;
* the tests named `*-nosplit`: `test-basic` and `test-footnote` with the footnotenosplit package (footnotes are not split), with the same checks, and no warning of it.

| Test | Engines | What it covers |
|---|---|---|
| `test-basic.tex` | pdflatex (also twocolumn), xelatex, lualatex (article, ltjsarticle), platex (jarticle, jsarticle), uplatex | boxes inside a box, three levels deep, broken across several pages; a list, a display and an ordinary box inside; a title, the enhanced skin, a text color, `\newtcolorbox`; a box as the first thing in the outer box, in an item, in the lower part; boxes with a lower part, broken in the upper and in the lower part, also of the bicolor skin; boxes that do not flow (in a minipage, in an unbreakable box); an outer box that is not broken |
| `test-plain.tex` | pdflatex, lualatex, platex | documents without a box that flows: unchanged by the package |
| `test-footnote.tex` | pdflatex, xelatex, lualatex, platex, uplatex; with footnotenosplit | with tcbpagefootnote: footnotes of the outer box and of the boxes inside, three levels deep, also in a title |
| `test-tate.tex` | platex (tarticle), uplatex (utarticle), lualatex (ltjtarticle) | `test-basic.tex` and `test-footnote.tex` in tate, with pxpgftate for pLaTeX and upLaTeX |

`test-common.tex` holds the helpers shared by the tests.

## License

This package is licensed under the conditions of the [LaTeX Project Public License](https://www.latex-project.org/lppl.txt), either version 1.3c of this license or any later version.

Copyright (c) 2026 Munehiro Yamamoto
