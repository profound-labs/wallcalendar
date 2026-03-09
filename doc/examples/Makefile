LATEX=lualatex
LATEX_OPTS=-interaction=nonstopmode -halt-on-error

all:
	@echo "Are you sure? Making them all is a lot of work."

#all: calendars bursts

test: ./diff-cal.py

calendars: cal-translations cal-plain.pdf cal-photo-and-notes-sunday.pdf cal-showtrims.pdf cal-showframe.pdf cal-varnishmask.pdf cal-marks.pdf cal-photo-and-notes.pdf cal-year-planner.pdf cal-year-planner-rows.pdf cal-year-planner-grid.pdf cal-year-planner-compact.pdf cal-thumbnails.pdf cal-four-row-february.pdf cal-four-row-february-leapyear.pdf

bursts: cal-plain-burst cal-photo-and-notes-sunday-burst cal-showtrims-burst cal-showframe-burst cal-varnishmask-burst cal-no-photos-burst cal-photo-and-notes-burst cal-four-row-february-burst cal-four-row-february-leapyear-burst

jpg: cal-marks.jpg

%.jpg: %.pdf
	./jpg-to-pdf.sh $<

%.pdf: %.tex
	$(LATEX) $(LATEX_OPTS) $<

cal-plain-burst:
	pdftk cal-plain.pdf burst output ./cal-burst/cal-plain-%02d.pdf

cal-photo-and-notes-sunday-burst:
	pdftk cal-photo-and-notes-sunday.pdf burst output ./cal-burst/cal-photo-and-notes-sunday-%02d.pdf

cal-showtrims-burst:
	pdftk cal-showtrims.pdf burst output ./cal-burst/cal-showtrims-%02d.pdf

cal-showframe-burst:
	pdftk cal-showframe.pdf burst output ./cal-burst/cal-showframe-%02d.pdf

cal-varnishmask-burst:
	pdftk cal-varnishmask.pdf burst output ./cal-burst/cal-varnishmask-%02d.pdf

cal-no-photos-burst:
	pdftk cal-no-photos.pdf burst output ./cal-burst/cal-no-photos-%02d.pdf

cal-photo-and-notes-burst:
	pdftk cal-photo-and-notes.pdf burst output ./cal-burst/cal-photo-and-notes-%02d.pdf

cal-four-row-february-burst:
	pdftk cal-four-row-february.pdf burst output ./cal-burst/cal-four-row-february-%02d.pdf

cal-four-row-february-leapyear-burst:
	pdftk cal-four-row-february-leapyear.pdf burst output ./cal-burst/cal-four-row-february-leapyear-%02d.pdf

cal-translations: cal-translations-japanese.pdf cal-translations-english.pdf cal-translations-hungarian.pdf

# For developing snippets in isolation.
mwe:
	$(LATEX) $(LATEX_OPTS) mwe.tex

clean:
	rm -v *.dvi *.ps *.aux *.log *.bbl *.blg *.bcf *.toc
