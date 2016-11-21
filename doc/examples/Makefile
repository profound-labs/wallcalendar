LATEX=lualatex
LATEX_OPTS=-interaction=nonstopmode -halt-on-error

all: calendars bursts

test: ./diff-cal.sh

calendars: cal-plain cal-showtrims cal-showframe cal-varnishmask cal-translations cal-marks cal-year-planner cal-thumbnails

bursts: cal-plain-burst cal-showtrims-burst cal-showframe-burst cal-varnishmask-burst

cal-plain:
	$(LATEX) $(LATEX_OPTS) cal-plain.tex

cal-plain-burst:
	pdftk cal-plain.pdf burst output ./cal-burst/cal-plain-%02d.pdf

cal-showtrims:
	$(LATEX) $(LATEX_OPTS) cal-showtrims.tex

cal-showtrims-burst:
	pdftk cal-showtrims.pdf burst output ./cal-burst/cal-showtrims-%02d.pdf

cal-showframe:
	$(LATEX) $(LATEX_OPTS) cal-showframe.tex

cal-showframe-burst:
	pdftk cal-showframe.pdf burst output ./cal-burst/cal-showframe-%02d.pdf

cal-varnishmask:
	$(LATEX) $(LATEX_OPTS) cal-varnishmask.tex

cal-varnishmask-burst:
	pdftk cal-varnishmask.pdf burst output ./cal-burst/cal-varnishmask-%02d.pdf

cal-translations-japanese:
	$(LATEX) $(LATEX_OPTS) cal-translations-japanese.tex

cal-translations-english:
	$(LATEX) $(LATEX_OPTS) cal-translations-english.tex

cal-translations-hungarian:
	$(LATEX) $(LATEX_OPTS) cal-translations-hungarian.tex

cal-translations: cal-translations-japanese cal-translations-english cal-translations-hungarian

cal-marks:
	$(LATEX) $(LATEX_OPTS) cal-marks.tex

cal-year-planner:
	$(LATEX) $(LATEX_OPTS) cal-year-planner.tex

cal-thumbnails:
	$(LATEX) $(LATEX_OPTS) cal-thumbnails.tex

# For developing snippets in isolation.
mwe:
	$(LATEX) $(LATEX_OPTS) mwe.tex

clean:
	rm -v *.dvi *.ps *.aux *.log *.bbl *.blg *.bcf *.toc
