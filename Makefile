all:
	echo "huh?"

local-install: ctan
	@./helpers/local-install.sh wallcalendar.zip

ctan:
	@./helpers/ctan.sh

export-manual:
	cd doc && emacs --batch -L -l 'wallcalendar.org' -l 'export-init.el' --eval '(org-latex-export-to-latex)'

wallcalendar.cls: tangle-code

wallcalendar.pdf: export-manual
	cd doc && latexmk wallcalendar.tex

dist: wallcalendar.cls wallcalendar.pdf
	cp doc/wallcalendar.pdf .
