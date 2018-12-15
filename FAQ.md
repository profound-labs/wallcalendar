# Frequently Asked Questions

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Frequently Asked Questions](#frequently-asked-questions)
    - [How to use the wallcalendar package on Overleaf?](#how-to-use-the-wallcalendar-package-on-overleaf)
    - [How to insert a text only page?](#how-to-insert-a-text-only-page)
    - [How to change the margins and page layout?](#how-to-change-the-margins-and-page-layout)
    - [How to use other alphabets such as Cyrillic?](#how-to-use-other-alphabets-such-as-cyrillic)
    - [How to customize the fonts and point sizes?](#how-to-customize-the-fonts-and-point-sizes)
    - [How to position the month and year label?](#how-to-position-the-month-and-year-label)
    - [How to position the photo differently?](#how-to-position-the-photo-differently)
    - [How to change the colour of the day number?](#how-to-change-the-colour-of-the-day-number)
    - [How to change the size of the day number?](#how-to-change-the-size-of-the-day-number)

<!-- markdown-toc end -->

## How to use the wallcalendar package on Overleaf.com?

Keep in mind to set the compiler to `LuaLaTeX` in the project settings sidebar.

Example using Photo and Notes layout, `wallcalendar v1.4`:

- https://www.overleaf.com/read/hzjpfdmspwds
- https://github.com/profound-labs/wallcalendar-photo-and-notes-overleaf

Example using single page layouts, `wallcalendar v1.4`:

- https://www.overleaf.com/read/kjpcxcsmxkjc
- https://github.com/profound-labs/wallcalendar-portrait-layouts-overleaf

A template using `wallcalendar v1.3`:

- https://www.overleaf.com/read/yyvqfsbsmssm
- https://www.overleaf.com/latex/templates/wall-calendar/yyvqfsbsmssm 

## How to insert a normal text page?

## How to change the margins and page layout?

## How to use other alphabets such as Cyrillic?

I used DejaVu Sans without problems.

## How to customize the fonts and point sizes?

Each layout has a command where the formatting hooks can be redefined.

For example see main.tex#L41 where the month label is customized.

Fonts are loaded using the mechanisms of the fontspec package. In the example 'Josefin Sans' is loaded from an uploaded font file using \newfontfamily.

A Cyrillic font should work just the same, upload the file in your Overleaf project and adapt the JosefinSans example.

You will probably need to edit i18n/wallcalendar-serbian.tex to use Cyrillic text. Such as:

\def\xMonday{Понедељак}

Are the calendars in Serbia more commonly printed in Cyrillic than romanized?

If you wish to do so, submit a PR on Github to wallcalendar with Cyrillic Serbian labels.


## How to position the month and year label?

I see, to fix that one change the positioning directly at wallcalendar.cls#L1373

Either adjust the '10pt' of the heading, or lower down, the '35pt' of the calendar.

\node (heading) [
  below right=10pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
]

% ...

\node (calendar) [
  below right=35pt and {\@t@rightOffset} of bg.north west,
  anchor=north west,
]

Thanks for the Serbian labels, if cyrillics is what is considered default then I will use that in the wallcalendar package instead of the romanized.

## How to position the photo differently?

custom photo handler exmple

## How to change the colour of the day number?

- changing regular day color (sunday)
- changing specific date color

## How to change the size of the day number?

- changing formatting hooks

