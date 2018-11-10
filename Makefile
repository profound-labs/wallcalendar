all:
	echo "huh?"

local-install: ctan
	@./helpers/local-install.sh wallcalendar.zip

ctan:
	@./helpers/ctan.sh

tangle-code:
	cd doc && emacs --batch -L -l 'wallcalendar-code.org' --eval "(require 'org)" --eval '(org-babel-tangle "wallcalendar-code.org")'

export-code:
	cd doc && emacs --batch -L -l 'wallcalendar-code.org' -l 'export-init.el' --eval '(org-latex-export-to-latex)'

export-manual:
	cd doc && emacs --batch -L -l 'wallcalendar.org' -l 'export-init.el' --eval '(org-latex-export-to-latex)'

wallcalendar.cls: tangle-code

wallcalendar.pdf: export-manual
	cd doc && latexmk wallcalendar.tex

wallcalendar-code.pdf: export-code
	cd doc && latexmk wallcalendar-code.tex

dist: wallcalendar.cls wallcalendar.pdf wallcalendar-code.pdf
	cd doc && cp wallcalendar.pdf .. && cp wallcalendar-code.pdf ..

