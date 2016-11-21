LATEX=lualatex
LATEX_OPTS=-shell-escape -interaction=nonstopmode -halt-on-error

all: wallcalendar wallcalendar-code

wallcalendar:
	$(LATEX) $(LATEX_OPTS) wallcalendar.tex

wallcalendar-code:
	$(LATEX) $(LATEX_OPTS) wallcalendar-code.tex

clean:
	rm -v *.dvi *.ps *.aux *.log *.bbl *.blg *.bcf *.toc
