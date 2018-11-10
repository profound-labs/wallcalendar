(require 'org)

(setq org-latex-classes
      '(("memoir-article" "\\documentclass[11pt,oneside]{memoir-article}\n[NO-DEFAULT-PACKAGES]\n[EXTRA]"
         ("\\chapter{%s}" . "\\chapter*{%s}")
         ("\\section{%s}" . "\\section*{%s}")
         ("\\subsection{%s}" . "\\subsection*{%s}")
         ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
         ("\\paragraph{%s}" . "\\paragraph*{%s}")
         ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))
