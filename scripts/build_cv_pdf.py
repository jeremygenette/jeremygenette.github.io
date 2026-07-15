#!/usr/bin/env python3
"""
build_cv_pdf.py

A dependency-light fallback that builds assets/cv.pdf directly with
pdflatex, reading the exact same source files as the R pipeline
(cv-pdf.qmd / R/build_cv_pdf.R):

  - _data/cv_data.yml   (education, positions, awards, grants, skills,
                          training, affiliations, references)
  - publications/, talks/, teaching/   (one .qmd file per entry)

Use this if you don't have the `fontawesome5` / `academicons` LaTeX
packages installed (this script uses plain-text symbols instead, so it
has no extra package requirements beyond a standard TeX Live install)
or don't want to set up R/Quarto just to refresh the CV. Once you do
have TinyTeX + those two packages, R/build_cv_pdf.R produces a closer
match to the original hand-written CV (icons instead of text labels)
from the *same* source files -- pick whichever fits your setup.

Usage:
    python3 scripts/build_cv_pdf.py
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent


def read_frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return {}
    fm = yaml.safe_load(m.group(1)) or {}
    fm["_body"] = m.group(2).strip()
    return fm


def read_collection(dirname: str):
    entries = []
    for f in sorted((ROOT / dirname).glob("*.qmd")):
        fm = read_frontmatter(f)
        if not fm:
            continue
        fm.setdefault("date", "1900-01-01")
        entries.append(fm)
    entries.sort(key=lambda e: str(e["date"]), reverse=True)
    return entries


def fmt_date(d) -> str:
    s = str(d)
    if s.endswith("-01-01"):
        return s[:4]
    try:
        import datetime
        dt = datetime.date.fromisoformat(s)
        return dt.strftime("%B %Y")
    except Exception:
        return s


def esc(s) -> str:
    if s is None:
        return ""
    s = str(s)
    s = s.replace("\\", r"\textbackslash{}")
    for ch in "&%$#_{}":
        s = s.replace(ch, "\\" + ch)
    return s


def block_rows(entries) -> str:
    out = []
    for e in entries:
        place = f" ({esc(e.get('place', ''))})" if e.get("place") else ""
        out.append(f"{esc(e['dates'])} & \\textbf{{{esc(e['title'])}}}{place} \\\\")
        detail = e.get("detail", "")
        if detail:
            detail = re.sub(r"\*(.+?)\*", r"\\textit{\1}", esc(detail).replace(r"\*", "*"))
            out.append(f" & {detail} \\\\")
        out.append(r"\\")
    return "\n".join(out)


def collection_rows(entries) -> str:
    out = []
    for e in entries:
        out.append(f"{fmt_date(e['date'])} & \\textbf{{{esc(e['title'])}}} \\\\")
        if e.get("subtitle"):
            out.append(f" & {esc(e['subtitle'])} \\\\")
        out.append(r"\\")
    return "\n".join(out)


def is_invited(entry) -> bool:
    cats = entry.get("categories") or []
    return any("invited" in str(c).lower() for c in cats)


def build():
    cv = yaml.safe_load((ROOT / "_data" / "cv_data.yml").read_text(encoding="utf-8"))
    publications = read_collection("publications")
    talks = read_collection("talks")
    invited = [t for t in talks if is_invited(t)]
    presentations = [t for t in talks if not is_invited(t)]
    teaching = read_collection("teaching")

    emails = cv["emails"]
    email_line = f"{esc(emails[0])}"
    if len(emails) > 1:
        email_line += f" and \\href{{mailto:{emails[1]}}}{{{esc(emails[1])}}}"

    tex = r"""
\documentclass[10pt]{article}
\usepackage[a4paper,margin=1in]{geometry}
\usepackage{hyperref}
\usepackage{tipa}
\usepackage{longtable}
\usepackage{xcolor}
\usepackage{xurl}
\usepackage{wrapfig}
\usepackage{graphicx}
\renewcommand*{\arraystretch}{1.15}
\hypersetup{colorlinks=true, linkcolor=black, urlcolor=black}
\begin{document}

\begin{wrapfigure}{r}{0.22\textwidth}
    \vspace{-10pt}
    \includegraphics[width=\linewidth, height=3.6cm]{""" + str(ROOT / "assets" / "img" / "photo.jpg") + r"""}
\end{wrapfigure}
\noindent
\textbf{\Large """ + esc(cv["name"]).upper() + r"""}\\
\textipa{""" + cv["ipa"] + r"""}\\
\\
Email: """ + email_line + r"""\\
\hypersetup{colorlinks=true, linkcolor=blue, urlcolor=blue}
\small
ResearchGate: \href{""" + cv["links"]["researchgate"] + r"""}{""" + esc(cv["links"]["researchgate"]) + r"""}\\
Google Scholar: \href{""" + cv["links"]["scholar"] + r"""}{""" + esc(cv["links"]["scholar"]) + r"""}\\
ORCID: \href{""" + cv["links"]["orcid"] + r"""}{""" + esc(cv["links"]["orcid"]) + r"""}
\vspace{2mm}
\hypersetup{colorlinks=true, linkcolor=black, urlcolor=black}
\normalsize

\section*{Education}
\hrule\vspace{5mm}
\small
\begin{longtable}{@{}p{3cm} p{12cm}@{}}
""" + block_rows(cv["education"]) + r"""
\end{longtable}

\section*{Academic positions}
\hrule\vspace{5mm}
\begin{longtable}{@{}p{3cm} p{12cm}@{}}
""" + block_rows(cv["positions"]) + r"""
\end{longtable}

\section*{Publications}
\hrule\vspace{5mm}
\begin{longtable}{@{}p{3cm} p{12cm}@{}}
""" + collection_rows(publications) + r"""
\end{longtable}

\section*{Invited talks}
\hrule\vspace{5mm}
\begin{longtable}{@{}p{3cm} p{12cm}@{}}
""" + collection_rows(invited) + r"""
\end{longtable}

\section*{Teaching}
\hrule\vspace{5mm}
\begin{longtable}{p{3cm}p{12cm}}
""" + collection_rows(teaching) + r"""
\end{longtable}

\section*{Presentations}
\hrule\vspace{5mm}
\begin{longtable}{@{}p{3cm} p{12cm}@{}}
""" + collection_rows(presentations) + r"""
\end{longtable}

\section*{Awards}
\hrule\vspace{5mm}
\begin{longtable}{@{}p{3cm} p{12cm}@{}}
""" + block_rows(cv["awards"]) + r"""
\end{longtable}

\section*{Grants}
\hrule\vspace{5mm}
\begin{longtable}{@{}p{3cm} p{12cm}@{}}
""" + block_rows(cv["grants"]) + r"""
\end{longtable}

\section*{Skills}
\hrule\vspace{5mm}
\begin{longtable}{p{12cm}}
\textbf{IT} \\
Advanced: """ + esc(", ".join(cv["skills"]["it_advanced"])) + r""" \\
Intermediate: """ + esc(", ".join(cv["skills"]["it_intermediate"])) + r""" \\
\\
\textbf{Languages} \\
""" + " \\\\\n".join(f"{esc(l['language'])}: {esc(l['level'])}" for l in cv["skills"]["languages"]) + r""" \\
\end{longtable}

\section*{Additional training}
\hrule\vspace{5mm}
\begin{longtable}{@{}p{3cm} p{12cm}@{}}
""" + block_rows(cv["training"]) + r"""
\end{longtable}

\section*{Scientific affiliations}
\hrule\vspace{5mm}
""" + esc(", ".join(cv["affiliations"])) + r"""

\section*{References}
\hrule\vspace{5mm}
\begin{longtable}{@{}p{4cm} p{6cm} p{5cm}@{}}
""" + "\n".join(
        f"\\textbf{{{esc(r['name'])}}} & {esc(r['place'])} & {r['email']} \\\\"
        for r in cv["references"]
    ) + r"""
\end{longtable}

\end{document}
"""

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        (tmp / "cv.tex").write_text(tex, encoding="utf-8")
        for _ in range(2):  # run twice so hyperref cross-refs settle
            result = subprocess.run(
                ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", "cv.tex"],
                cwd=tmp, capture_output=True, text=True,
            )
        if not (tmp / "cv.pdf").exists():
            print(result.stdout[-4000:])
            print(result.stderr[-2000:])
            sys.exit("pdflatex failed -- see log above")

        dest = ROOT / "assets" / "cv.pdf"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes((tmp / "cv.pdf").read_bytes())
        print(f"Wrote {dest}")


if __name__ == "__main__":
    build()
