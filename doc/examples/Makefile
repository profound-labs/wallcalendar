LATEX=lualatex
LATEX_OPTS=-interaction=nonstopmode -halt-on-error

all:
	@echo "Are you sure? Making them all is a lot of work."

#all: calendars bursts

test: ./diff-cal.sh

calendars: cal-plain.pdf cal-showtrims.pdf cal-showframe.pdf cal-varnishmask.pdf cal-translations cal-marks.pdf cal-photo-and-notes.pdf cal-year-planner.pdf cal-thumbnails.pdf

bursts: cal-plain-burst cal-showtrims-burst cal-showframe-burst cal-varnishmask-burst

%.pdf: %.tex
	$(LATEX) $(LATEX_OPTS) $<

cal-plain-burst:
	pdftk cal-plain.pdf burst output ./cal-burst/cal-plain-%02d.pdf

cal-showtrims-burst:
	pdftk cal-showtrims.pdf burst output ./cal-burst/cal-showtrims-%02d.pdf

cal-showframe-burst:
	pdftk cal-showframe.pdf burst output ./cal-burst/cal-showframe-%02d.pdf

cal-varnishmask-burst:
	pdftk cal-varnishmask.pdf burst output ./cal-burst/cal-varnishmask-%02d.pdf

cal-translations: cal-translations-japanese.pdf cal-translations-english.pdf cal-translations-hungarian.pdf

# For developing snippets in isolation.
mwe:
	$(LATEX) $(LATEX_OPTS) mwe.tex

clean:
	rm -v *.dvi *.ps *.aux *.log *.bbl *.blg *.bcf *.toc
