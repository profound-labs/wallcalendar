% wallcalendar.cls
%
% NOTE Don't edit this file directly. Edit doc/wallcalendar-code.org with emacs
% org-mode and run 'make wallcalendar.cls'.
%
% Wall Calendar
%
% A wall calendar document class with custom layouts and support for internationalization.
%
% (c) Gambhiro Bhikkhu, 2026
% Contact: https://gambhiro.github.io
%
% LPPL LaTeX Public Project License

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{wallcalendar}[2026/03/06 v1.6.0 A wall calendar document class with custom layouts and support for internationalization.]

\RequirePackage{pgfopts}
\RequirePackage{calc}

\newlength\calPaperWidth
\newlength\calPaperHeight
\newlength\calTextWidth
\newlength\calTextHeight
\newlength\@wall@leftMargin
\newlength\@wall@rightMargin
\newlength\@wall@topMargin
\newlength\@wall@bottomMargin
\newlength\@wall@trimSpace

\def\@wall@eventsCsv{}
\def\@wall@moonsCsv{}
\def\@wall@dateAnnotationsStr{}
\def\@wall@markDefaultsCsv{}
\def\@wall@translationsInputFile{}

\newcommand*\theMonthName{}

\newif\ifvarnishmask
\newif\ifshowframe
\newif\iftranslationsAutoload
\newif\ifloadBabel
\newif\ifgridSurround
\newif\ifsundayFirst

\pgfkeys{
  /wall/.is family, /wall,
  defaults/.style = {
    year = \the\year,
    altyear = \empty,
    loadBabel = false,
    language = english,
    translationsAutoload = true,
    dateAnnotations = true,
    imageFolder = {./src-images},
    choralOctavoPaper,
    hMargin = 17mm,
    topMargin = 20.5mm,
    bottomMargin = 10mm,
    trimSpace = 35mm,
  },
  year/.store in = \CalendarYear,
  year/.initial = \the\year,
  altyear/.store in = \CalendarAltYear,
  altyear/.initial = \empty,
  language/.store in = \@wall@calendarLanguage,
  loadBabel/.is if = loadBabel,
  translationsInputFile/.store in = \@wall@translationsInputFile,
  translationsInputFile/.initial = {},
  translationsAutoload/.is if = translationsAutoload,
  eventsCsv/.store in = \@wall@eventsCsv,
  eventsCsv/.initial = {},
  moonsCsv/.store in = \@wall@moonsCsv,
  moonsCsv/.initial = {},
  markDefaultsCsv/.store in = \@wall@markDefaultsCsv,
  markDefaultsCsv/.initial = {},
  varnishmask/.is if = varnishmask,
  showframe/.is if = showframe,
  gridSurround/.is if = gridSurround,
  sundayFirst/.is if = sundayFirst,
  dateAnnotations/.store in = \@wall@dateAnnotationsStr,
  dateAnnotations/.initial = true,
  imageFolder/.store in = \@wall@imageFolder,
  paperWidth/.code = {\setlength{\calPaperWidth}{#1}},
  paperHeight/.code = {\setlength{\calPaperHeight}{#1}},
  hMargin/.code = {\setlength{\@wall@leftMargin}{#1}%
                   \setlength{\@wall@rightMargin}{#1}},
  leftMargin/.code = {\setlength{\@wall@leftMargin}{#1}},
  rightMargin/.code = {\setlength{\@wall@rightMargin}{#1}},
  topMargin/.code = {\setlength{\@wall@topMargin}{#1}},
  bottomMargin/.code = {\setlength{\@wall@bottomMargin}{#1}},
  trimSpace/.code = {\setlength{\@wall@trimSpace}{#1}},
  % Paper sizes
  choralOctavoPaper/.style = {paperWidth = 6.75in, paperHeight = 10.5in},
  a2Paper/.style = {paperWidth = 420mm, paperHeight = 594mm},
  a2PaperLandscape/.style = {paperWidth = 594mm, paperHeight = 420mm},
  a3Paper/.style = {paperWidth = 297mm, paperHeight = 420mm},
  a3PaperLandscape/.style = {paperWidth = 420mm, paperHeight = 297mm},
  a4Paper/.style = {paperWidth = 210mm, paperHeight = 297mm},
  a4PaperLandscape/.style = {paperWidth = 297mm, paperHeight = 210mm},
  a5Paper/.style = {paperWidth = 148mm, paperHeight = 210mm},% r = 1.4142 = sqrt(2)
  prevPaper/.style = {paperWidth = 170mm, paperHeight = 250mm},% r = 1.4705
}

% Debug with: \wlog{YEA: \the\@wall@bottomMargin}

\DeclareOption*{%
  \PassOptionsToClass{\CurrentOption}{memoir}
}

\pgfkeys{/wall, defaults}
\ProcessPgfOptions{/wall}
\ProcessOptions\relax

% Set the week list style based on sundayFirst option.
% This macro is used in TikZ style definitions to avoid TeX conditional nesting issues.
\ifsundayFirst
  \def\@wall@weekListStyle{week list sunday}
\else
  \def\@wall@weekListStyle{week list}
\fi

\LoadClass[11pt,oneside]{memoir}

\newlength\@tmp@a
\newlength\@tmp@b
\newlength\@tmp@c
\newlength\@tmp@z
\newlength\@tmp@width
\newlength\@tmp@height

\ifloadBabel
\RequirePackage[\@wall@calendarLanguage]{babel}
\fi

\RequirePackage{nag}
% Don't use [cmyk] option on xcolor. Declare text colors either in gray or cmyk (for color).
\RequirePackage{xcolor}
\RequirePackage{graphicx}
\DeclareGraphicsExtensions{.pdf,.png,.jpg}
\graphicspath{{\@wall@imageFolder}}

\RequirePackage{xparse}
\RequirePackage{soul}
\RequirePackage{eso-pic}
\RequirePackage{ccicons}
\RequirePackage{multicol}
\RequirePackage{wasysym}

\RequirePackage{pdftexcmds}
\RequirePackage{etoolbox}
\RequirePackage{luacode}

\RequirePackage{xcoffins}
%\RequirePackage{xstring}
%\RequirePackage{stringstrings}

\ifloadBabel
\RequirePackage[final,babel=true]{microtype}
\else
\RequirePackage[final]{microtype}
\fi

\RequirePackage{tikz}
\usetikzlibrary{calendar}
\usetikzlibrary{positioning}
\usetikzlibrary{fit}
\usetikzlibrary{shapes.geometric}

% http://tex.stackexchange.com/a/20426/831
\pgfdeclarelayer{one}
\pgfdeclarelayer{two}
\pgfsetlayers{main,one,two}

\pgfkeys{%
  /tikz/on layer/.code={
    \pgfonlayer{#1}\begingroup
    \aftergroup\endpgfonlayer
    \aftergroup\endgroup
  }
}

\definecolor{textbody}{gray}{0}

% pantone 1245C, RGB 191,145,12 HEX: #BF910C
% pantone 1255C, CMYK 0,27.5,100,34
\definecolor{gold}{cmyk}{0,0.275,1,0.34}
\definecolor{darkgold}{cmyk}{0.27,0.53,1,0.09}
%\definecolor{orangegold}{cmyk}{0,0.31,0.89,0}
\colorlet{orangegold}{darkgold}

\colorlet{month}{darkgold}
\colorlet{gridcolor}{black!30}
\colorlet{weekday}{black}
\colorlet{weekend}{black!50}
\colorlet{mooncolor}{textbody}
  
\definecolor{sunday}{RGB}{255,0,0}

\definecolor{datenum}{gray}{0.3}
\definecolor{plannerdatenum}{gray}{0}
\definecolor{quote}{gray}{0.3}
\definecolor{notes}{gray}{0.3}

\definecolor{gridcolor}{gray}{0.5}
\colorlet{pagebgcolor}{gridcolor!60}

\colorlet{photo-frame}{blue}
\colorlet{quote-frame}{red}
\colorlet{heading-frame}{brown}
\colorlet{calendar-frame}{orange}
\colorlet{events-frame}{green}

\ifshowframe
  \colorlet{calendarbg}{black!50}
\else
  \colorlet{calendarbg}{white}
\fi

\ifshowtrims
  \setstocksize{\calPaperHeight + \@wall@trimSpace}{\calPaperWidth + \@wall@trimSpace}
  \setlength{\paperheight}{\calPaperHeight}
  \setlength{\paperwidth}{\calPaperWidth}
  \trimXmarks
  \trimLmarks
  \quarkmarks
  \settrims{0.5\stockheight - 0.5\paperheight}{0.5\stockwidth - 0.5\paperwidth}
  \settrimmedsize{\calPaperHeight}{\calPaperWidth}{*}
\else\relax
  \setstocksize{\calPaperHeight}{\calPaperWidth}
  \settrims{0pt}{0pt}
  \settrimmedsize{\stockheight}{\stockwidth}{*}
\fi

%\settypeblocksize{\stockheight}{\stockwidth}{*}
% TODO: calculate margins by ratios to paper size
\setlrmarginsandblock{\@wall@leftMargin}{\@wall@rightMargin}{*}
\setulmarginsandblock{\@wall@topMargin}{\@wall@bottomMargin}{*}
\setheadfoot{0pt}{0pt}
\setheaderspaces{0pt}{*}{*}

\checkandfixthelayout% This will typeout values in pt.
\settypeoutlayoutunit{mm}% It is useful to see layout values in mm too.
\typeoutlayout
 
\setlength{\calTextWidth}{\calPaperWidth - \@wall@leftMargin - \@wall@rightMargin}
\setlength{\calTextHeight}{\calPaperHeight - \@wall@topMargin - \@wall@bottomMargin}

\def\@wall@fontSize{11}
\def\@wall@lineHeight{13.6}

\renewcommand{\normalsize}{%
  \@setfontsize\normalsize\@wall@fontSize\@wall@lineHeight
  \abovedisplayskip 11\p@ \@plus3\p@ \@minus6\p@
  \abovedisplayshortskip \z@ \@plus3\p@
  \belowdisplayshortskip 6.5\p@ \@plus3.5\p@ \@minus3\p@
  \belowdisplayskip \abovedisplayskip
  \color{textbody}
  \let\@listi\@listI}
\normalsize

\setlength{\vgap}{1.5em}
\setlength{\vindent}{\vgap}
\setlength{\vleftmargin}{2em}

\setlength{\parskip}{0pt}
\setlength{\parindent}{0pt}

\setlength{\fboxsep}{0pt}

\definecolor{varnishmask}{gray}{0}

% http://tex.stackexchange.com/a/59571/831
\newcommand*{\strcmpblank}[3]{%
  \ifnum\pdf@strcmp{#1}{}=\z@ #2\else #3\fi
}

\newcommand\@placeholder@pre[1]{%
  \settowidth{\@tmp@width}{#1}%
  \settototalheight{\@tmp@height}{#1}%
  \def\@spacer{\rule{\@tmp@width}{0pt}\rule{0pt}{\@tmp@height}}%
}

\newcommand\placeholder[3][]{%
  \ifvarnishmask%
    \ifstrequal{#2}{hasvarnish}{%
      \@placeholder@pre{#3}%
      \tikz\node[fill=varnishmask, inner sep=0pt]{\@spacer};%
    }{}%
  \else%
    \ifshowframe%
      \@placeholder@pre{#3}%
      \tikz\node[inner sep=0pt, opacity=0.6, #1]{\@spacer};%
    \else%
      #3%
    \fi%
  \fi%
}

\newif\ifsixrowsmonth
\sixrowsmonthfalse

\newif\iffourrowsmonth
\fourrowsmonthfalse

\pgfkeys{/pgf/calendar/six rows month/.code={%
  % Monday-first: new week starts on Monday (weekday 0).
  % Sunday-first: new week starts on Sunday (weekday 6).
  \ifsundayFirst
    \ifnum\pgfcalendarifdateday=30\relax
      % Sunday (start of new week in Sunday-first)
      \ifnum\pgfcalendarifdateweekday=6\relax
        \pgfcalendarmatchestrue
      \fi
    \else
      \ifnum\pgfcalendarifdateday=31\relax
        % Sunday
        \ifnum\pgfcalendarifdateweekday=6\relax
          \pgfcalendarmatchestrue
        \fi
        % Monday (day 30 was Sunday = new row, day 31 is Monday)
        \ifnum\pgfcalendarifdateweekday=0\relax
          \pgfcalendarmatchestrue
        \fi
      \fi
    \fi
  \else
    \ifnum\pgfcalendarifdateday=30\relax
      % Monday
      \ifnum\pgfcalendarifdateweekday=0\relax
        \pgfcalendarmatchestrue
      \fi
    \else
      \ifnum\pgfcalendarifdateday=31\relax
        % Monday
        \ifnum\pgfcalendarifdateweekday=0\relax
          \pgfcalendarmatchestrue
        \fi
        % Tuesday
        \ifnum\pgfcalendarifdateweekday=1\relax
          \pgfcalendarmatchestrue
        \fi
      \fi
    \fi
  \fi%
}}

% Four rows month: February with exactly 28 days where the 1st falls on the
% week-start day (Monday for monday-first, Sunday for sunday-first).
% We detect this by checking if day 28 falls on the last column of the week.
\pgfkeys{/pgf/calendar/four rows month/.code={%
  \ifnum\pgfcalendarifdateday=28\relax
    \ifsundayFirst
      % Sunday-first: last column is Saturday (weekday 5)
      \ifnum\pgfcalendarifdateweekday=5\relax
        \pgfcalendarmatchestrue
      \fi
    \else
      % Monday-first: last column is Sunday (weekday 6)
      \ifnum\pgfcalendarifdateweekday=6\relax
        \pgfcalendarmatchestrue
      \fi
    \fi
  \fi%
}}

\def\@wall@photo@putPhoto#1{#1}
\def\@wall@photo@setYOffset{}

\pgfkeys{
  /put photo/.is family, /put photo,
  simple/.code = {%
    \def\@wall@photo@putPhoto##1{%
      \includegraphics{##1}%
    }%
    \def\@wall@photo@setYOffset{}%
  },
  full page/.code = {%
    \def\@wall@photo@putPhoto##1{%
      \includegraphics[%
        keepaspectratio,%
        width={\calPaperWidth + 2\@t@bleed},%
      ]{##1}%
    }%
    \def\@wall@photo@setYOffset{}%
  },
  full width above calendar/.code = {%
    \def\@wall@photo@putPhoto##1{%
      \includegraphics[%
        keepaspectratio,%
        width={\calPaperWidth + 2\@t@bleed},%
      ]{##1}%
    }%
    \def\@wall@photo@setYOffset{%
      \setlength{\@t@yOffset}{\@t@calendar@height + \@t@bleed + 1pt}%
    }%
  },
  full width/.code = {%
    \def\@wall@photo@putPhoto##1{%
      \includegraphics[%
        keepaspectratio,%
        width={\calPaperWidth + 2\@t@bleed},%
      ]{##1}%
    }%
    \def\@wall@photo@setYOffset{%
      \setlength{\@t@yOffset}{\@t@calendar@height + \@t@bleed}%
    }%
  },
  left/.code = {%
    \def\@wall@photo@putPhoto##1{%
      \begin{minipage}[t][\height][b]{\calPaperWidth + 6mm}%
        \raggedright
        
        \placeholder[fill=photo-frame]{hasvarnish}{%
          \includegraphics[width=0.66\calPaperWidth + 3mm]{##1}%
        }%

        \vfill\mbox{}%
      \end{minipage}%
    }%
    \def\@wall@photo@setYOffset{}%
  },
  right/.code = {%
    \def\@wall@photo@putPhoto##1{%
      \begin{minipage}[t][\height][b]{\calPaperWidth + 6mm}%
        \raggedleft
        
        \placeholder[fill=photo-frame]{hasvarnish}{%
          \includegraphics[width=0.66\calPaperWidth + 3mm]{##1}%
        }%

        \vfill\mbox{}%
      \end{minipage}%
    }%
    \def\@wall@photo@setYOffset{}%
  },
}

\def\@wall@quote@putQuote#1{#1}

\pgfkeys{
  /put quote/.is family, /put quote,
  simple/.code = {%
    \def\@wall@quote@putQuote##1{%
      ##1%
    }%
  },
  left/.code = {%
    \def\@wall@quote@putQuote##1{%
      \begin{minipage}[b][0.5\calPaperHeight][t]{\calPaperWidth + 6mm}%
        \raggedright%
        \mbox{}\vfill%
        
        \hspace*{8mm}%
        \begin{minipage}{0.33\calPaperWidth - 10mm}%
          \raggedleft%
          \quoteFmt%
          ##1%
        \end{minipage}%
      \end{minipage}%
    }%
  },
  right/.code = {%
    \def\@wall@quote@putQuote##1{%
      \begin{minipage}[b][0.5\calPaperHeight][t]{\calPaperWidth + 6mm}%
        \raggedleft%
        \mbox{}\vfill%

        \begin{minipage}{0.33\calPaperWidth - 10mm}%
          \raggedright%
          \quoteFmt%
          ##1%
        \end{minipage}%
        \hspace*{8mm}%
      \end{minipage}%
    }%
  },
}

\newif\ifPhotoEnabled
\PhotoEnabledtrue

\pgfkeys{
  /Photo/.is family, /Photo,
  init/.style = {
    defaults/.style = {disabled = false, file = {}, thumbFile = {}, caption = {}, bleed = 0pt, xOffset=0pt, yOffset=0pt},
    disabled/.initial = false,
    file/.initial = {},
    thumbFile/.initial = {},
    caption/.initial = {},
    bleed/.initial = 0pt,
    xOffset/.initial = 0pt,
    yOffset/.initial = 0pt,
  },
}

\pgfkeys{
  /Quote/.is family, /Quote,
  init/.style = {
    defaults/.style = {position=center, text={}, xOffset=0pt, yOffset=0pt},
    position/.initial = {},
    text/.initial = {},
    xOffset/.initial = 0pt,
    yOffset/.initial = 0pt,
  },
}

\pgfkeys{
  /Calendar/.is family, /Calendar,
  init/.style = {
    defaults/.style = {bg/.style={opacity=0.5}},
    bg/.style = {},
    minimum height/.initial = {},
  },
}

\pgfkeys{
  /Events/.is family, /Events,
  init/.style = {
    defaults/.style = {day code = {}, marks = {}, text = {}},
    day code/.initial = {},
    marks/.initial = {},
    text/.initial = {},
  },
}

\pgfkeys{
  /Txt/.is family, /Txt,
  init/.style = {
    defaults/.style = {text = {}},
    text/.initial = {},
  },
}

\def\eIdx{}
\def\eMaxIdx{}
\def\eMark{}
\def\eIsoDate{}
\def\eYear{}
\def\eMonth{}
\def\eMonthShort{}
\def\eDay{}
\def\eDayText{}
\def\eFootnote{}
\def\eSidenote{}

\pgfkeys{
  /parseMonthEvents/.is family, /parseMonthEvents,
  month/.initial = {},
  filter pred/.initial = nil,
  format func/.initial = nil,
  format cmd/.initial = {},
  events csv/.initial = {},
  mark defaults csv/.initial = {},
  min events/.initial = {},
  defaults/.style = {
    month = \theMonthName,
    filter pred = nil,
    format func = nil,
    format cmd = {\textsuperscript{\eIdx}~\eMonthShort~\eDay:~\eFootnote\par},
    events csv = \@wall@eventsCsv,
    mark defaults csv = \@wall@markDefaultsCsv,
    min events = nil,
  },
}

\pgfkeys{
  /parseYearEvents/.is family, /parseYearEvents,
  year/.initial = {},
  filter pred/.initial = nil,
  format func/.initial = nil,
  format cmd/.initial = {},
  events csv/.initial = {},
  mark defaults csv/.initial = {},
  min events/.initial = {},
  defaults/.style = {
    year = \CalendarYear,
    filter pred = nil,
    format func = nil,
    format cmd = {\textsuperscript{\eIdx}~\eMonthShort~\eDay:~\eFootnote\ifnumless{\eIdx}{\eMaxIdx}{,\space}{.}},
    events csv = \@wall@eventsCsv,
    mark defaults csv = \@wall@markDefaultsCsv,
    min events = nil,
  },
}

\newcommand\StarMark{*}

\newcommand\NoteStarMark{*}

\newlength\@wall@starHeight

% Measure the star's height here, so that we are measuring with the current typeface.
\newcommand\KiteMark{%
\setlength{\@wall@starHeight}{\totalheightof{*}}%
\begin{tikzpicture}
  \node (box) [
    rectangle, minimum height=\@wall@starHeight, minimum width=3.4pt,
    inner sep=0pt, line width=0pt,
  ] {};
  \node[
    kite, draw, textbody, fill=textbody,
    scale=0.15, kite vertex angles=60,
    above=0pt of box.north, anchor=north,
  ] {};%
\end{tikzpicture}%
}

% Same as \KiteMark but with scale=0.2
\newcommand\NoteKiteMark{\raisebox{1pt}{%
\setlength{\@wall@starHeight}{\totalheightof{*}}%
\begin{tikzpicture}
  \node (box) [
    rectangle, minimum height=\@wall@starHeight, minimum width=3.4pt,
    inner sep=0pt, line width=0pt,
  ] {};
  \node[
    kite, draw, textbody, fill=textbody,
    scale=0.2, kite vertex angles=60,
    above=0pt of box.north, anchor=north,
  ] {};%
\end{tikzpicture}%
}}

\tikzstyle{moon circle}=[
  circle,
  inner sep=0pt,
  line width=0pt,
  minimum height=8pt,
]

\newlength\@wall@moonRaise
\setlength{\@wall@moonRaise}{-0.7pt}

\newcommand\NewMoon{}
\newcommand\FirstQuarter{}
\newcommand\FullMoon{}
\newcommand\LastQuarter{}

\newcommand\@wall@NewMoon{%
\raisebox{\@wall@moonRaise}{%
  \tikz\node[moon circle, fill=mooncolor] {};%
}}

\newcommand\@wall@FullMoon{%
\raisebox{\@wall@moonRaise}{%
  \tikz\node[moon circle, draw, mooncolor, line width=0.3pt] {};%
}}

\newcommand\@wall@FirstQuarter{%
\raisebox{\@wall@moonRaise}{%
\begin{tikzpicture}
\node [moon circle, name=waxing] {};
\path[fill=mooncolor]
  (waxing.north) --
  (waxing.south) to[out=-180,in=-90]
  (waxing.west) to[out=90,in=-180]
  (waxing.north);
\end{tikzpicture}%
}}

\newcommand\@wall@LastQuarter{%
\raisebox{\@wall@moonRaise}{%
\begin{tikzpicture}
\node [moon circle, name=waning] {};
\path[fill=mooncolor]
  (waning.north) --
  (waning.south) to[out=0,in=-90]
  (waning.east) to[out=90,in=0]
  (waning.north);
\end{tikzpicture}%
}}

\newcommand\@wall@useDefaultMoons{%
\renewcommand\NewMoon{\@wall@NewMoon}%
\renewcommand\FirstQuarter{\@wall@FirstQuarter}%
\renewcommand\FullMoon{\@wall@FullMoon}%
\renewcommand\LastQuarter{\@wall@LastQuarter}%
}

\newcommand\plannerMoonSize{\@setfontsize\plannerMoonSize{14}{14}}
\newcommand*\plannerMoonFormat[1]{{\plannerMoonSize #1}}

\newcommand\@wall@planner@NewMoon{\plannerMoonFormat{\CIRCLE}}
\newcommand\@wall@planner@FirstQuarter{\plannerMoonFormat{\LEFTcircle}}
\newcommand\@wall@planner@FullMoon{\plannerMoonFormat{\Circle}}
\newcommand\@wall@planner@LastQuarter{\plannerMoonFormat{\RIGHTcircle}}

\newcommand\@wall@usePlannerMoons{%
\renewcommand\NewMoon{\@wall@planner@NewMoon}%
\renewcommand\FirstQuarter{\@wall@planner@FirstQuarter}%
\renewcommand\FullMoon{\@wall@planner@FullMoon}%
\renewcommand\LastQuarter{\@wall@planner@LastQuarter}%
}

\@wall@useDefaultMoons

% #1 = (opt) color
% #2 = date as '2018-09-14'
\newcommand*\dateCircle[2][textbody]{%
  \node[
  circle,
  minimum height=12pt,
  draw,
  color={#1},
  above right=2pt and 0pt of {cal-#2.mid},
  anchor=mid,
  ] {};%
}

% #1 = (opt) color
% #2 = date as '2018-09-14'
\newcommand*\dateSquare[2][textbody]{%
  \node[
  rectangle,
  minimum width=12pt,
  minimum height=12pt,
  draw,
  color={#1},
  above right=2pt and 0pt of {cal-#2.mid},
  anchor=mid,
  ] {};%
}

% #1 = (opt) color
% #2 = date as '2018-09-14'
\newcommand*\dateStart[2][textbody]{%
  \node (#2-rec) [
  rectangle,
  minimum width=12pt,
  minimum height=12pt,
  above right=2pt and 0pt of {cal-#2.mid},
  anchor=mid,
  ] {};%
  \node (#2-a) [above left=-6pt and 0pt of {#2-rec.north east}] {};%
  \node (#2-b) [above left=-6pt and -1pt of {#2-rec.north}] {};%
  \node (#2-c) [above left=-6pt and -3pt of {#2-rec.west}] {};%
  \node (#2-d) [above left=-6pt and -1pt of {#2-rec.south}] {};%
  \node (#2-e) [above left=-6pt and 0pt of {#2-rec.south east}] {};%
  \draw [color={#1}] (#2-a.mid) -- (#2-b.mid) -- (#2-c.mid) -- (#2-d.mid) -- (#2-e.mid);
}

% #1 = (opt) color
% #2 = date as '2018-09-14'
\newcommand*\dateEnd[2][textbody]{%
  \node (#2-rec) [
  rectangle,
  minimum width=12pt,
  minimum height=12pt,
  above right=2pt and 0pt of {cal-#2.mid},
  anchor=mid,
  ] {};%
  \node (#2-a) [above right=-6pt and 0pt of {#2-rec.north west}] {};%
  \node (#2-b) [above right=-6pt and -1pt of {#2-rec.north}] {};%
  \node (#2-c) [above right=-6pt and -3pt of {#2-rec.east}] {};%
  \node (#2-d) [above right=-6pt and -1pt of {#2-rec.south}] {};%
  \node (#2-e) [above right=-6pt and 0pt of {#2-rec.south west}] {};%
  \draw [color={#1}] (#2-a.mid) -- (#2-b.mid) -- (#2-c.mid) -- (#2-d.mid) -- (#2-e.mid);
}

% #1 = (opt) color
% #2 = date as '2018-09-14'
\newcommand*\dateUnder[2][textbody]{%
  \node (#2-rec) [
  rectangle,
  minimum width=12pt,
  minimum height=12pt,
  above right=3pt and 0pt of {cal-#2.mid},
  anchor=mid,
  ] {};%
  \draw [color={#1}] (#2-rec.south west) -- (#2-rec.south east);
}

\newcommand\SetPhoto[2][]{%
  \pgfkeys{%
    /Photo/#2/.is family, /Photo/#2,
    /Photo/init,
    defaults, file={#2},
    #1%
  }%
}

\newcommand\SetCalendar[2][]{%
  \pgfkeys{%
    /Calendar/#2/.is family, /Calendar/#2,
    /Calendar/init,
    defaults,
    #1%
  }%
}

\newcommand\SetQuote[3][]{%
  \pgfkeys{%
    /Quote/#2/.is family, /Quote/#2,
    /Quote/init,
    defaults, text={#3},
    #1%
  }%
}

\newcommand\SetEvents[4][]{%
  \pgfkeys{%
    /Events/#2/.is family, /Events/#2,
    /Events/init,
    defaults, marks={#3}, text={#4},
    #1%
  }%
}

\pgfkeys{
  /MonthPage/.is family, /MonthPage,
  layout/.style = {layout handlers/#1/.get = \@wall@month@doLayout},
  put photo/.style = {/put photo/#1},
  put quote/.style = {/put quote/#1},
  defaults/.style = {layout = small landscape, put photo = simple, put quote = simple},
  layout handlers/.cd,
    full page/.initial = \@wall@fullPageLayout,
    small landscape/.initial = \@wall@smallLandscapeLayout,
    photo and notes/.initial = \@wall@photoAndNotesLayout,
    large calendar/.initial = \@wall@largeCalendarLayout,
}

\newcommand\MonthPage[2][]{%
  \pgfkeys{/MonthPage, defaults, #1}%
  \@wall@month@doLayout{#2}%
}

\newcommand\SetTxt[2]{%
  \pgfkeys{%
    /Txt/#1/.is family, /Txt/#1,
    /Txt/init,
    defaults, text={#2},
  }%
}

\newcommand\txt[1]{%
\pgfkeys{/Txt/#1/text/.get=\@val}%
\@val%
}

\def\@t@monthName{}
\def\@t@eventsCsv{}
\def\@t@markDefaultsCsv{}
\def\@t@filterPred{}
\def\@t@formatFunc{}
\def\@t@formatCmd{}
\def\@t@minEvents{}

\newcommand\monthMarkFmt{\fontsize{10}{10}\selectfont\color{textbody}}

\newcommand\symbolSpace{\thinspace}
\newcommand\symbolSeparator{,\symbolSpace}
  
% Semicolon to close the tikz calendar. Necessary before starting to use \node
% or \draw commands.
\newcommand\semicolonEndTikzCalendar{%
  ;%
}

% #1 = option keys
\newcommand*\parseMonthEvents[1][]{%
\pgfkeys{/parseMonthEvents, defaults, #1,
  month/.get=\@t@monthName,
  filter pred/.get=\@t@filterPred,
  format func/.get=\@t@formatFunc,
  format cmd/.get=\@t@formatCmd,
  events csv/.get=\@t@eventsCsv,
  mark defaults csv/.get=\@t@markDefaultsCsv,
  min events/.get=\@t@minEvents,
}%
\luadirect{
require("wallcalendar-helpers.lua")
monthEvents(
  \luastring{\@t@monthName},
  \@t@filterPred,
  \@t@formatFunc,
  \luastringO{\@t@formatCmd},
  \luastring{\@t@eventsCsv},
  \luastring{\@t@markDefaultsCsv},
  \@t@minEvents
)}}

\def\@t@yearNum{}

% #1 = option keys
\newcommand*\parseYearEvents[1][]{%
\pgfkeys{/parseYearEvents, defaults, #1,
  year/.get=\@t@year,
  filter pred/.get=\@t@filterPred,
  format func/.get=\@t@formatFunc,
  format cmd/.get=\@t@formatCmd,
  events csv/.get=\@t@eventsCsv,
  mark defaults csv/.get=\@t@markDefaultsCsv,
  min events/.get=\@t@minEvents,
}%
\luadirect{
require("wallcalendar-helpers.lua")
yearEvents(
  tonumber(\@t@year),
  \@t@filterPred,
  \@t@formatFunc,
  \luastringO{\@t@formatCmd},
  \luastring{\@t@eventsCsv},
  \luastring{\@t@markDefaultsCsv},
  \@t@minEvents
)}}

\newlength\dayTextXshift
\newlength\dayTextYshift
\setlength{\dayTextXshift}{0pt}
\setlength{\dayTextYshift}{0pt}

\newlength\markNumberAbove
\newlength\markNumberRight
\setlength{\markNumberAbove}{-10pt}
\setlength{\markNumberRight}{-3pt}

\newlength\markDayTextAbove
\newlength\markDayTextRight
\setlength{\markDayTextAbove}{-10pt}
\setlength{\markDayTextRight}{-3pt}

% Suffix appended to the calendar day node name when positioning event marks.
% Empty by default (marks reference the day node itself). Layouts with
% separate day-number nodes (e.g.\ rigel / photo-and-notes) set this to
% {-daynumber} so marks are positioned relative to the day number, avoiding
% overflow on the last grid column.
\def\@wall@markNodeSuffix{}

\newcommand\parseMonthMarksDayText{%
\luadirect{
require("wallcalendar-helpers.lua")
monthMarksDayText(\luastring{\theMonthName}, nil, \luastring{\@wall@eventsCsv})
tex.sprint(';')
}}

\newcommand\parseMonthMarksDayTextMonth[1]{%
\luadirect{
require("wallcalendar-helpers.lua")
monthMarksDayText(\luastring{#1}, nil, \luastring{\@wall@eventsCsv})
tex.sprint(';')
}}

\newcommand*\parseMonthMarksDayTextUsing[1]{%
\luadirect{
require("wallcalendar-helpers.lua")
monthMarksDayText(\luastring{\theMonthName}, nil, \luastring{#1})
}}

\newcommand\parseMonthMarksDayTextMonthUsing[2]{%
\luadirect{
require("wallcalendar-helpers.lua")
monthMarksDayText(\luastring{#1}, nil, \luastring{#2})
}}

\newcommand*\parseMonthMarksDayTextInlineUsing[1]{%
\luadirect{
require("wallcalendar-helpers.lua")
monthMarksDayTextInline(\luastring{\theMonthName}, nil, \luastring{#1})
}}

\newcommand*\parseMonthMarksNote{%
\luadirect{
require("wallcalendar-helpers.lua")
monthMarksNote(\luastring{\theMonthName}, nil, \luastring{\@wall@eventsCsv}, \luastring{\@wall@markDefaultsCsv}, \luastring{\@wall@markNodeSuffix})
}}

\newcommand*\parseMonthMarksNoteUsing[1]{%
\luadirect{
require("wallcalendar-helpers.lua")
monthMarksNote(\luastring{\theMonthName}, nil, \luastring{#1}, \luastring{\@wall@markDefaultsCsv}, \luastring{\@wall@markNodeSuffix})
}}

\newcommand*\parseMonthInlineNotes{%
\luadirect{
require("wallcalendar-helpers.lua")
monthInlineNotes(\luastring{\theMonthName}, nil, \luastring{\@wall@eventsCsv}, \luastring{\@wall@markDefaultsCsv})
}}

\makepagestyle{month}
\makeoddhead{month}{}{}{}
\makeevenhead{month}{}{}{}
\makeoddfoot{month}{}{}{}
\makeevenfoot{month}{}{}{}

\pagestyle{month}

\NewCoffin\@wall@pageWrap
\NewCoffin\@wall@photo
\NewCoffin\@wall@quote
\NewCoffin\@wall@calendar
\NewCoffin\@wall@events
\NewCoffin\@wall@notepad
\NewCoffin\@wall@photoPageWrap
\NewCoffin\@wall@notesPageWrap

\newlength\@t@bleed
\newlength\@t@rightOffset
\newlength\@t@minipageWidth
\newlength\@t@calendar@minimumHeight
\newlength\@t@calendar@height
\newlength\@t@calendar@hmargin
\newlength\@t@calendar@verticalSpacing
\newlength\@t@calendar@dayYshift
\newlength\@t@calendar@dayXshift
\newlength\@t@calendar@gridHeight
\newlength\@t@calendar@gridHeightFourRows
\newlength\@t@calendar@gridHeightFiveRows
\newlength\@t@calendar@gridHeightSixRows
\newlength\@t@xOffset
\newlength\@t@yOffset
\def\@t@file{}

\newcommand*\monthFmt{}%
\newcommand*\yearFmt{}%
\newcommand*\dayLetterColor{}%
\newcommand*\dayLetterFmt{}%
\newcommand*\dayTextFmt{}%
\newcommand*\quoteFmt{}%
\newcommand*\headingFmt{}%
\newcommand*\calendarFmt{}%
\newcommand*\eventsFmt{}%
\newcommand*\dayLetterTextFmt[1]{#1}

\newcommand\@wall@layout@reset{%
  \renewcommand*\monthFmt{}%
  \renewcommand*\yearFmt{}%
  \renewcommand*\dayLetterColor{}%
  \renewcommand*\dayLetterFmt{}%
  \renewcommand*\dayTextFmt{}%
  \renewcommand*\quoteFmt{}%
  \renewcommand*\headingFmt{}%
  \renewcommand*\calendarFmt{}%
  \renewcommand*\eventsFmt{}%
  \def\@t@file{}%
  \setlength{\@t@calendar@height}{0pt}%
  \setlength{\@t@calendar@hmargin}{0pt}%
  \setlength{\@t@calendar@dayYshift}{0pt}%
  \setlength{\@t@calendar@dayXshift}{0pt}%
  \setlength{\@t@bleed}{0pt}%
  \setlength{\@t@rightOffset}{0pt}%
  \setlength{\@t@minipageWidth}{0pt}%
  \setlength{\@t@xOffset}{0pt}%
  \setlength{\@t@yOffset}{0pt}%
  \setlength{\@t@calendar@gridHeight}{0pt}%
  \setlength{\@t@calendar@gridHeightFourRows}{0pt}%
  \setlength{\@t@calendar@gridHeightFiveRows}{0pt}%
  \setlength{\@t@calendar@gridHeightSixRows}{0pt}%
  \def\@wall@markNodeSuffix{}%
  \renewcommand\monthMarkFmt{\fontsize{10}{10}\selectfont\color{textbody}}%
}

\newcommand\fullPageFmt{%
  \renewcommand*\monthFmt{\LARGE}%
  \renewcommand*\yearFmt{\LARGE}%
  \renewcommand*\dayLetterColor{}%
  \renewcommand*\dayLetterFmt{\tiny}%
  \renewcommand*\dayTextFmt{\small}%
  \renewcommand*\quoteFmt{}%
  \renewcommand*\headingFmt{\centering}%
  \renewcommand*\calendarFmt{\centering}%
  \renewcommand*\eventsFmt{\setlength{\parindent}{0pt}\raggedleft\footnotesize}%
}

\newcommand\@wall@fullPageLayout[2][]{%
\makeatletter
\renewcommand*\theMonthName{#2}
\@wall@layout@reset
\fullPageFmt

\colorlet{weekday}{black}
\colorlet{weekend}{black!70}

\pgfkeys{/Photo/#2/bleed/.get=\@val}
\setlength{\@t@bleed}{\@val}

\def\@t@monthnum{\monthToNum{#2}}

% 40mm = 1.5748 inch
% 43mm = 1.6929 inch
\setlength{\@t@calendar@height}{40mm + \@t@bleed}

% See if there was a height given in the options
\pgfkeys{/Calendar/#2/minimum height/.get=\@val}
\ifx\@val\empty \relax
\else
  \setlength{\@t@calendar@height}{\@val + \@t@bleed}
\fi

\setlength{\@t@calendar@hmargin}{20pt}

% NOTE: the -4pt and -2pt offset is somehow necessary for the sides to align
% with the edges
\setlength{\@t@rightOffset}{\@t@bleed +\@t@calendar@hmargin -4pt}
\setlength{\@t@minipageWidth}{\calPaperWidth -2\@t@calendar@hmargin -2pt}

\SetHorizontalCoffin\@wall@pageWrap{%
  \color{white}%
  \rule{\textwidth}{0pt}%
  \rule{0pt}{\textheight}%
}

\pgfkeys{/Photo/#2/file/.get=\@t@file}

\SetHorizontalCoffin\@wall@photo{%
  \placeholder[fill=photo-frame]{hasvarnish}{%
    \@wall@photo@putPhoto{\@t@file}%
  }%
}

\SetHorizontalCoffin\@wall@quote{%
  \placeholder[fill=quote-frame]{}{%
    \begin{minipage}{\linewidth}%
      \quoteFmt
      \pgfkeys{/Quote/#2/text/.get=\@val}%
      \@val%
    \end{minipage}%
  }%
}

\SetHorizontalCoffin\@wall@calendar{%
\ifvarnishmask\relax
\else
\begin{tikzpicture}

\node (bg) [
  fill = calendarbg,
  opacity = 0.5,
  minimum width = {\calPaperWidth + 2\@t@bleed},
  anchor=north west,
  /Calendar/#2/bg,
  % override the style, in case bleed was set above
  minimum height = {\@t@calendar@height},
] at (0,0) {};

\node (heading) [
  below right=10pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
] {%
\placeholder[fill=heading-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\headingFmt
{\monthFmt\@tr@monthNumName{\@t@monthnum}}
\hfill
\strcmpblank{\CalendarAltYear}{%
   {\yearFmt\CalendarYear}%
}{%
  {\yearFmt\CalendarYear/\CalendarAltYear}%
}%
\end{minipage}%
}%
};

\node (calendar) [
  below right=35pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
] {%
\placeholder[fill=calendar-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\calendarFmt
\tikz{\tikzMonthCalendar@fullpage{\@t@monthnum};}%
\end{minipage}%
}%
};

\node (events) [
  below=0pt of calendar.south west,
  anchor=north west,
] {%
\placeholder[fill=events-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\eventsFmt
\pgfkeys{/Events/#2/text/.get=\@val}%
\@val%
\end{minipage}%
}%
};

\end{tikzpicture}%
\fi
}% \SetHorizontalCoffin

\@wall@photo@setYOffset

\pgfkeys{/Photo/#2/xOffset/.get=\@val}
\addtolength{\@t@xOffset}{\@val}
\pgfkeys{/Photo/#2/yOffset/.get=\@val}
\addtolength{\@t@yOffset}{\@val}

% NOTE: a small whitespace is visible on the left edge of the page when bleed is 0pt, a space must be getting in somewhere.
\JoinCoffins*\@wall@pageWrap[l,t]\@wall@photo[l,t](-\spinemargin -\@t@bleed + \@t@xOffset, \uppermargin + \@t@bleed + \@t@yOffset)

\pgfkeys{/Quote/#2/xOffset/.get=\@val}
\setlength{\@t@xOffset}{\@val}
\pgfkeys{/Quote/#2/yOffset/.get=\@val}
\setlength{\@t@yOffset}{\@val}

\JoinCoffins*\@wall@pageWrap[l,t]\@wall@quote[l,t](\@t@xOffset, \@t@yOffset)

\JoinCoffins*\@wall@pageWrap[l,b]\@wall@calendar[l,b](-\spinemargin -\@t@bleed, \textheight +\uppermargin -\paperheight -\@t@bleed)

\makeatother

\clearpage
\TypesetCoffin\@wall@pageWrap%
}% \@wall@fullPageLayout

\newcommand*{\tikzMonthCalendar@fullpage}[1]{%
\pgfkeys{/Events/\monthName{#1}/marks/.get=\@eventmarks}%
\calendar (cal#1) [alnitak, dates=\CalendarYear-#1-01 to \CalendarYear-#1-last] \@eventmarks;%
}

\newcommand\smallLandscapeFmt{%
  \renewcommand*\monthFmt{\LARGE}%
  \renewcommand*\yearFmt{\LARGE}%
  \renewcommand*\dayLetterColor{}%
  \renewcommand*\dayLetterFmt{\tiny}%
  \renewcommand*\dayTextFmt{\small}%
  \renewcommand*\quoteFmt{\centering}%
  \renewcommand*\headingFmt{\centering}%
  \renewcommand*\calendarFmt{\centering}%
  \renewcommand*\eventsFmt{\setlength{\parindent}{0pt}\raggedright\footnotesize}%
  \setlength{\@t@calendar@minimumHeight}{85mm}%
  \setlength{\@t@calendar@hmargin}{20pt}%
  % 5mm: day headings
  % 20mm: events
  % 6.5mm: white space
  \setlength{\@t@calendar@verticalSpacing}{20mm + 5mm + 6.5mm}%
}

\newcommand\@wall@smallLandscapeLayout[2][]{%
\makeatletter
\renewcommand*\theMonthName{#2}
\@wall@layout@reset
\smallLandscapeFmt

\colorlet{weekday}{black}
\colorlet{weekend}{black!70}

\pgfkeys{/Photo/#2/bleed/.get=\@val}
\setlength{\@t@bleed}{\@val}

\def\@t@monthnum{\monthToNum{#2}}

\setlength{\@t@calendar@height}{\@t@calendar@minimumHeight + \@t@bleed}

% See if there was a height given in the options
\pgfkeys{/Calendar/#2/minimum height/.get=\@val}
\ifx\@val\empty \relax
\else
  \setlength{\@t@calendar@height}{\@val + \@t@bleed}
\fi

\setlength{\@tmp@a}{\@t@calendar@verticalSpacing}
\setlength{\@tmp@b}{\@t@calendar@height -\@tmp@a}
\setlength{\@t@calendar@dayYshift}{0.1666\@tmp@b}% 1/6 = 0.1666

\setlength{\@t@calendar@gridHeightSixRows}{\@tmp@b}
\setlength{\@t@calendar@gridHeightFiveRows}{\@tmp@b -0.1666\@tmp@b}
\setlength{\@t@calendar@gridHeightFourRows}{\@tmp@b -0.3332\@tmp@b}

% NOTE: the -4pt and -2pt offset is somehow necessary for the sides to align
% with the edges
\setlength{\@t@rightOffset}{\@t@bleed +\@t@calendar@hmargin -4pt}
\setlength{\@t@minipageWidth}{\calPaperWidth -2\@t@calendar@hmargin -2pt}

\setlength{\@t@calendar@dayXshift}{0.1428\@t@minipageWidth}% 1/7 = 0.1428

\SetHorizontalCoffin\@wall@pageWrap{%
  \color{white}%
  \rule{\textwidth}{0pt}%
  \rule{0pt}{\textheight}%
}

\pgfkeys{/Photo/#2/file/.get=\@t@file}

\SetHorizontalCoffin\@wall@photo{%
  \placeholder[fill=photo-frame]{hasvarnish}{%
    \@wall@photo@putPhoto{\@t@file}%
  }%
}

\SetHorizontalCoffin\@wall@quote{%
  \placeholder[fill=quote-frame]{}{%
    \begin{minipage}{\linewidth}%
      \quoteFmt
      \pgfkeys{/Quote/#2/text/.get=\@val}%
      \@val%
    \end{minipage}%
  }%
}

\SetHorizontalCoffin\@wall@calendar{%
\ifvarnishmask\relax
\else
\begin{tikzpicture}

\node (bg) [
  fill = calendarbg,
  opacity = 1,
  minimum width = {\calPaperWidth + 2\@t@bleed},
  anchor=north west,
  /Calendar/#2/bg,
  % override the style, in case bleed was set above
  minimum height = {\@t@calendar@height},
] at (0,0) {};

\node (heading) [
  below right=10pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
] {%
\placeholder[fill=heading-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\headingFmt
{\monthFmt\@tr@monthNumName{\@t@monthnum}}
\hfill
\strcmpblank{\CalendarAltYear}{%
   {\yearFmt\CalendarYear}%
}{%
  {\yearFmt\CalendarYear/\CalendarAltYear}%
}%
\end{minipage}%
}%
};

\node (calendar) [
  below right=35pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
] {%
\placeholder[fill=calendar-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\calendarFmt
\hspace*{-5pt}% FIXME
\tikz{\tikzMonthCalendar@smallLandscape{\@t@monthnum};}%
\end{minipage}%
}%
};

\node (events) [
  above right=9mm and {\@t@rightOffset} of bg.south west,
  anchor=south west,
] {%
\placeholder[fill=events-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\eventsFmt
\pgfkeys{/Events/#2/text/.get=\@val}%
\@val%
\end{minipage}%
}%
};

\end{tikzpicture}%
\fi
}% \SetHorizontalCoffin

% The quote has to be centered between the photo and the calendar with manual tweaking.
% The height of the quote is not known, the height of the calendar plus its heading is not known.

% TODO move the photo with /Photo/#2/xOffset and yOffset as at the full page layout

\pgfkeys{/Quote/#2/yOffset/.get=\@val}
\setlength{\@t@yOffset}{\@val}

\JoinCoffins*\@wall@photo[hc,b]\@wall@quote[hc,t](0pt, \@t@yOffset)

\pgfkeys{/Photo/#2/yOffset/.get=\@val}
\setlength{\@t@yOffset}{\@val}

% NOTE: Taking the bottom edge of the photo as fixed.
% yOffset must be set to pull the photo down into position

\JoinCoffins*\@wall@pageWrap[hc,t]\@wall@photo[hc,b](0pt, \uppermargin + \@t@yOffset)

% Calendar is aligned to the bottom of the page.

\JoinCoffins*\@wall@pageWrap[hc,b]\@wall@calendar[hc,b](0pt, \textheight +\uppermargin -\paperheight -\@t@bleed)

\makeatother

\clearpage
\TypesetCoffin\@wall@pageWrap%
}% \@wall@smallLandscapeLayout

\newcommand*{\tikzMonthCalendar@smallLandscape}[1]{%
\pgfkeys{/Events/\monthName{#1}/marks/.get=\@eventmarks}%
\calendar (cal#1) [betelgeuse, dates=\CalendarYear-#1-01 to \CalendarYear-#1-last] \@eventmarks;%
}

\newcommand\notepadContent{%
  \begin{minipage}{\@t@minipageWidth}%
    \setlength\parindent{0pt}%
    \setlength\parskip{10pt}%
    \color{black!40}%

    \ifsixrowsmonth
      \dotfill\par
      \dotfill\par
    \else
      \iffourrowsmonth
        \dotfill\par
        \dotfill\par
        \dotfill\par
        \dotfill\par
        \dotfill\par
        \dotfill\par
      \else
        \dotfill\par
        \dotfill\par
        \dotfill\par
        \dotfill\par
      \fi
    \fi

  \end{minipage}%
}

\newcommand\photoAndNotesFmt{%
  \renewcommand*\monthFmt{\LARGE}%
  \renewcommand*\yearFmt{\LARGE}%
  \renewcommand*\dayLetterColor{}%
  \renewcommand*\dayLetterFmt{\small}%
  \renewcommand*\dayLetterTextFmt[1]{\tiny\textls*{\MakeUppercase{##1}}}%
  \renewcommand*\dayTextFmt{\small}%
  \renewcommand*\quoteFmt{\centering}%
  \renewcommand*\headingFmt{\centering}%
  \renewcommand*\calendarFmt{\centering}%
  \renewcommand*\eventsFmt{\setlength{\parindent}{0pt}\raggedright\fontsize{6}{8}\selectfont}%
  \renewcommand\monthMarkFmt{\fontsize{7}{7}\selectfont\color{textbody}}%
  \def\@wall@markNodeSuffix{-daynumber}%
  \setlength{\@t@calendar@minimumHeight}{\calPaperHeight - 30mm}%
  \setlength{\@t@calendar@hmargin}{20pt}%
  % white space to allow:
  % - month and year label
  % - notepad area
  % - extra white space
  \setlength{\@t@calendar@verticalSpacing}{30mm}%
}

\newcommand\@wall@photoAndNotesLayout[2][]{%
\makeatletter
\renewcommand*\theMonthName{#2}
\@wall@layout@reset
\photoAndNotesFmt
\pgfkeys{/Photo/#2/disabled/.get=\@val}
\ifdefstring{\@val}{true}{\PhotoEnabledfalse}{\PhotoEnabledtrue}

\pgfkeys{/Photo/#2/bleed/.get=\@val}
\setlength{\@t@bleed}{\@val}

\def\@t@monthnum{\monthToNum{#2}}

\settowidth{\@tmp@z}{%
\begin{tikzpicture}
  \calendar [
    dates=\CalendarYear-\@t@monthnum-01 to \CalendarYear-\@t@monthnum-last,
    execute at begin day scope={
      \ifdate{six rows month}{\global\sixrowsmonthtrue}{\global\sixrowsmonthfalse}
      \ifdate{four rows month}{\global\fourrowsmonthtrue}{}
      \ifdate{day of month=29}{\global\fourrowsmonthfalse}{}
    },
  ];
\end{tikzpicture}
}

\setlength{\@t@calendar@height}{\@t@calendar@minimumHeight + \@t@bleed}

% See if there was a height given in the options
\pgfkeys{/Calendar/#2/minimum height/.get=\@val}
\ifx\@val\empty \relax
\else
  \setlength{\@t@calendar@height}{\@val + \@t@bleed}
\fi

\setlength{\@tmp@a}{\@t@calendar@verticalSpacing}
\setlength{\@tmp@b}{\@t@calendar@height -\@tmp@a}
\setlength{\@t@calendar@dayYshift}{0.1666\@tmp@b}% 1/6 = 0.1666

\setlength{\@t@calendar@gridHeightSixRows}{\@tmp@b}
\setlength{\@t@calendar@gridHeightFiveRows}{\@tmp@b -0.1666\@tmp@b}
\setlength{\@t@calendar@gridHeightFourRows}{\@tmp@b -0.3332\@tmp@b}

% NOTE: the -4pt and -2pt offset is somehow necessary for the sides to align
% with the edges
\setlength{\@t@rightOffset}{\@t@bleed +\@t@calendar@hmargin -4pt}
\setlength{\@t@minipageWidth}{\calPaperWidth -2\@t@calendar@hmargin -2pt}

\setlength{\@t@calendar@dayXshift}{0.1428\@t@minipageWidth}% 1/7 = 0.1428

\SetHorizontalCoffin\@wall@photoPageWrap{%
  \color{white}%
  \rule{\textwidth}{0pt}%
  \rule{0pt}{\textheight}%
}

\SetHorizontalCoffin\@wall@notesPageWrap{%
  \color{white}%
  \rule{\textwidth}{0pt}%
  \rule{0pt}{\textheight}%
}

\ifPhotoEnabled
\pgfkeys{/Photo/#2/file/.get=\@t@file}

\SetHorizontalCoffin\@wall@photo{%
  \placeholder[fill=photo-frame]{hasvarnish}{%
    \@wall@photo@putPhoto{\@t@file}%
  }%
}
\fi

\ifPhotoEnabled
\SetHorizontalCoffin\@wall@quote{%
  \placeholder[fill=quote-frame]{}{%
    \begin{minipage}{\linewidth}%
      \quoteFmt
      \pgfkeys{/Quote/#2/text/.get=\@val}%
      \@val%
    \end{minipage}%
  }%
}
\fi

\SetHorizontalCoffin\@wall@notepad{%
  \placeholder[fill=quote-frame]{}{%
    \notepadContent%
  }%
}

\SetHorizontalCoffin\@wall@calendar{%
\ifvarnishmask\relax
\else
\begin{tikzpicture}

\node (bg) [
  fill = calendarbg,
  opacity = 1,
  minimum width = {\calPaperWidth + 2\@t@bleed},
  anchor=north west,
  /Calendar/#2/bg,
  % override the style, in case bleed was set above
  minimum height = {\@t@calendar@height},
] at (0,0) {};

\node (heading) [
  below right=10pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
] {%
\placeholder[fill=heading-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\headingFmt
{\monthFmt\@tr@monthNumName{\@t@monthnum}}
\hfill
\strcmpblank{\CalendarAltYear}{%
   {\yearFmt\CalendarYear}%
}{%
  {\yearFmt\CalendarYear/\CalendarAltYear}%
}%
\end{minipage}%
}%
};

\node (calendar) [
  below right=35pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
] {%
\placeholder[fill=calendar-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\calendarFmt
\hspace*{-5pt}% FIXME
\tikz{\tikzMonthCalendar@photoAndNotes{\@t@monthnum};}%
\end{minipage}%
}%
};

\node (events) [
  above right=10mm and {\@t@rightOffset} of bg.south west,
  anchor=south west,
] {%
\placeholder[fill=events-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\eventsFmt
\pgfkeys{/Events/#2/text/.get=\@val}%
\@val%
\end{minipage}%
}%
};

\end{tikzpicture}%
\fi
}% \SetHorizontalCoffin

\ifPhotoEnabled
\@wall@photo@setYOffset

\pgfkeys{/Photo/#2/xOffset/.get=\@val}
\addtolength{\@t@xOffset}{\@val}
\pgfkeys{/Photo/#2/yOffset/.get=\@val}
\addtolength{\@t@yOffset}{\@val}

\JoinCoffins*\@wall@photoPageWrap[l,t]\@wall@photo[l,t](-\spinemargin -\@t@bleed + \@t@xOffset, \uppermargin + \@t@bleed + \@t@yOffset)

\pgfkeys{/Quote/#2/xOffset/.get=\@val}
\setlength{\@t@xOffset}{\@val}
\pgfkeys{/Quote/#2/yOffset/.get=\@val}
\setlength{\@t@yOffset}{\@val}

\JoinCoffins*\@wall@photoPageWrap[l,t]\@wall@quote[l,t](\@t@xOffset, \@t@yOffset)
\fi

% Calendar is aligned to the top of the notes page.

\JoinCoffins*\@wall@notesPageWrap[hc,t]\@wall@calendar[hc,t](0pt, 0pt)

% Notepad is aligned to the bottom of the notes page.

\JoinCoffins*\@wall@notesPageWrap[hc,b]\@wall@notepad[hc,b](0pt, 0pt)

\makeatother

\ifPhotoEnabled
\clearpage
\TypesetCoffin\@wall@photoPageWrap%
\fi
\clearpage
\TypesetCoffin\@wall@notesPageWrap%
}% \@wall@photoAndNotesLayout

\newcommand*{\tikzMonthCalendar@photoAndNotes}[1]{%
\pgfkeys{/Events/\monthName{#1}/marks/.get=\@eventmarks}%
\calendar (cal#1) [rigel, dates=\CalendarYear-#1-01 to \CalendarYear-#1-last] \@eventmarks;%
}

\newcommand\largeCalendarFmt{%
  \renewcommand*\monthFmt{\LARGE}%
  \renewcommand*\yearFmt{\LARGE}%
  \renewcommand*\dayLetterColor{}%
  \renewcommand*\dayLetterFmt{\small}%
  \renewcommand*\dayLetterTextFmt[1]{\tiny\textls*{\MakeUppercase{##1}}}%
  \renewcommand*\dayTextFmt{\small}%
  \renewcommand*\quoteFmt{}%
  \renewcommand*\headingFmt{\centering}%
  \renewcommand*\calendarFmt{\centering}%
  \renewcommand*\eventsFmt{\setlength{\parindent}{0pt}\raggedright\fontsize{6}{8}\selectfont}%
  \setlength{\@t@calendar@minimumHeight}{112mm}%
  \setlength{\@t@calendar@hmargin}{20pt}%
  % white space to allow:
  % - month and year label
  % - notepad area
  % - extra white space
  \setlength{\@t@calendar@verticalSpacing}{30mm}%
}

\newcommand\@wall@largeCalendarLayout[2][]{%
\makeatletter
\renewcommand*\theMonthName{#2}
\@wall@layout@reset
\largeCalendarFmt

\pgfkeys{/Photo/#2/bleed/.get=\@val}
\setlength{\@t@bleed}{\@val}

\def\@t@monthnum{\monthToNum{#2}}

\settowidth{\@tmp@z}{%
\begin{tikzpicture}
  \calendar [
    dates=\CalendarYear-\@t@monthnum-01 to \CalendarYear-\@t@monthnum-last,
    execute at begin day scope={
      \ifdate{six rows month}{\global\sixrowsmonthtrue}{\global\sixrowsmonthfalse}
      \ifdate{four rows month}{\global\fourrowsmonthtrue}{}
      \ifdate{day of month=29}{\global\fourrowsmonthfalse}{}
    },
  ];
\end{tikzpicture}
}

\setlength{\@t@calendar@height}{\@t@calendar@minimumHeight + \@t@bleed}

% See if there was a height given in the options
\pgfkeys{/Calendar/#2/minimum height/.get=\@val}
\ifx\@val\empty \relax
\else
  \setlength{\@t@calendar@height}{\@val + \@t@bleed}
\fi

\setlength{\@tmp@a}{\@t@calendar@verticalSpacing}
\setlength{\@tmp@b}{\@t@calendar@height -\@tmp@a}
\setlength{\@t@calendar@dayYshift}{0.1666\@tmp@b}% 1/6 = 0.1666

\setlength{\@t@calendar@gridHeightSixRows}{\@tmp@b}
\setlength{\@t@calendar@gridHeightFiveRows}{\@tmp@b -0.1666\@tmp@b}
\setlength{\@t@calendar@gridHeightFourRows}{\@tmp@b -0.3332\@tmp@b}

% NOTE: the -4pt and -2pt offset is somehow necessary for the sides to align
% with the edges
\setlength{\@t@rightOffset}{\@t@bleed +\@t@calendar@hmargin -4pt}
\setlength{\@t@minipageWidth}{\calPaperWidth -2\@t@calendar@hmargin -2pt}

\setlength{\@t@calendar@dayXshift}{0.1428\@t@minipageWidth}% 1/7 = 0.1428

\SetHorizontalCoffin\@wall@pageWrap{%
  \color{white}%
  \rule{\textwidth}{0pt}%
  \rule{0pt}{\textheight}%
}

\pgfkeys{/Photo/#2/file/.get=\@t@file}

\SetHorizontalCoffin\@wall@photo{%
  % Varnishmask placeholder is in 'put photo/left' and 'put photo/right'.
  \@wall@photo@putPhoto{\@t@file}%
}

\SetHorizontalCoffin\@wall@quote{%
\ifvarnishmask\relax
\else
  \placeholder[fill=quote-frame]{}{%
    \pgfkeys{/Quote/#2/text/.get=\@val}%
    \@wall@quote@putQuote{\@val}%
  }%
\fi
}

\SetHorizontalCoffin\@wall@calendar{%
\ifvarnishmask\relax
\else
\begin{tikzpicture}

\node (bg) [
  fill = calendarbg,
  opacity = 1,
  minimum width = {\calPaperWidth + 2\@t@bleed},
  anchor=north west,
  /Calendar/#2/bg,
  % override the style, in case bleed was set above
  minimum height = {\@t@calendar@height},
] at (0,0) {};

\node (heading) [
  below right=2pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
] {%
\placeholder[fill=heading-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\headingFmt
{\monthFmt\@tr@monthNumName{\@t@monthnum}}
\hfill
\strcmpblank{\CalendarAltYear}{%
   {\yearFmt\CalendarYear}%
}{%
  {\yearFmt\CalendarYear/\CalendarAltYear}%
}%
\end{minipage}%
}%
};

\node (calendar) [
  below right=35pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
] {%
\placeholder[fill=calendar-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\calendarFmt
\hspace*{-5pt}% FIXME
\tikz{\tikzMonthCalendar@largeCalendar{\@t@monthnum};}%
\end{minipage}%
}%
};

\node (events) [
  below=105mm of bg.north,
  anchor=north,
] {%
\placeholder[fill=events-frame]{}{%
\begin{minipage}{\@t@minipageWidth}%
\eventsFmt
\pgfkeys{/Events/#2/text/.get=\@val}%
\@val%
\end{minipage}%
}%
};

\end{tikzpicture}%
\fi
}% \SetHorizontalCoffin

\@wall@photo@setYOffset

\pgfkeys{/Photo/#2/xOffset/.get=\@val}
\addtolength{\@t@xOffset}{\@val}
\pgfkeys{/Photo/#2/yOffset/.get=\@val}
\addtolength{\@t@yOffset}{\@val}

\JoinCoffins*\@wall@pageWrap[l,t]\@wall@photo[l,t](-\spinemargin -\@t@bleed + \@t@xOffset, \uppermargin + \@t@bleed + \@t@yOffset)

\pgfkeys{/Quote/#2/xOffset/.get=\@val}
\setlength{\@t@xOffset}{\@val}
\pgfkeys{/Quote/#2/yOffset/.get=\@val}
\setlength{\@t@yOffset}{\@val}

\JoinCoffins*\@wall@pageWrap[l,t]\@wall@quote[l,t](-\spinemargin -\@t@bleed + \@t@xOffset, \uppermargin + \@t@bleed + \@t@yOffset)
                                                                
\JoinCoffins*\@wall@pageWrap[l,b]\@wall@calendar[l,t](-\spinemargin -\@t@bleed, \textheight +\uppermargin -\paperheight -\@t@bleed +\@t@calendar@height +10mm)
                                                          
\makeatother

\clearpage
\TypesetCoffin\@wall@pageWrap%
}% \@wall@largeCalendarLayout

\newcommand*{\tikzMonthCalendar@largeCalendar}[1]{%
\pgfkeys{/Events/\monthName{#1}/marks/.get=\@eventmarks}%
\calendar (cal#1) [rigel, dates=\CalendarYear-#1-01 to \CalendarYear-#1-last] \@eventmarks;%
}

\tikzstyle{day letter headings}=[%
  day heading/.style={black!90},
  execute before day scope={%
    \ifdate{day of month=1}{%
      \pgfmathsetlength\pgf@xa{\tikz@lib@cal@xshift}%
      \pgfmathsetlength\pgf@ya{\tikz@lib@cal@yshift}%
      \foreach \d in {0,1,2,3,4,5,6} {%
        \pgf@xa=\d\pgf@xa%
        \pgftransformxshift{\pgf@xa}%
        \pgftransformyshift{\pgf@ya}%
        \pgftransformyshift{4pt}%
        \node (d\d) [anchor=base, day heading] {\dayLetterFmt\@tr@columnDayLetter{\d}};%
      };%
    }{}%
  },%
]

\tikzstyle{day fullday headings}=[%
  day heading/.style={black!90},
  execute before day scope={%
    \ifdate{day of month=1}{%
      \pgfmathsetlength\pgf@xa{\tikz@lib@cal@xshift}%
      \pgfmathsetlength\pgf@ya{\tikz@lib@cal@yshift}%
      \foreach \d in {0,1,2,3,4,5,6} {%
        \pgf@xa=\d\pgf@xa%
        \pgftransformxshift{\pgf@xa}%
        \pgftransformyshift{\pgf@ya}%
        \pgftransformyshift{4pt}%
        \node (d\d) [anchor=base, day heading] {\dayLetterTextFmt{\@tr@columnDayName{\d}}};%
      };%
    }{}%
  },%
]

\newcount\gridRows
\newcount\gridLines
\newcount\n

\tikzstyle{days grid}=[%
  execute before day scope={%
    \ifdate{day of month=1}{%
      %
      % Determine if the grid is five or six rows
      %
      % 31 day months
      \ifdate{between=01-01 and 01-31, between=03-01 and 03-31, between=05-01 and 05-31, between=07-01 and 07-31, between=08-01 and 08-31, between=10-01 and 10-31, between=12-01 and 12-31}{%
        % Monday-first: 6 rows if 1st is Sat or Sun. Sunday-first: 6 rows if 1st is Fri or Sat.
        \ifsundayFirst
          \ifdate{Friday,Saturday}{%
            \gridRows=6%
            \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightSixRows}%
          }{%
            \gridRows=5%
            \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightFiveRows}%
          }
        \else
          \ifdate{Saturday,Sunday}{%
            \gridRows=6%
            \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightSixRows}%
          }{%
            \gridRows=5%
            \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightFiveRows}%
          }
        \fi
      }{
      % 30 day months and February
        \ifdate{between=02-01 and 02-last}{%
          % 4-row February: non-leap year where Feb 1 is the week-start day.
          % Monday-first: 4 rows if 1st is Mon. Sunday-first: 4 rows if 1st is Sun.
          \ifsundayFirst
            \ifdate{Sunday}{%
              \luadirect{
                local date = require("wallcalendar-date.lua")
                if not date.isleapyear(\CalendarYear) then
                  tex.sprint("\\gridRows=4\\relax")
                  tex.sprint("\\setlength\\@t@calendar@gridHeight{\\@t@calendar@gridHeightFourRows}")
                else
                  tex.sprint("\\gridRows=5\\relax")
                  tex.sprint("\\setlength\\@t@calendar@gridHeight{\\@t@calendar@gridHeightFiveRows}")
                end
              }%
            }{%
              \gridRows=5%
              \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightFiveRows}%
            }%
          \else
            \ifdate{Monday}{%
              \luadirect{
                local date = require("wallcalendar-date.lua")
                if not date.isleapyear(\CalendarYear) then
                  tex.sprint("\\gridRows=4\\relax")
                  tex.sprint("\\setlength\\@t@calendar@gridHeight{\\@t@calendar@gridHeightFourRows}")
                else
                  tex.sprint("\\gridRows=5\\relax")
                  tex.sprint("\\setlength\\@t@calendar@gridHeight{\\@t@calendar@gridHeightFiveRows}")
                end
              }%
            }{%
              \gridRows=5%
              \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightFiveRows}%
            }%
          \fi
        }{%
          % Monday-first: 6 rows if 1st is Sun. Sunday-first: 6 rows if 1st is Sat.
          \ifsundayFirst
            \ifdate{Saturday}{%
              \gridRows=6%
              \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightSixRows}%
            }{%
              \gridRows=5%
              \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightFiveRows}%
            }
          \else
            \ifdate{Sunday}{%
              \gridRows=6%
              \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightSixRows}%
            }{%
              \gridRows=5%
              \setlength\@t@calendar@gridHeight{\@t@calendar@gridHeightFiveRows}%
            }
          \fi
        }
      }
      %
      % Horizontal lines
      %
      \gridLines=\gridRows
      \ifgridSurround
        \advance\gridLines by 1
        \n=0
        \draw [
          gridcolor,
          line width=0.3pt,
          xshift=-0.5\@t@calendar@dayXshift,
          yshift=0.5\@t@calendar@dayYshift,
        ] (0,{-\n\@t@calendar@dayYshift}) -- (7\@t@calendar@dayXshift,{-\n\@t@calendar@dayYshift});
      \fi
      \foreach \n in {1,2,3,4,5,6} {
        \ifnum\n<\gridLines
          \draw [
            gridcolor,
            line width=0.3pt,
            xshift=-0.5\@t@calendar@dayXshift,
            yshift=0.5\@t@calendar@dayYshift,
          ] (0,{-\n\@t@calendar@dayYshift}) -- (7\@t@calendar@dayXshift,{-\n\@t@calendar@dayYshift});
        \fi
      }
      %
      % Vertical lines
      %
      \gridLines=7
      \ifgridSurround
        \advance\gridLines by 1
        \n=0
        \draw [
          gridcolor,
          line width=0.3pt,
          xshift=-0.5\@t@calendar@dayXshift,
          yshift=0.5\@t@calendar@dayYshift,
        ] ({\n\@t@calendar@dayXshift},0) -- ({\n\@t@calendar@dayXshift},{-\gridRows\@t@calendar@dayYshift});
      \fi
      \foreach \n in {1,2,3,4,5,6,7} {
        \ifnum\n<\gridLines
          \draw [
            gridcolor,
            line width=0.3pt,
            xshift=-0.5\@t@calendar@dayXshift,
            yshift=0.5\@t@calendar@dayYshift,
          ] ({\n\@t@calendar@dayXshift},0) -- ({\n\@t@calendar@dayXshift},{-\gridRows\@t@calendar@dayYshift});
        \fi
      }
      %
      % If we are not drawing the surrounding lines, it looks better to hide
      % some of the top and bottom edges
      %
      \ifgridSurround\relax
      \else
        \draw [
          color=white,
          line width=6pt,
          xshift=-0.5\@t@calendar@dayXshift,
          yshift={0.5\@t@calendar@dayYshift -1pt},
        ] (0,0) -- (7\@t@calendar@dayXshift,0);
        \draw [
          color=white,
          line width=6pt,
          xshift=-0.5\@t@calendar@dayXshift,
          yshift={0.5\@t@calendar@dayYshift +1pt},
        ] (0,-\gridRows\@t@calendar@dayYshift) -- (7\@t@calendar@dayXshift,-\gridRows\@t@calendar@dayYshift);
      \fi
    }{}%
  }
]

\tikzstyle{headings background rule}=[
  background rule/.style={black!90, line width=0.3pt, yshift={0.3\@t@calendar@dayYshift -3pt}},
  execute before day scope={%
    \ifdate{day of month=1}{%
      \draw [
        xshift=-0.5\@t@calendar@dayXshift,
        yshift=0.5\@t@calendar@dayYshift,
        background rule,
      ] (0,0) -- (7\@t@calendar@dayXshift,0);
    }{}%
  }
]

\tikzstyle{headings background bar}=[
  headings background rule,
  background rule/.style={black!20, line width=10pt, yshift={0.3\@t@calendar@dayYshift +3.5pt}},
]

% week list sunday: a variant of TikZ's week list that starts weeks on Sunday.
% Based on https://texample.net/tikz/examples/changing-the-default-calendar-layout/
\tikzstyle{week list sunday}=[
  execute before day scope={%
    \ifdate{day of month=1}{\ifdate{equals=\pgfcalendarbeginiso}{}{%
      \pgfmathsetlength{\pgf@y}{\tikz@lib@cal@month@yshift}%
      \pgftransformyshift{-\pgf@y}%
    }}{}%
  },
  execute at begin day scope={%
    \pgfmathsetlength\pgf@x{\tikz@lib@cal@xshift}%
    \ifnum\pgfcalendarcurrentweekday=6
      \c@pgf@counta=0
    \else
      \c@pgf@counta=\pgfcalendarcurrentweekday
      \advance\c@pgf@counta by 1
    \fi
    \pgf@x=\c@pgf@counta\pgf@x
    \pgftransformxshift{\pgf@x}%
  },
  execute after day scope={%
    \ifdate{Saturday}{%
      \pgfmathsetlength{\pgf@y}{\tikz@lib@cal@yshift}%
      \pgftransformyshift{-\pgf@y}%
    }{}%
  },
  tikz@lib@cal@width=7
]

\tikzstyle{betelgeuse}=[
  days grid,
  \@wall@weekListStyle,
  day xshift=\@t@calendar@dayXshift,
  day yshift=\@t@calendar@dayYshift,
  headings background bar,
  day letter headings,
  day heading/.style={black!90, yshift={-0.3\@t@calendar@dayYshift}},
  every day/.append style={anchor=base, inner xsep=0pt, yshift={-0.25\baselineskip}},
  day text={\dayTextFmt\%d-},
]

% #1 : day node name to position at, \pgfcalendarsuggestedname in the day code block
% #2 : this node name postfix, -daynumber in the day code block
% #3 : day number, use \tikzdaytext in the day code block
\newcommand*\calDayNumberNode[3]{%
    \node (#1#2) [
      below right=3.5pt and 8pt of #1.north west,
      anchor=north west,
      inner sep=0pt,
    ] {#3};
}

\tikzstyle{rigel}=[
  days grid,
  \@wall@weekListStyle,
  day xshift=\@t@calendar@dayXshift,
  day yshift=\@t@calendar@dayYshift,
  day fullday headings,
  day heading/.style={black!90, yshift={-0.3\@t@calendar@dayYshift}},
  every day/.append style={anchor=base, inner xsep=0pt, yshift={-0.25\baselineskip}},
  execute at begin day scope={
    \ifdate{Sunday}{\def\dayLetterColor{\color{sunday}}}{\def\dayLetterColor{\color{weekday}}}%
  },
  day text={\dayTextFmt\dayLetterColor\%d-},
  day code={%
    \node [
      minimum width=\@t@calendar@dayXshift,
      minimum height=\@t@calendar@dayYshift,
      name=\pgfcalendarsuggestedname,
      every day,
    ] {};%
    \calDayNumberNode{\pgfcalendarsuggestedname}{-daynumber}{\tikzdaytext}%
  },
]

\tikzstyle{aldebaran}=[
  days grid,
  \@wall@weekListStyle,
  day xshift=\@t@calendar@dayXshift,
  day yshift=\@t@calendar@dayYshift,
  day letter headings,
  day heading/.style={black!90, yshift={-0.3\@t@calendar@dayYshift}},
  every day/.append style={anchor=base, inner xsep=0pt, yshift={-0.25\baselineskip}},
  day text={\dayTextFmt\%d-},
]

\tikzstyle{alnitak}=[
  day list right,
  day xshift={0pt},
  every month/.append style={anchor=base, inner xsep=0pt, yshift=4mm, xshift=-\widthof{\space}},
  day text={\dayTextFmt\%d-},
  every day/.append style={anchor=base, inner xsep=0pt},
  execute before day scope={
    %
    % === Moving the day number ===
    %
    % A small offset seems to improve the result, the last day gets closer to the end of the linewidth
    \pgftransformxshift{0.01em}
    \pgfcalendarjuliantodate{\pgfcalendarendjulian}{\currentyear}{\currentmonth}{\lastday}
    % Width of month day digits from 1 - 28
    \setlength{\@tmp@a}{\widthof{12345678910111213141516171819202122232425262728}}
    \setlength{\@tmp@b}{\widthof{30}}
    \pgfmathparse{(\linewidth - \@tmp@a - \@tmp@b * (\lastday-28)) / \lastday}
    \pgftransformxshift{\pgfmathresult}
    \let\%=\pgfcalendarshorthand
    \setlength{\@tmp@a}{\widthof{\%d-}}
    \pgftransformxshift{\@tmp@a}
    %
    % === Weekday letter above the day ===
    %
    \ifdate{weekend}{\def\dayLetterColor{\color{weekend}}}{\def\dayLetterColor{\color{weekday}}}%
    \node[anchor=base,yshift=5.5mm,inner sep=0pt]{%
      \dayLetterColor\dayLetterFmt\@tr@dayLetter{\pgfcalendarcurrentweekday}%
    };%
  },
]

\newcommand\plannerPortraitMonthFmt{\fontsize{13}{13}\selectfont\color{darkgold}}
\newcommand\plannerPortraitDayFmt{\fontsize{12}{12}\selectfont\color{plannerdatenum}}

\tikzstyle{year planner portrait}=[
  \@wall@weekListStyle,
  day xshift=20pt,
  day yshift=18pt,
  month text={\plannerPortraitMonthFmt\@tr@monthNumName{\pgfcalendarcurrentmonth}},
  day text={\plannerPortraitDayFmt\%d-},
  every month/.append style={%
    anchor=south,
    inner xsep=0pt,
    yshift=5mm,
    xshift=2.5mm,
  },
  day letter headings,
  day heading/.style={gray, xshift=0pt, scale=0.85},
  month label above centered,
  every day/.style={anchor=mid},
]

\newcommand\plannerLandscapeDateDayFont{}
\newcommand\plannerLandscapeDayFont{}
\newcommand\plannerLandscapeMonthFont{}

\newcommand\plannerLandscapeMonthFmt{%
  \plannerLandscapeMonthFont%
  \fontsize{15}{18}\selectfont%
  \color{gold}\bfseries%
}

\newcommand\plannerLandscapeDayFmt{%
  \plannerLandscapeDayFont%
  \fontsize{11}{12}\selectfont%
}

\newcommand*\plannerLandscapeDateDayFormat[1]{%
  \plannerLandscapeDateDayFont%
  \fontsize{8}{11}\selectfont%
  #1%
}

\newcommand\plannerLandscapeBeginDayScopeHook{%
  \ifdate{weekend}{\color{black!60}}{}
}

\newlength\plannerLandscapeDayXShift
\newlength\plannerLandscapeMonthYShift

% Assuming 25mm to fit 'September'
\setlength{\@tmp@a}{\calPaperWidth - \@wall@leftMargin - \@wall@rightMargin - 25mm}
% Max week shift is 6 = Sunday. 31 days + 6 = 37. 1/37 = 0.027
\setlength{\plannerLandscapeDayXShift}{0.027\@tmp@a}

% Assuming 10mm for day headings (M T W...) and some padding
\setlength{\@tmp@a}{\calPaperHeight - \@wall@topMargin - \@wall@bottomMargin - 10mm}
% 1/12 = 0.0833
\setlength{\plannerLandscapeMonthYShift}{0.0833\@tmp@a}

\tikzstyle{year planner landscape}=[
  month list,
  day xshift=\plannerLandscapeDayXShift,
  month yshift=\plannerLandscapeMonthYShift,
  every month/.append style={anchor=base, inner xsep=0pt},
  month text={\plannerLandscapeMonthFmt \%mt},
  day text={\plannerLandscapeDayFmt \%d-},
  every day/.append style={anchor=base, inner xsep=0pt},
  month label left,
  execute at begin day scope={
    \plannerLandscapeBeginDayScopeHook
    % Week divider line at end of week as a thin rectangle
    % Sunday-first: divider after Saturday (weekday 5). Monday-first: after Sunday (weekday 6).
    \ifsundayFirst \n=5\else \n=6\fi
    \ifnum\pgfcalendarcurrentweekday=\n
      \node[
        rectangle,
        inner sep=0pt,
        minimum width={0.4pt},
        minimum height={\plannerLandscapeMonthYShift},
        xshift={0.5\plannerLandscapeDayXShift},
        yshift=2pt,
        draw=none,
        fill=black!80,
        ]{};%
    \fi
    % Weekday headers in January
    \ifdate{between=01-01 and 01-31}{
      \def\l{\ifcase\pgfcalendarcurrentweekday M\or T\or W\or T\or F\or S\or S\fi}%
      \ifdate{weekend}{\def\daylabelcolor{weekend}}{\def\daylabelcolor{weekday}}%
      \node[anchor=south,yshift=5mm,inner sep=0pt]{\color{\daylabelcolor}\plannerLandscapeDateDayFormat{\l}};%
    }{}
    % Weekday headers in December
    \ifdate{between=12-01 and 12-31}{
      \pgftransformyshift{-3mm}%
      \def\l{\ifcase\pgfcalendarcurrentweekday M\or T\or W\or T\or F\or S\or S\fi}%
      \ifdate{weekend}{\def\daylabelcolor{weekend}}{\def\daylabelcolor{weekday}}%
      \node[anchor=south,yshift=5mm,inner sep=0pt]{\color{\daylabelcolor}\plannerLandscapeDateDayFormat{\l}};%
    }{}
  }
]

\newcommand\plannerGridMonthFont{}
\newcommand\plannerGridDateDayFont{}
\newcommand\plannerGridNotesFont{}
\newcommand\plannerGridDayFont{}
\newcommand\plannerGridYearNumberFont{}

\newcommand\plannerGridYearNumberFmt{%
  \plannerGridYearNumberFont%
  \fontsize{11}{11}\selectfont%
  \color{white}%
}

\newcommand\plannerGridMonthFmt{%
  \plannerGridMonthFont%
  \fontsize{9.5}{9.5}\selectfont%
  \color{white}%
}

\newcommand\plannerGridDayFmt{%
  \plannerGridDayFont%
  \fontsize{10.5}{10.5}\selectfont%
}

\newcommand\plannerGridDateDayFmt{%
  \plannerGridDateDayFont%
  \fontsize{8.5}{8.5}\selectfont%
  \color{black!80}%
}

\newcommand{\plannerGridNotesFmt}{%
  \plannerGridNotesFont%
  \fontsize{9}{9}\selectfont%
}

\newcommand\plannerGridBeginDayScopeHook{%
  \ifdate{weekend}{\color{black!60}}{}
}

\newlength\plannerGridColXShift
\newlength\plannerGridRowYShift

\newlength\plannerGridCalendarWidth
\newlength\plannerGridCalendarHeight

\newlength\plannerGridDayHeadingsHeight
\newlength\plannerGridMonthNamesWidth

\newlength\plannerGridNotesHeight
\setlength{\plannerGridNotesHeight}{7mm}
\setlength{\plannerGridDayHeadingsHeight}{5mm}
\setlength{\plannerGridMonthNamesWidth}{5mm}

\setlength{\plannerGridCalendarWidth}{\calPaperWidth - \@wall@leftMargin - \@wall@rightMargin - \plannerGridMonthNamesWidth}
\setlength{\plannerGridCalendarHeight}{\calPaperHeight - \@wall@topMargin - \@wall@bottomMargin - \plannerGridNotesHeight}

\setlength{\@tmp@a}{\plannerGridCalendarWidth - \plannerGridMonthNamesWidth}
% 37 columns. 1/37 = 0.027. Max week shift is 6 = Sunday. 31 days + 6 = 37.
\setlength{\plannerGridColXShift}{0.027\@tmp@a}

\setlength{\@tmp@a}{\plannerGridCalendarHeight - 2\plannerGridDayHeadingsHeight}
% 12 rows. 1/12 = 0.0833
\setlength{\plannerGridRowYShift}{0.0833\@tmp@a}

\newcounter{verticalCount}

\tikzstyle{year planner landscape grid days}=[
  month list,
  day xshift=\plannerGridColXShift,
  month yshift=\plannerGridRowYShift,
  day text={\plannerGridDayFmt \%d-},
  every day/.append style={anchor=base, yshift=-4pt, inner xsep=0pt},
  execute at begin day scope={%
    % White fill to cover the page background color
    \node (cell) [
      rectangle,
      fill = white,
      minimum height = \plannerGridRowYShift - 1pt,
      minimum width = \plannerGridColXShift - 1pt,
      xshift = -0.5\plannerGridColXShift,
      yshift = 4.5pt,
    ] {};%
    %
    % Week start marker (left triangle). Monday-first: Monday (0). Sunday-first: Sunday (6).
    \ifsundayFirst \n=6\else \n=0\fi
    \ifnum\pgfcalendarcurrentweekday=\n
      \node (a) [above left = 10pt and -3.5pt of cell.west] {};
      \node (b) [below left = 10pt and -3.5pt of cell.west] {};
      \node (c) [right = 5pt of cell.west] {};
      \path [on layer = one, fill = pagebgcolor] (a.south) -- (b.north) -- (c.west) -- (a.south);%
    \fi
    %
    % Week end marker (right triangle). Monday-first: Sunday (6). Sunday-first: Saturday (5).
    \ifsundayFirst \n=5\else \n=6\fi
    \ifnum\pgfcalendarcurrentweekday=\n
      \node (a) [above left = 10pt and {-3.5pt + 0.6pt} of cell.east] {};
      \node (b) [below left = 10pt and {-3.5pt + 0.6pt} of cell.east] {};
      \node (c) [right = {5pt - 0.6pt} of cell.east] {};
      \path [on layer = two, fill = white] (a.south) -- (b.north) -- (c.west) -- (a.south);%
    \fi
    %
    \plannerGridBeginDayScopeHook%
  },
]

\newcommand\pf{\fontsize{8}{8}\selectfont}
\newcommand\plannerCompactDayFmt{\fontsize{9}{9}\selectfont}
\newcommand\plannerCompactMonthFmt{\bfseries\fontsize{10}{10}\selectfont\color{month}}
\newcommand\plannerCompactYearFmt{\plannerCompactMonthFmt}
\newcommand\plannerCompactWeekNumFmt{\itshape\fontsize{7}{7}\selectfont\color{plannerdatenum}}

\newcommand*\plannerCompactDateDayFormat[1]{\fontsize{8}{11}\selectfont #1}
 
\newcommand\plannerCompactBeginDayScopeHook{%
  \ifdate{weekend}{\color{weekend}}{\color{weekday}}
}

\newcount\weeknum

\newif\ifstartswithlastyear

\luadirect{
require("wallcalendar-helpers.lua")
setStartsWithLastYear(\luastring{\CalendarYear})}

\tikzstyle{year planner compact}=[
  \@wall@weekListStyle,
  month yshift=0pt,
  day text={\plannerCompactDayFmt\%d-},
  every day/.style={anchor=mid},%
  %
  execute before day scope={%
    %
    % Month corner node
    %
    \ifdate{day of month=1}{%
      \node (month-\pgfcalendarcurrentmonth-top-left) {};
    }{}
    %
    % Year number
    %
    \ifdate{equals=01-01}{%
      \node [
        above left = \tikz@lib@cal@yshift and 35pt of month-01-top-left.north west,
        inner sep = 0pt,
        anchor = south east,
      ] {\plannerCompactYearFmt\CalendarYear};%
    }{}
    %
    % Weekday headers in January
    %
    \ifdate{equals=01-01}{%
      \weeknum=1
      \pgfmathsetlength\pgf@xa{\tikz@lib@cal@xshift}%
      \pgfmathsetlength\pgf@ya{\tikz@lib@cal@yshift}%
      \foreach \d in {0,1,2,3,4,5,6} {%
        \pgf@xa=\d\pgf@xa%
        \pgftransformxshift{\pgf@xa}%
        \pgftransformyshift{\pgf@ya}%
        \pgftransformyshift{4pt}%
        \node (d\d) [anchor=base, inner sep=0pt] {%
          \ifsundayFirst
            % Sunday-first: column 0 = Sunday (weekend), column 6 = Saturday (weekend)
            \ifnum\d=0
              \plannerCompactDateDayFormat{\color{weekend}\@tr@columnDayLetter{\d}}%
            \else
              \ifnum\d=6
                \plannerCompactDateDayFormat{\color{weekend}\@tr@columnDayLetter{\d}}%
              \else
                \plannerCompactDateDayFormat{\@tr@columnDayLetter{\d}}%
              \fi
            \fi
          \else
            % Monday-first: columns 5,6 = Saturday,Sunday (weekend)
            \ifnum\d=5
              \plannerCompactDateDayFormat{\color{weekend}\@tr@columnDayLetter{\d}}%
            \else
              \ifnum\d=6
                \plannerCompactDateDayFormat{\color{weekend}\@tr@columnDayLetter{\d}}%
              \else
                \plannerCompactDateDayFormat{\@tr@columnDayLetter{\d}}%
              \fi
            \fi
          \fi
        };%
      };%
    }{}%
    %
    % Week number
    % Determine the weekday that starts a new week row
    \ifsundayFirst \n=6\else \n=0\fi
    \ifnum\pgfcalendarcurrentweekday=\n
      \node [
        anchor = east,
        xshift = -13pt,
        yshift = -0.5pt,
        inner sep = 0pt,
      ] {\parbox{6mm}{\centering\plannerCompactWeekNumFmt \the\weeknum.}};
      \advance\weeknum by 1
    \fi
    % When first week doesn't start on the first day of the week
    \ifdate{equals=01-01}{%
      \ifnum\pgfcalendarcurrentweekday=\n\relax
      \else
        \ifstartswithlastyear
          \node [
            anchor = east,
            xshift = -13pt,
            yshift = -0.5pt,
            inner sep = 0pt,
          ] {\parbox{6mm}{\centering\plannerCompactWeekNumFmt 53.}};
        \else
          \node [
            anchor = east,
            xshift = -13pt,
            yshift = -0.5pt,
            inner sep = 0pt,
          ] {\parbox{6mm}{\centering\plannerCompactWeekNumFmt \the\weeknum.}};
          \advance\weeknum by 1
        \fi
      \fi
    }{}%
  },%
  %
  execute at begin day scope={%
    %
    % Month name
    %
    \ifdate{day of month=1}{%
      \node [
        below left = 0pt and 35pt of month-\pgfcalendarcurrentmonth-top-left.north west,
        inner sep = 0pt,
        anchor = north west,
        rotate = -90,
      ] {%
        \plannerCompactMonthFmt\@tr@monthNumName{\pgfcalendarcurrentmonth}%
      };
    }{}
    %
    % Draw border lines between months
    %
    \ifdate{day of month=1}{%
      \ifdate{equals=01-01}{%
        % Don't draw border in January
      }{%
        \pgfmathsetlength\pgf@xa{\tikz@lib@cal@xshift}
        \pgfmathsetlength\pgf@ya{\tikz@lib@cal@yshift}
        %
        % Compute column index from weekday
        \ifsundayFirst
          \ifnum\pgfcalendarcurrentweekday=6 \n=0\else
            \n=\pgfcalendarcurrentweekday \advance\n by 1
          \fi
        \else
          \n=\pgfcalendarcurrentweekday
        \fi
        % No bottom and left edge when day is in the first column
        \ifnum\n=0\relax
        \else
          %
          % Bottom border, from left side to the number
          \draw [
            gridcolor,
            line width = 0.5pt,
          ] ({-\n\pgf@xa -0.5\pgf@xa}, -0.5\pgf@ya) -- (-0.5\pgf@xa, -0.5\pgf@ya);
          % Vertical edge on the left side of the number
          \draw [
            gridcolor,
            line width = 0.5pt,
          ] (-0.5\pgf@xa, 0.5\pgf@ya + 0.25pt) -- (-0.5\pgf@xa, -0.5\pgf@ya - 0.25pt);
        \fi
        %
        % Top border, from the number to the right side
        \advance \n by -6
        \draw [
          gridcolor,
          line width = 0.5pt,
        ] (-0.5\pgf@xa, 0.5\pgf@ya) -- ({-\n\pgf@xa +0.5\pgf@xa}, 0.5\pgf@ya);
      }%
    }{}%
    %
    \plannerCompactBeginDayScopeHook
  },
]

\newcommand\plannerMarksDayTextCSV{\@wall@eventsCsv}
\newcommand\plannerMarksNoteCSV{\@wall@eventsCsv}
\newcommand\plannerMoonsCSV{\@wall@moonsCsv}
\newcommand\plannerMarkDefaultsCsv{}

\newcommand\@wall@plm[1]{%
\luadirect{
require("wallcalendar-helpers.lua")
monthMarksDayText(\luastring{#1}, nil, \luastring{\plannerMarksDayTextCSV})
monthMarksDayText(\luastring{#1}, nil, \luastring{\plannerMoonsCSV})
tex.sprint(';')
}}

\newcommand\@wall@plmYear{%
\luadirect{
require("wallcalendar-helpers.lua")
yearMarksDayText(tonumber(\CalendarYear), nil, \luastring{\plannerMarksDayTextCSV})
yearMarksDayText(tonumber(\CalendarYear), nil, \luastring{\plannerMoonsCSV})
tex.sprint(';')
if isEqual(\luastring{\@wall@dateAnnotationsStr}, "true") then
  drawAnnotations(tonumber(\CalendarYear), nil, \luastring{\plannerMarksDayTextCSV})
end
}}

\newcommand\@wall@plNotes{%
\luadirect{
require("wallcalendar-helpers.lua")
yearMarksNote(tonumber(\CalendarYear), nil, \luastring{\plannerMarksNoteCSV}, \luastring{\plannerMarkDefaultsCsv}, false)
}}

\newcommand\@wall@plNotesOneCalendar{%
\luadirect{
require("wallcalendar-helpers.lua")
yearMarksNote(tonumber(\CalendarYear), nil, \luastring{\plannerMarksNoteCSV}, \luastring{\plannerMarkDefaultsCsv}, true)
}}

\newcommand\plannerEvents{%
\parseYearEvents[filter pred = hasFootnote]%
}

\newcommand\plannerWeeklyNotes{%
\luadirect{
require("wallcalendar-helpers.lua")
plannerWeeklyNotes(tonumber(\CalendarYear), nil, \luastring{\plannerMarksDayTextCSV})
}}

\newcommand\plannerWeeklyImages{%
\luadirect{
require("wallcalendar-helpers.lua")
plannerWeeklyImages(tonumber(\CalendarYear), nil, \luastring{\plannerMarksDayTextCSV})
}}

% \varul<gap-width>[below-depth][line-thickness]{text}
% https://tex.stackexchange.com/questions/36894/underline-omitting-the-descenders

\ExplSyntaxOn
\cs_new:Npn \white_text:n #1
{
  \fp_set:Nn \l_tmpa_fp {#1 * .01}
  \llap{\textcolor{white}{\the\SOUL@syllable}\hspace{\fp_to_decimal:N \l_tmpa_fp em}}
  \llap{\textcolor{white}{\the\SOUL@syllable}\hspace{-\fp_to_decimal:N \l_tmpa_fp em}}
}
\NewDocumentCommand{\whiten}{ m }
{
  \int_step_function:nnnN {1}{1}{#1} \white_text:n
}
\ExplSyntaxOff

\NewDocumentCommand{ \varul }{ D<>{5} O{0.3ex} O{0.1ex} +m } {%
  \begingroup
  \setul{#2}{#3}%
  \def\SOUL@uleverysyllable{%
    \setbox0=\hbox{\the\SOUL@syllable}%
    \ifdim\dp0>\z@
    \SOUL@ulunderline{\phantom{\the\SOUL@syllable}}%
    \whiten{#1}%
    \llap{%
      \the\SOUL@syllable
      \SOUL@setkern\SOUL@charkern
    }%
    \else
    \SOUL@ulunderline{%
      \the\SOUL@syllable
      \SOUL@setkern\SOUL@charkern
    }%
    \fi}%
  \ul{#4}%
  \endgroup
}

\def\@wall@oneWeekNotes@fontSize{9}
\def\@wall@oneWeekNotes@lineHeight{14.55}
\newcommand\oneWeekNotesSize{\@setfontsize\oneWeekNotesSize{\@wall@oneWeekNotes@fontSize}{\@wall@oneWeekNotes@lineHeight}}

\newlength\oneNoteSkip
\newlength\oneImageSkip
\setlength{\oneNoteSkip}{\@wall@oneWeekNotes@lineHeight pt}
\setlength{\oneImageSkip}{\oneNoteSkip}

\newcommand\oneWeekNotesSep{}
\newcommand\oneWeekImagesSep{}

% #1 = (opt) color
% #2 = text
\newcommand*\colorUL[2][textbody]{%
  \setulcolor{#1}%
  \varul{#2}%
  \setulcolor{textbody}%
}

% #1 = color
% #2 = week number
% #3 = date string
% #4 = text
\newcommand\oneNote[4]{%
  \ifstrequal{#3}{}{%
    #4\quad%
  }{%
    \colorUL[#1]{#3} #4\quad%
  }%
}

% #1 = week number
% #2 = combined text
\newcommand\oneWeekNotes[2]{%
  \node [
    below left = {#1\oneNoteSkip} and 0pt of bg.north east,
    anchor = north east,
    inner sep = 0pt,
  ] {%
    \begin{minipage}{\linewidth}%
      \raggedright%
      \setlength{\parindent}{0pt}%
      \oneWeekNotesSize\selectfont%
      #2%
    \end{minipage}%
  };%
}

% #1 = (opt) image options
% #2 = week number
% #3 = image path
\newcommand\oneImage[3][width=20mm]{%
  \node [
    below left = {#2\oneImageSkip} and 0pt of bg.north east,
    anchor = north east,
    inner sep = 0pt,
  ] {%
    \includegraphics[#1]{#3}%
  };%
}

\newcommand\YearPlannerPortrait{%
\@wall@useDefaultMoons%
\begin{tikzpicture}[every calendar/.style={year planner portrait}]%
  \matrix[column sep=1.5em, row sep=5mm] {
    \calendar(cal01)[dates=\CalendarYear-01-01 to \CalendarYear-01-last] \@wall@plm{January};   \pgfmatrixnextcell
    \calendar(cal02)[dates=\CalendarYear-02-01 to \CalendarYear-02-last] \@wall@plm{February};  \pgfmatrixnextcell
    \calendar(cal03)[dates=\CalendarYear-03-01 to \CalendarYear-03-last] \@wall@plm{March};     \\
    \calendar(cal04)[dates=\CalendarYear-04-01 to \CalendarYear-04-last] \@wall@plm{April};     \pgfmatrixnextcell
    \calendar(cal05)[dates=\CalendarYear-05-01 to \CalendarYear-05-last] \@wall@plm{May};       \pgfmatrixnextcell
    \calendar(cal06)[dates=\CalendarYear-06-01 to \CalendarYear-06-last] \@wall@plm{June};      \\
    \calendar(cal07)[dates=\CalendarYear-07-01 to \CalendarYear-07-last] \@wall@plm{July};      \pgfmatrixnextcell
    \calendar(cal08)[dates=\CalendarYear-08-01 to \CalendarYear-08-last] \@wall@plm{August};    \pgfmatrixnextcell
    \calendar(cal09)[dates=\CalendarYear-09-01 to \CalendarYear-09-last] \@wall@plm{September}; \\
    \calendar(cal10)[dates=\CalendarYear-10-01 to \CalendarYear-10-last] \@wall@plm{October};   \pgfmatrixnextcell
    \calendar(cal11)[dates=\CalendarYear-11-01 to \CalendarYear-11-last] \@wall@plm{November};  \pgfmatrixnextcell
    \calendar(cal12)[dates=\CalendarYear-12-01 to \CalendarYear-12-last] \@wall@plm{December};  \\
  };
  \@wall@plNotes
\end{tikzpicture}%
}

\newcommand\YearPlannerLandscape{%
\@wall@usePlannerMoons%
\begin{tikzpicture}%
  \calendar (cal) [
    year planner landscape,
    dates=\CalendarYear-01-01 to \CalendarYear-12-31,
  ] \@wall@plmYear;
  \@wall@plNotesOneCalendar
\end{tikzpicture}%
}

\newcommand\YearPlannerLandscapeGrid{%
\@wall@usePlannerMoons%
\begin{tikzpicture}

  % Background frame

  \node (bg) [
    rectangle,
    inner sep = 0pt,
    minimum width = \plannerGridCalendarWidth,
    minimum height = \plannerGridCalendarHeight,
  ] {};

  \foreach \x/\m in {1/\xJanShort, 2/\xFebShort, 3/\xMarShort, 4/\xAprShort,
    5/\xMayShort, 6/\xJunShort, 7/\xJulShort, 8/\xAugShort, 9/\xSepShort,
    10/\xOctShort, 11/\xNovShort, 12/\xDecShort}
  {
    \setlength{\@tmp@a}{\x\plannerGridRowYShift + \plannerGridDayHeadingsHeight}

    % Month labels

    \node [
      below = \@tmp@a of bg.north west,
      yshift = 0.5\plannerGridRowYShift - 2pt,
      xshift = 0.5\plannerGridColXShift - 2pt,
      anchor = base,
      rotate = 90,
    ] {\plannerGridMonthFmt\MakeUppercase{\textls*{\m}}};

    % Horizontal lines

    \addtolength{\@tmp@a}{-\plannerGridRowYShift}

    \node (h-a-\x) [below = \@tmp@a of bg.north west] {};
    \node (h-b-\x) [below = \@tmp@a of bg.north east] {};
    \draw [gridcolor] (h-a-\x) -- (h-b-\x);
  }

  % 13th line
  \setlength{\@tmp@a}{12\plannerGridRowYShift + \plannerGridDayHeadingsHeight}
  \node (h-a-13) [below = \@tmp@a of bg.north west] {};
  \node (h-b-13) [below = \@tmp@a of bg.north east] {};
  \draw [gridcolor] (h-a-13) -- (h-b-13);

  % Year number in the corner
  \node [
    below right = -1pt and -5pt of bg.north west,
    xshift = 0.5\plannerGridMonthNamesWidth,
    yshift = -0.5\plannerGridDayHeadingsHeight,
    anchor = north west,
    inner sep = 0pt,
  ] {\plannerGridYearNumberFmt\CalendarYear};

  \setcounter{verticalCount}{1}

  \foreach \i in {0,1,2,3,4,5} {
    \foreach \j/\d in {
      0/\xMondayDayLetter,
      1/\xTuesdayDayLetter,
      2/\xWednesdayDayLetter,
      3/\xThursdayDayLetter,
      4/\xFridayDayLetter,
      5/\xSaturdayDayLetter,
      6/\xSundayDayLetter}
    {
      \addtocounter{verticalCount}{1}
      \ifnumgreater{\value{verticalCount}}{38}{\relax}{
        \setlength{\@tmp@a}{7\plannerGridColXShift}
        \setlength{\@tmp@a}{\i\@tmp@a + \j\plannerGridColXShift + \plannerGridMonthNamesWidth}

        % Day headings (top and bottom)
        
        \node [
          right = \@tmp@a of bg.north west,
          xshift = 0.5\plannerGridColXShift + 4pt,
          yshift = -0.5\plannerGridDayHeadingsHeight - 5pt,
          anchor = base,
        ] {\plannerGridDateDayFmt \d};

        \node [
          right = \@tmp@a of bg.south west,
          xshift = 0.5\plannerGridColXShift + 4pt,
          yshift = 0.5\plannerGridDayHeadingsHeight - 5pt,
          anchor = base,
        ] {\plannerGridDateDayFmt \d};

        % % Vertical lines

        % \node (v-a-\i-\j) [right = \@tmp@a of bg.north west] {};
        % \node (v-b-\i-\j) [right = \@tmp@a of bg.south west] {};
        % \draw [gridcolor] (v-a-\i-\j) -- (v-b-\i-\j);
      }
    }
  }

  \calendar (cal) [
    year planner landscape grid days,
    dates=\CalendarYear-01-01 to \CalendarYear-12-31,
    below right = 0pt and 0pt of bg.north west,
    anchor = north west,
    yshift = -\plannerGridDayHeadingsHeight - 3mm,
    xshift = \plannerGridMonthNamesWidth + 0.5\plannerGridColXShift + 4pt,
  ] \@wall@plmYear;

  \@wall@plNotesOneCalendar

\end{tikzpicture}%
}

\newcommand{\YearPlannerLandscapeGridPage}{%
\pagecolor{pagebgcolor}%
\AddToShipoutPictureFG*{\put(\LenToUnit{\@wall@leftMargin},\LenToUnit{\@wall@bottomMargin})%
{\begin{minipage}[b]{\plannerGridCalendarWidth}%
\YearPlannerLandscapeGrid

\begin{minipage}[b][10mm][c]{\plannerGridCalendarWidth}%
\plannerGridNotesFmt
\hspace*{2mm}%
\parseYearEvents[%
  filter pred = hasFootnote,
  format cmd = {\textsuperscript{\eIdx}~\eMonthShort~\eDay:~\textit{\eFootnote}\ifnumless{\eIdx}{\eMaxIdx}{,\space}{.}},
]%
\end{minipage}%
\end{minipage}%
}}}

\newcommand\YearPlannerCompact{%
\@wall@usePlannerMoons%
\begin{tikzpicture}%
  \calendar (cal) [
    year planner compact,
    dates=\CalendarYear-01-01 to \CalendarYear-12-31,
  ] \@wall@plmYear;
  \@wall@plNotesOneCalendar
\end{tikzpicture}%
}

% #1 : image path
% #3 : background overlay height
% #3 : title text
\newcommand{\TitlePage}[3]{%
\mbox{}
\thispagestyle{empty}

\AddToShipoutPictureFG*{%
  \put(\LenToUnit{-3mm},\LenToUnit{-3mm}){%
    \begin{tikzpicture}
      \node (bg) [
        minimum width=\calPaperWidth + 6mm,
        minimum height=\calPaperHeight + 6mm,
      ] {%
        \includegraphics[height={\calPaperHeight + 6mm}]{#1}%
      };

      \node (title-bg) [
        minimum width=\calPaperWidth + 6mm,
        minimum height=#2,
        above left=0pt and 0pt of bg.center,
        anchor=center,
        fill=white,
        opacity=0.4,
      ] {};

      \node (title-text) [
        above left=0pt and 0pt of bg.center,
        anchor=center,
      ] {%
        \begin{minipage}{\calPaperWidth + 6mm}%
          \centering
          #3%
          \par
        \end{minipage}%
      };
    \end{tikzpicture}%
  }%
}%

}

% Load internal translations
\InputIfFileExists{i18n/wallcalendar-\@wall@calendarLanguage.tex}{}%
{\ClassError{wallcalendar}{File Not Found: i18n/wallcalendar-\@wall@calendarLanguage.tex}{}}

% Load user translations if the option was set and translationsAutoload is true

\newcommand\LoadTranslations{%
\InputIfFileExists{\@wall@translationsInputFile}{}%
{\ClassWarning{wallcalendar}{File Not Found: \@wall@translationsInputFile}{}}}

\notblank{\@wall@translationsInputFile}{%
\iftranslationsAutoload \LoadTranslations \fi}

\newcommand*\@tr@monthNumName[1]{%
\ifcase#1 \relax\or \xJanuary\or \xFebruary\or \xMarch\or \xApril\or \xMay\or \xJune\or
\xJuly\or \xAugust\or \xSeptember\or \xOctober\or \xNovember\or \xDecember\fi}

\newcommand*\@tr@dayLetter[1]{%
\ifcase#1 \xMondayDayLetter\or \xTuesdayDayLetter\or \xWednesdayDayLetter\or
\xThursdayDayLetter\or \xFridayDayLetter\or \xSaturdayDayLetter\or \xSundayDayLetter\fi}

\newcommand*\@tr@dayName[1]{%
\ifcase#1 \xMonday\or \xTuesday\or \xWednesday\or
\xThursday\or \xFriday\or \xSaturday\or \xSunday\fi}

% Column-to-day mapping for headings. When sundayFirst is active, column 0 is
% Sunday; otherwise column 0 is Monday (matching TikZ weekday numbering).
\newcommand*\@tr@columnDayLetter[1]{%
\ifsundayFirst
  \ifcase#1 \xSundayDayLetter\or \xMondayDayLetter\or \xTuesdayDayLetter\or \xWednesdayDayLetter\or
  \xThursdayDayLetter\or \xFridayDayLetter\or \xSaturdayDayLetter\fi
\else
  \@tr@dayLetter{#1}%
\fi}

\newcommand*\@tr@columnDayName[1]{%
\ifsundayFirst
  \ifcase#1 \xSunday\or \xMonday\or \xTuesday\or \xWednesday\or
  \xThursday\or \xFriday\or \xSaturday\fi
\else
  \@tr@dayName{#1}%
\fi}

\newcommand*{\monthToNum}[1]{%
\luadirect{
  local monthToNum = {
    january   = '01',
    february  = '02',
    march     = '03',
    april     = '04',
    may       = '05',
    june      = '06',
    july      = '07',
    august    = '08',
    september = '09',
    october   = '10',
    november  = '11',
    december  = '12',
  }
  local key = string.lower('#1')
  tex.sprint(monthToNum[key])
}}

\newcommand*\monthName[1]{%
% \ifcase might be just fine here
\luadirect{
  local monthName = {
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  }
  local key = tonumber('#1')
  tex.sprint(monthName[key])
}}

\SetPhoto{January}
\SetCalendar{January}
\SetQuote{January}{}
\SetEvents{January}{}{}
 
\SetPhoto{February}
\SetCalendar{February}
\SetQuote{February}{}
\SetEvents{February}{}{}
 
\SetPhoto{March}
\SetCalendar{March}
\SetQuote{March}{}
\SetEvents{March}{}{}
 
\SetPhoto{April}
\SetCalendar{April}
\SetQuote{April}{}
\SetEvents{April}{}{}
 
\SetPhoto{May}
\SetCalendar{May}
\SetQuote{May}{}
\SetEvents{May}{}{}
 
\SetPhoto{June}
\SetCalendar{June}
\SetQuote{June}{}
\SetEvents{June}{}{}
 
\SetPhoto{July}
\SetCalendar{July}
\SetQuote{July}{}
\SetEvents{July}{}{}
 
\SetPhoto{August}
\SetCalendar{August}
\SetQuote{August}{}
\SetEvents{August}{}{}
 
\SetPhoto{September}
\SetCalendar{September}
\SetQuote{September}{}
\SetEvents{September}{}{}
 
\SetPhoto{October}
\SetCalendar{October}
\SetQuote{October}{}
\SetEvents{October}{}{}
 
\SetPhoto{November}
\SetCalendar{November}
\SetQuote{November}{}
\SetEvents{November}{}{}
 
\SetPhoto{December}
\SetCalendar{December}
\SetQuote{December}{}
\SetEvents{December}{}{}

% End of wallcalendar.cls
