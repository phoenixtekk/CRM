#!/usr/bin/env python3
"""
build-deliverables.py — Phoenixtekk Workplace Marketplace factory compiler.

Reads a solution version folder (…/<slug>/vX.Y.Z/) and produces the customer deliverables:
  deliverables/<SOL>-Solution.docx   branded Word doc (cover + TOC + all sections + scripts appendix)
  deliverables/<SOL>-Solution.pdf    matching branded PDF (cover + TOC + sections + appendix)
  deliverables/<SOL>-Scripts.zip     all PowerShell scripts zipped

Source of metadata: <version>/solution.meta.json (title, sol_code, version, created).
Markdown handled: # ## ### headings, **bold**, `code`, bullet/numbered lists, > quotes,
| tables |, ``` fenced code, --- rules.

Usage:
  python tools/build-deliverables.py --solution-dir "library/intune-solutions/windows-hello-for-business/v1.0.0"
"""
import argparse, json, os, re, zipfile
from pathlib import Path

# ------- ordering of source files in the compiled document -------
SOURCE_ORDER = [
    "executive-summary.md",
    "01-solution-overview.md",
    "02-requirements.md",
    "global-requirements-intune-solutions.md",
    "global-requirements-google.md",
    "global-requirements-gcp.md",
    "global-requirements-oracle.md",
    "global-requirements-synthetic.md",
    "global-requirements-messaging.md",
    "global-requirements-teams.md",
    "global-requirements-sharepoint.md",
    "03-implementation.md",
    "04-maintenance-and-updates.md",
    "04-use-and-login.md",
    "04-enrollment-scenarios.md",
    "05-testing.md",
    "06-troubleshooting.md",
    "07-best-practices.md",
    "08-deliverables-summary.md",
]

BRAND_NAVY = (0x1F, 0x3A, 0x5F)
BRAND_ACCENT = (0x2E, 0x86, 0xC1)

# --- Company branding (gated by the "branding" toggle; the navy/accent palette above is a neutral
#     document theme and is always used). When branding is OFF (default), none of these strings appear. ---
BRAND_NAME = "PHOENIXTEKK"
BRAND_SUBTITLE = "Workplace Marketplace · Intune Solutions"
BRAND_URL = "workplace.phoenixtekk.com"
BRAND_FOOT_NAME = "Phoenixtekk"
BRAND_TRUE = ("on", "branded", "yes", "true", "1")


def is_branded(meta, cli_override=None):
    """cli_override: True/False forces it; None falls back to meta['branding'] (default OFF)."""
    if cli_override is not None:
        return cli_override
    return str(meta.get("branding", "off")).strip().lower() in BRAND_TRUE


# ============================ tiny markdown parser ============================
def parse_markdown(text):
    """Yield blocks: ('h',level,text) ('p',text) ('bullet',[items]) ('num',[items])
    ('table',[rows]) ('code',text) ('quote',text) ('rule',)"""
    lines = text.splitlines()
    i, n = 0, len(lines)
    while i < n:
        line = lines[i]
        if not line.strip():
            i += 1; continue
        # fenced code
        if line.strip().startswith("```"):
            buf = []; i += 1
            while i < n and not lines[i].strip().startswith("```"):
                buf.append(lines[i]); i += 1
            i += 1
            yield ("code", "\n".join(buf)); continue
        # heading
        m = re.match(r"^(#{1,4})\s+(.*)", line)
        if m:
            yield ("h", len(m.group(1)), m.group(2).strip()); i += 1; continue
        # horizontal rule
        if re.match(r"^---+\s*$", line):
            yield ("rule",); i += 1; continue
        # table
        if line.lstrip().startswith("|") and i + 1 < n and re.match(r"^\s*\|?[\s:|-]+\|?\s*$", lines[i + 1]):
            rows = []
            header = [c.strip() for c in line.strip().strip("|").split("|")]
            rows.append(header); i += 2
            while i < n and lines[i].lstrip().startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")]); i += 1
            yield ("table", rows); continue
        # blockquote
        if line.lstrip().startswith(">"):
            buf = []
            while i < n and lines[i].lstrip().startswith(">"):
                buf.append(lines[i].lstrip()[1:].strip()); i += 1
            yield ("quote", " ".join(buf)); continue
        # bullet list (incl checkboxes)
        if re.match(r"^\s*[-*]\s+", line):
            items = []
            while i < n and re.match(r"^\s*[-*]\s+", lines[i]):
                items.append(re.sub(r"^\s*[-*]\s+", "", lines[i])); i += 1
            yield ("bullet", items); continue
        # numbered list
        if re.match(r"^\s*\d+\.\s+", line):
            items = []
            while i < n and re.match(r"^\s*\d+\.\s+", lines[i]):
                items.append(re.sub(r"^\s*\d+\.\s+", "", lines[i])); i += 1
            yield ("num", items); continue
        # paragraph (gather until blank)
        buf = [line]; i += 1
        while i < n and lines[i].strip() and not re.match(r"^(#{1,4}\s|[-*]\s|\d+\.\s|\||>|```|---)", lines[i].lstrip()):
            buf.append(lines[i]); i += 1
        yield ("p", " ".join(buf))


def strip_inline(s):
    """Plain text: remove ** and ` for PDF/segment fallback."""
    return s.replace("**", "").replace("`", "")


SCRIPT_EXTS = ("*.ps1", "*.sh", "*.py", "*.sql", "*.wlst")


def script_files(d):
    """All automation scripts in a dir (PowerShell + shell/Python/WLST/SQL), sorted by name."""
    fs = []
    for g in SCRIPT_EXTS:
        fs += list(Path(d).glob(g))
    return sorted(fs, key=lambda p: p.name)


def scripts_appendix(scripts_dir):
    """Return list of (name, purpose, howto) extracted from each script's header (any language)."""
    out = []
    for ps1 in script_files(scripts_dir):
        body = ps1.read_text(encoding="utf-8", errors="ignore")
        purpose = howto = ""
        def _dc(l):  # strip leading comment markers (#, --, *, /*, ;) so non-PowerShell headers render clean
            return re.sub(r"^\s*(#+|--+|/\*+|\*+|;+)\s?", "", l).strip()
        pm = re.search(r"PURPOSE\s*\n(.*?)\n\s*\n", body, re.S)
        if pm: purpose = " ".join(_dc(l) for l in pm.group(1).splitlines() if _dc(l))
        hm = re.search(r"HOW TO RUN\s*\n(.*?)\n\s*\n", body, re.S)
        if hm: howto = " ".join(_dc(l) for l in hm.group(1).splitlines() if _dc(l))
        out.append((ps1.name, purpose, howto))
    return out


# ============================ DOCX builder ============================
def build_docx(meta, blocks, scripts, out_path, branded=False):
    import docx
    from docx import Document
    from docx.shared import Pt, RGBColor, Inches
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.oxml.ns import qn
    from docx.oxml import OxmlElement

    doc = Document()
    # base style
    normal = doc.styles["Normal"]; normal.font.name = "Calibri"; normal.font.size = Pt(11)
    for s in ("Heading 1", "Heading 2", "Heading 3"):
        doc.styles[s].font.color.rgb = RGBColor(*BRAND_NAVY)

    # ---- cover ----
    for _ in range(6): doc.add_paragraph()
    if branded:
        t = doc.add_paragraph(); t.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = t.add_run(BRAND_NAME); r.bold = True; r.font.size = Pt(26); r.font.color.rgb = RGBColor(*BRAND_NAVY)
        s = doc.add_paragraph(); s.alignment = WD_ALIGN_PARAGRAPH.CENTER
        rs = s.add_run(BRAND_SUBTITLE); rs.font.size = Pt(12); rs.font.color.rgb = RGBColor(*BRAND_ACCENT)
        doc.add_paragraph()
    ti = doc.add_paragraph(); ti.alignment = WD_ALIGN_PARAGRAPH.CENTER
    rt = ti.add_run(meta["title"]); rt.bold = True; rt.font.size = Pt(20)
    sub = doc.add_paragraph(); sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    rsub = sub.add_run("Implementation Solution Guide"); rsub.font.size = Pt(13); rsub.italic = True
    for _ in range(8): doc.add_paragraph()
    info = doc.add_paragraph(); info.alignment = WD_ALIGN_PARAGRAPH.CENTER
    info_txt = f"Version {meta['version']}    ·    {meta['created']}"
    if branded: info_txt += f"\n{BRAND_FOOT_NAME} · {BRAND_URL}"
    info.add_run(info_txt).font.size = Pt(10)
    doc.add_page_break()

    # ---- TOC field ----
    doc.add_heading("Contents", level=1)
    p = doc.add_paragraph()
    run = p.add_run()
    fldBegin = OxmlElement("w:fldChar"); fldBegin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText"); instr.set(qn("xml:space"), "preserve"); instr.text = r'TOC \o "1-3" \h \z \u'
    fldSep = OxmlElement("w:fldChar"); fldSep.set(qn("w:fldCharType"), "separate")
    fldText = OxmlElement("w:t"); fldText.text = "Right-click and choose “Update Field” to build the table of contents."
    fldEnd = OxmlElement("w:fldChar"); fldEnd.set(qn("w:fldCharType"), "end")
    for el in (fldBegin, instr, fldSep, fldText, fldEnd): run._r.append(el)
    doc.add_page_break()

    # ---- body ----
    def add_rich(paragraph, text):
        # render **bold** and `code` inline
        text = re.sub(r"\*\*(`[^`]*`)\*\*", r"\1", text)  # drop redundant bold around a code span
        for seg in re.split(r"(\*\*.*?\*\*|`.*?`)", text):
            if not seg: continue
            if seg.startswith("**") and seg.endswith("**"):
                paragraph.add_run(seg[2:-2]).bold = True
            elif seg.startswith("`") and seg.endswith("`"):
                rr = paragraph.add_run(seg[1:-1]); rr.font.name = "Consolas"; rr.font.size = Pt(9.5)
            else:
                paragraph.add_run(seg)

    for b in blocks:
        kind = b[0]
        if kind == "h":
            doc.add_heading(b[2], level=min(b[1], 3))
        elif kind == "p":
            add_rich(doc.add_paragraph(), b[1])
        elif kind == "bullet":
            for it in b[1]:
                add_rich(doc.add_paragraph(style="List Bullet"), re.sub(r"^\[[ x]\]\s*", "", it))
        elif kind == "num":
            for it in b[1]:
                add_rich(doc.add_paragraph(style="List Number"), it)
        elif kind == "quote":
            pq = doc.add_paragraph(); pq.paragraph_format.left_indent = Inches(0.3)
            rq = pq.add_run(strip_inline(b[1])); rq.italic = True; rq.font.color.rgb = RGBColor(*BRAND_ACCENT)
        elif kind == "code":
            pc = doc.add_paragraph(); rc = pc.add_run(b[1]); rc.font.name = "Consolas"; rc.font.size = Pt(9)
        elif kind == "rule":
            doc.add_paragraph("_" * 50)
        elif kind == "table":
            rows = b[1]
            tbl = doc.add_table(rows=len(rows), cols=len(rows[0])); tbl.style = "Light Grid Accent 1"
            for ri, row in enumerate(rows):
                for ci, cell in enumerate(row):
                    if ci < len(tbl.rows[ri].cells):
                        cp = tbl.rows[ri].cells[ci].paragraphs[0]; add_rich(cp, cell)
                        if ri == 0:
                            for rr in cp.runs: rr.bold = True

    # ---- scripts appendix ----
    doc.add_page_break(); doc.add_heading("Appendix A — PowerShell Scripts", level=1)
    doc.add_paragraph("The following scripts are included in the accompanying ZIP. Each script's own header documents its full usage and expected results.")
    for name, purpose, howto in scripts:
        doc.add_heading(name, level=2)
        if purpose: add_rich(doc.add_paragraph(), f"**Purpose:** {purpose}")
        if howto: add_rich(doc.add_paragraph(), f"**How to run:** {howto}")

    # ---- page numbers (footer) ----
    footer = doc.sections[0].footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    fr = footer.add_run()
    b1 = OxmlElement("w:fldChar"); b1.set(qn("w:fldCharType"), "begin")
    it = OxmlElement("w:instrText"); it.set(qn("xml:space"), "preserve"); it.text = "PAGE"
    e1 = OxmlElement("w:fldChar"); e1.set(qn("w:fldCharType"), "end")
    for el in (b1, it, e1): fr._r.append(el)

    doc.save(out_path)


# ============================ PDF builder ============================
def build_pdf(meta, blocks, scripts, out_path, branded=False):
    from reportlab.lib.pagesizes import LETTER
    from reportlab.lib.units import inch
    from reportlab.lib import colors
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
                                    Table, TableStyle, Preformatted, PageBreak)
    from reportlab.platypus.tableofcontents import TableOfContents

    navy = colors.Color(*[c / 255 for c in BRAND_NAVY])
    accent = colors.Color(*[c / 255 for c in BRAND_ACCENT])
    ss = getSampleStyleSheet()
    body = ParagraphStyle("body", parent=ss["BodyText"], fontSize=10, leading=14, spaceAfter=6)
    h1 = ParagraphStyle("h1", parent=ss["Heading1"], textColor=navy, fontSize=16, spaceBefore=14, spaceAfter=8)
    h2 = ParagraphStyle("h2", parent=ss["Heading2"], textColor=navy, fontSize=13, spaceBefore=10, spaceAfter=6)
    h3 = ParagraphStyle("h3", parent=ss["Heading3"], textColor=accent, fontSize=11, spaceBefore=8, spaceAfter=4)
    quote = ParagraphStyle("quote", parent=body, leftIndent=16, textColor=accent, fontName="Helvetica-Oblique")
    code = ParagraphStyle("code", parent=body, fontName="Courier", fontSize=8.5, leading=10,
                          backColor=colors.whitesmoke, borderPadding=4)
    bullet = ParagraphStyle("bullet", parent=body, leftIndent=14, bulletIndent=4)

    def _balanced(s):
        order = []
        for m in re.finditer(r"<b>|</b>|<font[^>]*>|</font>", s):
            t = m.group(0)
            if t == "<b>": order.append("b")
            elif t == "</b>":
                if not order or order.pop() != "b": return False
            elif t.startswith("<font"): order.append("f")
            elif t == "</font>":
                if not order or order.pop() != "f": return False
        return not order

    def _esc(t):
        return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    def rich(text):
        # escape &<> first so <PLACEHOLDER> tokens in the docs aren't parsed as reportlab tags,
        # THEN add our own bold/code tags. If the result has unbalanced/overlapping inline tags
        # (malformed source markdown), fall back to plain escaped text so the PDF never fails to build.
        esc = _esc(text)
        out = re.sub(r"\*\*(`[^`]*`)\*\*", r"\1", esc)   # drop redundant bold around a code span
        out = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", out)
        out = re.sub(r"`(.+?)`", r'<font face="Courier">\1</font>', out)
        return out if _balanced(out) else _esc(re.sub(r"[*`]", "", text))

    story = []
    # cover
    story.append(Spacer(1, 2.0 * inch))
    if branded:
        story.append(Paragraph(BRAND_NAME, ParagraphStyle("c", parent=h1, fontSize=30, alignment=1, textColor=navy)))
        story.append(Paragraph(BRAND_SUBTITLE, ParagraphStyle("c2", parent=body, alignment=1, textColor=accent, fontSize=12)))
    story.append(Spacer(1, 0.6 * inch))
    story.append(Paragraph(meta["title"], ParagraphStyle("ct", parent=h1, fontSize=22, alignment=1, textColor=colors.black)))
    story.append(Paragraph("Implementation Solution Guide", ParagraphStyle("cs", parent=body, alignment=1, fontSize=13)))
    story.append(Spacer(1, 2.5 * inch))
    ver_txt = f"Version {meta['version']} &nbsp;·&nbsp; {meta['created']}"
    if branded: ver_txt += f"<br/>{BRAND_URL}"
    story.append(Paragraph(ver_txt, ParagraphStyle("ci", parent=body, alignment=1, fontSize=10)))
    story.append(PageBreak())

    # TOC
    toc = TableOfContents()
    toc.levelStyles = [ParagraphStyle("toc1", fontSize=11, leftIndent=8, spaceAfter=4, textColor=navy),
                       ParagraphStyle("toc2", fontSize=10, leftIndent=22, spaceAfter=2)]
    story += [Paragraph("Contents", h1), toc, PageBreak()]

    seq = [0]
    def heading(text, level):
        style = {1: h1, 2: h2, 3: h3}[min(level, 3)]
        seq[0] += 1; key = f"h{seq[0]}"
        p = Paragraph(text, style)
        p.toc_level = level - 1; p.toc_key = key
        return p

    class TocPara(Paragraph):
        pass

    for b in blocks:
        kind = b[0]
        if kind == "h":
            lvl = min(b[1], 3)
            p = heading(rich(b[2]), lvl)
            story.append(p)
            # notify TOC for level 1 & 2
            if lvl <= 2:
                story.append(_TocNotify(b[2], lvl - 1, p.toc_key))
        elif kind == "p":
            story.append(Paragraph(rich(b[1]), body))
        elif kind == "bullet":
            for it in b[1]:
                story.append(Paragraph("• " + rich(re.sub(r"^\[[ x]\]\s*", "", it)), bullet))
        elif kind == "num":
            for n, it in enumerate(b[1], 1):
                story.append(Paragraph(f"{n}. " + rich(it), bullet))
        elif kind == "quote":
            story.append(Paragraph(rich(b[1]), quote))
        elif kind == "code":
            story.append(Preformatted(b[1], code))
        elif kind == "rule":
            story.append(Spacer(1, 6))
        elif kind == "table":
            rows = b[1]
            data = [[Paragraph(rich(c), ParagraphStyle("td", parent=body, fontSize=9)) for c in row] for row in rows]
            tb = Table(data, repeatRows=1)
            tb.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), navy),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.grey),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.Color(0.95, 0.97, 0.99)]),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
            ]))
            story += [tb, Spacer(1, 8)]

    # appendix
    story.append(PageBreak())
    ph = heading("Appendix A — PowerShell Scripts", 1); story.append(ph)
    story.append(_TocNotify("Appendix A — PowerShell Scripts", 0, ph.toc_key))
    story.append(Paragraph("Included in the accompanying ZIP. Each script's header documents full usage.", body))
    for name, purpose, howto in scripts:
        story.append(Paragraph(name, h2))
        if purpose: story.append(Paragraph(f"<b>Purpose:</b> {rich(purpose)}", body))
        if howto: story.append(Paragraph(f"<b>How to run:</b> {rich(howto)}", body))

    # build with page numbers + TOC multi-pass
    def on_page(canvas, doc):
        canvas.saveState()
        canvas.setFont("Helvetica", 8); canvas.setFillColor(colors.grey)
        foot = (f"{BRAND_FOOT_NAME} · {meta['title']} · Page {doc.page}" if branded
                else f"{meta['title']} · Page {doc.page}")
        canvas.drawCentredString(LETTER[0] / 2, 0.5 * inch, foot)
        canvas.restoreState()

    frame = Frame(0.9 * inch, 0.8 * inch, LETTER[0] - 1.8 * inch, LETTER[1] - 1.6 * inch, id="f")
    doct = BaseDocTemplate(out_path, pagesize=LETTER)
    doct.addPageTemplates([PageTemplate(id="main", frames=[frame], onPage=on_page)])
    doct.multiBuild(story)


# helper flowable that notifies the TOC
def _make_toc_notify():
    from reportlab.platypus import Flowable
    class _Notify(Flowable):
        def __init__(self, text, level, key):
            super().__init__(); self.text = text; self.level = level; self.key = key
        def wrap(self, *a): return (0, 0)
        def draw(self): pass
        def afterDrawWriting(self): pass
        def __repr__(self): return "TocNotify"
        def drawOn(self, canvas, x, y, _sW=0):
            # 3-tuple entry: (level, text, page) — page-numbered TOC, no hyperlink target needed
            canvas._doctemplate.notify("TOCEntry", (self.level, self.text, canvas._doctemplate.page))
    return _Notify

_TocNotify = _make_toc_notify()


# ============================ main ============================
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solution-dir", required=True, help="path to …/<slug>/vX.Y.Z")
    ap.add_argument("--brand", dest="brand", action="store_true", default=None,
                    help="force company branding ON (overrides solution.meta.json 'branding')")
    ap.add_argument("--no-brand", dest="brand", action="store_false",
                    help="force company branding OFF / white-label (overrides solution.meta.json)")
    args = ap.parse_args()
    vdir = Path(args.solution_dir).resolve()
    meta = json.loads((vdir / "solution.meta.json").read_text(encoding="utf-8"))
    sol = meta["sol_code"]
    src = vdir / "source"; deliv = vdir / "deliverables"; scr = vdir / "scripts"
    deliv.mkdir(exist_ok=True)

    # assemble blocks in order (skip files that don't exist)
    blocks = []
    for fn in SOURCE_ORDER:
        f = src / fn
        if f.exists():
            blocks.extend(list(parse_markdown(f.read_text(encoding="utf-8"))))
    scripts = scripts_appendix(scr)

    docx_path = deliv / f"{sol}-Solution.docx"
    pdf_path = deliv / f"{sol}-Solution.pdf"
    zip_path = deliv / f"{sol}-Scripts.zip"

    branded = is_branded(meta, args.brand)
    build_docx(meta, blocks, scripts, str(docx_path), branded=branded)
    build_pdf(meta, blocks, scripts, str(pdf_path), branded=branded)

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for ps1 in script_files(scr):
            z.write(ps1, ps1.name)

    # Single "Complete Solution Package" — the one always-included deliverable attached to the
    # product (the PDF + Word doc + scripts in one zip), so a buyer can never check out without
    # their files. The individual docx/pdf/scripts.zip are kept for the wiki/docs pipeline.
    bundle_path = deliv / f"{sol}-Complete-Solution.zip"
    with zipfile.ZipFile(bundle_path, "w", zipfile.ZIP_DEFLATED) as b:
        b.write(pdf_path, arcname=pdf_path.name)
        b.write(docx_path, arcname=docx_path.name)
        for ps1 in script_files(scr):
            b.write(ps1, arcname=f"Scripts/{ps1.name}")

    for p in (docx_path, pdf_path, zip_path, bundle_path):
        print(f"  {p.name:28} {p.stat().st_size:>8,} bytes")
    print(f"Deliverables built ({'BRANDED — Phoenixtekk' if branded else 'unbranded / white-label'}).")


if __name__ == "__main__":
    main()
