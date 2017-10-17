DIST_FILES=wallcalendar.cls wallcalendar-csv.lua wallcalendar-date.lua wallcalendar-helpers.lua wallcalendar.pdf wallcalendar-code.pdf README.md LICENSE.txt wallcalendar-layouts.png i18n/

all:
	echo "huh?"

local-install: ctan
	@./helpers/local-install.sh wallcalendar.zip

ctan:
	@zip -r -q -X -ll wallcalendar.zip $(DIST_FILES) -x i18n/auto/ i18n/auto/*
