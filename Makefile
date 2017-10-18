all:
	echo "huh?"

local-install: ctan
	@./helpers/local-install.sh wallcalendar.zip

ctan:
	@./helpers/ctan.sh
