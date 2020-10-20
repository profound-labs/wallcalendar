-- paths are relative to wallcalendar.cls
local csv = require("wallcalendar-csv.lua")
local date = require("wallcalendar-date.lua")
local tp = tex.print
local tsp = tex.sprint

function loadCsv(csv_path)
  local f = csv.open(csv_path, {separator = ";", header = true})
  local data = {}
  for fields in f:lines() do
    data[#data + 1] = fields
  end
  return data
end

function ok(x)
  return x ~= nil and x ~= ""
end

function isEqual(x, val)
  return x == val
end

function hasFootnote(event)
  return ok(event.footnote)
end

function hasSidenote(event)
  return ok(event.sidenote)
end

function monthNameToNum(monthName)
  local months = {january = 1, february = 2, march = 3, april = 4, may = 5, june = 6, july = 7, august = 8, september = 9, october = 10, november = 11, december = 12}
  return months[string.lower(monthName)]
end

function getMark(idx, events, markDefaults, isNote)
  local event = events[idx]
  local default_mark = {}
  default_mark.number = {}
  default_mark.day_text = {}
  default_mark.footnote = {}

  default_mark.number.symbol = idx
  default_mark.number.above_offset = "\\markNumberAbove"
  default_mark.number.right_offset = "\\markNumberRight"

  default_mark.day_text.symbol = idx
  default_mark.day_text.above_offset = "\\markDayTextAbove"
  default_mark.day_text.right_offset = "\\markDayTextRight"

  default_mark.footnote.symbol = idx
  default_mark.footnote.above_offset = "" -- placeholder, not used for note
  default_mark.footnote.right_offset = "" -- placeholder, not used for note

  local mark = {}

  for k,v in pairs(default_mark.number) do
    local m = {}
    local mark_key = ""
    local csv_key = ""

    if ok(isNote) then
      mark_key = "footnote"
    elseif ok(event.day_text) then
      mark_key = "day_text"
    else
      mark_key = "number"
    end

    m = default_mark[mark_key]
    csv_key = mark_key .. "_" .. k

    if not ok(markDefaults) or not ok(markDefaults[idx]) or not ok(markDefaults[idx][csv_key]) then
      mark[k] = m[k]
    else
      mark[k] = markDefaults[idx][csv_key]
    end
  end

  return mark
end

function getCombinedMark(idx, events, markDefaults, isNote)
  local event = events[idx]
  local mark = getMark(idx, events, markDefaults, isNote)

  mark.symbol = ""
  for i,e in pairs(events) do
    if e.date == event.date then
      local m = getMark(i, events, markDefaults, isNote)
      if mark.symbol == "" then
        mark.symbol = m.symbol
      else
        mark.symbol = mark.symbol .. "\\symbolSeparator " .. m.symbol
      end
    end
  end

  return mark
end

function collectEvents(byWhat, events, byValue, filterPred)
  local data = {}
  for idx,row in pairs(events) do
    d = date(row.date)

    if filterPred ~= nil then
      if byWhat == 'month' then
        if d:getmonth() == byValue and filterPred(row) then
          data[#data + 1] = row
        end
      elseif byWhat == 'year' then
        if d:getyear() == byValue and filterPred(row) then
          data[#data + 1] = row
        end
      end
    else
      if byWhat == 'month' then
        if d:getmonth() == byValue then
          data[#data + 1] = row
        end
      elseif byWhat == 'year' then
        if d:getyear() == byValue then
          data[#data + 1] = row
        end
      end
    end

  end
  return data
end

function eventsInMonth(events, month, filterPred)
  return collectEvents('month', events, month, filterPred)
end

function eventsInYear(events, year, filterPred)
  return collectEvents('year', events, year, filterPred)
end

function formatEvents(events, formatFunc, formatCmd, markDefaultsCsv, minEvents)
  if ok(minEvents) and #events < minEvents then
    d = minEvents - #events
    for i=0,d,1 do
      events[#events + 1] = {}
    end
  end

  local markDefaults = nil
  if ok(markDefaultsCsv) then
    markDefaults = loadCsv(markDefaultsCsv)
  end

  for idx,event in pairs(events) do
    local mark = {}
    local d = {}

    if ok(event.date) then
      -- don't use getCombinedMark here, events on the same day will be printed one after the other
      mark = getMark(idx, events, markDefaults, true)
      d = date(event.date)
    end

    if formatFunc then

      formatFunc(idx, #events, event, d, mark)

    else

      tsp("\\def\\eIdx{"..idx                            .."}") -- \def\eIdx{1}
      tsp("\\def\\eMaxIdx{"..#events                     .."}") -- \def\eMaxIdx{8}
      tsp("\\def\\eMark{"..mark.symbol                   .."}") -- \def\eMark{\kiteMark}
      tsp("\\def\\eIsoDate{"..event.date                 .."}") -- \def\eIsoDate{2018-01-12}
      tsp("\\def\\eYear{"..d:getyear()                   .."}") -- \def\eYear{2018}
      tsp("\\def\\eMonth{\\x"..d:fmt("%B")               .."}") -- \def\eMonth\xJanuary
      tsp("\\def\\eMonthShort{\\x"..d:fmt("%b").."Short" .."}") -- \def\eMonthShort\xJanShort
      tsp("\\def\\eDay{"..d:getday()                     .."}") -- \def\eDay{12}
      if ok(event.day_text) then
        tsp("\\def\\eDayText{"..event.day_text           .."}") -- \def\eDayText{\dejaVuSans\char"263C}
      else
        tsp("\\def\\eDayText{}")
      end
      if ok(event.footnote) then
        tsp("\\def\\eFootnote{"..event.footnote              .."}") -- \def\eFootnote{Anniversary Day}
      else
        tsp("\\def\\eFootnote{}")
      end
      if ok(event.sidenote) then
        tsp("\\def\\eSidenote{"..event.sidenote              .."}") -- \def\eSidenote{Anniversary Day}
      else
        tsp("\\def\\eSidenote{}")
      end

      tsp(formatCmd)

    end
  end
end

-- It's better to call it with the name of the month than its number because it
-- fits the wrapper commands better.
function monthEvents(monthName, filterPred, formatFunc, formatCmd, eventsCsv, markDefaultsCsv, minEvents)
  if not ok(eventsCsv) then
    return
  end
  local monthNum = monthNameToNum(monthName)
  local events = eventsInMonth(loadCsv(eventsCsv), monthNum, filterPred)

  formatEvents(events, formatFunc, formatCmd, markDefaultsCsv, minEvents)
end

function yearEvents(yearNum, filterPred, formatFunc, formatCmd, eventsCsv, markDefaultsCsv, minEvents)
  if not ok(eventsCsv) then
    return
  end
  local events = eventsInYear(loadCsv(eventsCsv), yearNum, filterPred)

  formatEvents(events, formatFunc, formatCmd, markDefaultsCsv, minEvents)
end

-- monthName is better for argument than monthNum
function monthMarksDayText(monthName, filterPred, eventsCsv)
  if not ok(eventsCsv) then
    return
  end
  local monthNum = monthNameToNum(monthName)
  local events = eventsInMonth(loadCsv(eventsCsv), monthNum, filterPred);

  for idx,event in pairs(events) do
    if ok(event.day_text) then
      tsp(string.format(" if (equals=%s) [day text={%s}, xshift=\\dayTextXshift, yshift=\\dayTextYshift] ", event.date, event.day_text))
    end
  end
end

function monthMarksDayTextInline(monthName, filterPred, eventsCsv)
  if not ok(eventsCsv) then
    return
  end
  local monthNum = monthNameToNum(monthName)
  local events = eventsInMonth(loadCsv(eventsCsv), monthNum, filterPred);

  for idx,event in pairs(events) do
    if ok(event.day_text) then

      local d = date(event.date)

      tsp(string.format(" \\draw node [above right=%s and %s of cal%s-%s.north west, anchor=north west] {%s}; ",
                        "0.5pt",
                        "20pt",
                        d:fmt("%m"),
                        event.date,
                        event.day_text))

    end
  end
end

function yearMarksDayText(yearNum, filterPred, eventsCsv)
  if not ok(eventsCsv) then
    return
  end
  local events = eventsInYear(loadCsv(eventsCsv), yearNum, filterPred);

  for idx,event in pairs(events) do
    if ok(event.day_text) then
      tsp(string.format(" if (equals=%s) [day text={%s}, xshift=\\dayTextXshift, yshift=\\dayTextYshift] ", event.date, event.day_text))
    end
  end
end

function drawAnnotations(yearNum, filterPred, eventsCsv)
  if not ok(eventsCsv) then
    return
  end
  local events = eventsInYear(loadCsv(eventsCsv), yearNum, filterPred);

  for idx,event in pairs(events) do
    if ok(event.annotation) then
      if ok(event.annotation_color) then
        tsp(string.format("%s[%s]{%s}", event.annotation, event.annotation_color, event.date))
      else
        tsp(string.format("%s{%s}", event.annotation, event.date))
      end
    end
    if ok(event.date_end) and ok(event.annotation_end) then
      if ok(event.annotation_color) then
        tsp(string.format("%s[%s]{%s}", event.annotation_end, event.annotation_color, event.date_end))
      else
        tsp(string.format("%s{%s}", event.annotation_end, event.date_end))
      end
    end
  end
end

function plannerWeeklyNotes(yearNum, filterPred, eventsCsv)
  if not ok(eventsCsv) then
    return
  end
  local events = eventsInYear(loadCsv(eventsCsv), yearNum, filterPred);

  local week = 1
  while week <= 53 do
    for idx,event in pairs(events) do
      d = date(event.date)
      w = d:getisoweeknumber()
      if week == w and ok(event.sidenote) then
        if ok(event.date_end) then
          de = date(event.date_end)
          m = d:getmonth()
          me = de:getmonth()
          if m == me then
            tsp(string.format("\\weeklyNoteFmt{%s}{%s}{%s}", event.annotation_color, d:fmt("%b").." "..d:getday().."--"..de:getday(), event.sidenote))
          else
            tsp(string.format("\\weeklyNoteFmt{%s}{%s}{%s}", event.annotation_color, d:fmt("%b").." "..d:getday().." -- "..de:fmt("%b").." "..de:getday(), event.sidenote))
          end
        else
          tsp(string.format("\\weeklyNoteFmt{%s}{%s}{%s}", event.annotation_color, d:fmt("%b").." "..d:getday(), event.sidenote))
        end
      end
    end
    tsp("\\mbox{}\\par ")

    week = week + 1
  end
end

function plannerWeeklyImages(yearNum, filterPred, eventsCsv)
  if not ok(eventsCsv) then
    return
  end
  local events = eventsInYear(loadCsv(eventsCsv), yearNum, filterPred);

  local week = 1
  while week <= 53 do
    for idx,event in pairs(events) do
      w = d:getisoweeknumber()
      if week == w and ok(event.image) then
        if ok(event.image_options) then
          tsp(string.format("\\weeklyImageFmt[%s]{%s}", event.image_options, event.image))
        else
          tsp(string.format("\\weeklyImageFmt{%s}", event.image))
        end
      end
    end
    tsp("\\mbox{}\\par ")

    week = week + 1
  end
end

function formatMarksNote(events, filterPred, markDefaultsCsv, isOneCalendar)
  local markDefaults = nil
  if ok(markDefaultsCsv) then
    markDefaults = loadCsv(markDefaultsCsv)
  end

  local alreadyMarkedDates = {}

  for idx,event in pairs(events) do
    if ok(event.footnote) and alreadyMarkedDates[event.date] == nil then
      alreadyMarkedDates[event.date] = true
      local d = date(event.date)

      local mark = getCombinedMark(idx, events, markDefaults)

      if ok(isOneCalendar) and isOneCalendar == true then
        tsp(string.format(" \\draw node [above right=%s and %s of cal-%s.north east] {\\monthMarkFmt %s}; ",
                          mark.above_offset,
                          mark.right_offset,
                          event.date,
                          mark.symbol))
      else
        tsp(string.format(" \\draw node [above right=%s and %s of cal%s-%s.north east] {\\monthMarkFmt %s}; ",
                          mark.above_offset,
                          mark.right_offset,
                          d:fmt("%m"),
                          event.date,
                          mark.symbol))
      end
    end
  end
end

function formatInlineNotes(events, filterPred, markDefaultsCsv)
  local markDefaults = nil
  if ok(markDefaultsCsv) then
    markDefaults = loadCsv(markDefaultsCsv)
  end

  local alreadyMarkedDates = {}

  for idx,event in pairs(events) do
    if ok(event.footnote) and alreadyMarkedDates[event.date] == nil then
      alreadyMarkedDates[event.date] = true
      local d = date(event.date)

      tsp(string.format(" \\draw node [above right=0pt and 0pt of cal%s-%s.north west, anchor=north west] {\\begin{minipage}[t][\\@t@calendar@dayYshift - 10pt][b]{\\@t@calendar@dayXshift - 8pt}\\eventsFmt %s\\end{minipage}}; ",
                        d:fmt("%m"),
                        event.date,
                        event.footnote))
    end
  end
end

-- monthName is better for argument than monthNum
function monthMarksNote(monthName, filterPred, eventsCsv, markDefaultsCsv)
  if not ok(eventsCsv) then
    return
  end
  local monthNum = monthNameToNum(monthName)

  if not ok(filterPred) then
    filterPred = function(e) return ok(e.footnote) end
  end

  local events = eventsInMonth(loadCsv(eventsCsv), monthNum, filterPred);

  formatMarksNote(events, filterPred, markDefaultsCsv, false)
end

-- monthName is better for argument than monthNum
function monthInlineNotes(monthName, filterPred, eventsCsv, markDefaultsCsv)
  if not ok(eventsCsv) then
    return
  end
  local monthNum = monthNameToNum(monthName)

  if not ok(filterPred) then
    filterPred = function(e) return ok(e.footnote) end
  end

  local events = eventsInMonth(loadCsv(eventsCsv), monthNum, filterPred);

  formatInlineNotes(events, filterPred, markDefaultsCsv)
end

function yearMarksNote(yearNum, filterPred, eventsCsv, markDefaultsCsv, isOneCalendar)
  if not ok(eventsCsv) then
    return
  end
  if not ok(filterPred) then
    filterPred = function(e) return ok(e.footnote) end
  end

  local events = eventsInYear(loadCsv(eventsCsv), yearNum, filterPred);

  formatMarksNote(events, filterPred, markDefaultsCsv, isOneCalendar)
end
