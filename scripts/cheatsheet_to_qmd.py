"""Convert a stand-alone cheat sheet (e.g. DescriptiveI_cheatsheet.html) into a
Quarto include that is styled like the rest of the book.

Usage:  python3 scripts/cheatsheet_to_qmd.py DescriptiveI_cheatsheet.html cheatsheets/_DescriptiveI.qmd
"""
import sys, html
from bs4 import BeautifulSoup

src, dst = sys.argv[1], sys.argv[2]
soup = BeautifulSoup(open(src, encoding="utf-8").read(), "html.parser")

def inner(el):
    return "".join(str(c) for c in el.contents).strip() if el else ""

title = inner(soup.select_one(".header h1"))
cards = []
for c in soup.select(".grid .card"):
    cards.append({
        "label": inner(c.select_one(".label")),
        "title": inner(c.select_one("h3")),
        "formula": inner(c.select_one(".formula")),
        "desc": inner(c.select_one(".desc")),
        "xlabel": inner(c.select_one(".excel-label")).title(),
        "excel": inner(c.select_one(".excel")),
    })
panels = []
for p in soup.select(".bottom .panel"):
    rows = []
    for r in p.select(".row"):
        spans = r.find_all("span", recursive=False)
        rows.append((inner(spans[0]), inner(spans[1])))
    panels.append((inner(p.select_one(".ptitle")).title(), rows))

out = ['```{=html}', '<section class="bs-cheatsheet" aria-label="Chapter summary cheat sheet">',
       '  <header class="bs-cs-head"><div><div class="bs-cs-eyebrow">Quick reference</div>'
       f'<div class="bs-cs-title">{title}</div></div>'
       '</header>',
       '  <div class="bs-cs-grid">']
for c in cards:
    out.append('    <article class="bs-cs-card">'
               f'<div class="bs-cs-label">{c["label"]}</div>'
               f'<div class="bs-cs-card-title">{c["title"]}</div>'
               f'<div class="bs-cs-formula">{c["formula"]}</div>'
               f'<p class="bs-cs-desc">{c["desc"]}</p>'
               f'<div class="bs-excel"><span class="lbl">{c["xlabel"]}</span><span>{c["excel"]}</span></div>'
               '</article>')
out.append('  </div>')
out.append('  <div class="bs-cs-panels">')
for name, rows in panels:
    out.append(f'    <div class="bs-cs-panel"><div class="bs-cs-panel-title">{name}</div><dl>')
    for a, b in rows:
        out.append(f'      <div class="bs-cs-row"><dt>{a}</dt><dd>{b}</dd></div>')
    out.append('    </dl></div>')
out.append('  </div>')
out.append('</section>')
out.append('```')
open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")
print("wrote", dst, len(cards), "cards,", len(panels), "panels")
