"""
Renders repository content as an OMG-conforming document (docs/OMG-DOCUMENT-CONVENTIONS.md).

The content is NOT written here. It comes from the same structured sources the markdown is generated from, so an
OMG document is a second rendering rather than a second copy to keep in step: Annex A comes from
traceability/uml2-to-uml3.json, exactly as docs/UML2-to-UML3-Traceability.md does.

What conformance means here, from a published specification (SysML v2.0 Part 1) rather than from memory:
  * a cover page carrying the document number, date, standard document URL and machine-readable files
  * the fixed clause skeleton, and annexes marked normative or informative
  * Arial headings numbered 1, 1.1, 1.1.1 over a Times body, and a running foot with the page number
  * shall/should/may, and cross references written 'Clause 8' or '8.2'

The OMG legal boilerplate is NOT generated. It is several pages of OMG's own text - USE OF SPECIFICATION,
LICENSES, PATENTS, GENERAL USE RESTRICTIONS, DISCLAIMER OF WARRANTY, RESTRICTED RIGHTS LEGEND, TRADEMARKS,
COMPLIANCE, OMG'S ISSUE REPORTING PROCEDURE - and it must be copied verbatim from a current specification, not
retyped or invented. A marked placeholder page is emitted in its place, saying exactly that.

Usage: python tools/make_omg_doc.py [--part annex-a] [--out logs/omg] [--pdf]
  --pdf converts through Word (Word COM 16.0 is present on this machine; there is no pandoc)
Exit code: 0 written, 2 tool error.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path

try:
    from docx import Document
    from docx.enum.section import WD_ORIENT, WD_SECTION
    from docx.enum.table import WD_TABLE_ALIGNMENT
    from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
    from docx.oxml.ns import qn
    from docx.oxml import OxmlElement
    from docx.shared import Inches, Pt, RGBColor
except ImportError:  # pragma: no cover - the message matters more than the traceback
    print("needs python-docx: python -m pip install python-docx", file=sys.stderr)
    raise SystemExit(2)

ROOT = Path(__file__).resolve().parent.parent
TRACEABILITY = ROOT / "traceability" / "uml2-to-uml3.json"

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_traceability as ct  # noqa: E402  - one definition of what a row's prose is
import check_languages as cl  # noqa: E402

HEADING_FONT = "Arial"
BODY_FONT = "Times New Roman"

# The cover-page block. Document number is a placeholder until OMG issues one: an invented formal/ number would
# be worse than an obvious gap.
COVER = {
    "publication": "An OMG® Systems Modeling Publication",
    "title": "Unified Modeling Language™ (UML®)",
    "version": "Version 3.0",
    "docNumber": "<OMG Document Number: to be assigned>",
    "url": "https://www.omg.org/spec/UML/3.0/",
    "machineReadable": "https://github.com/turbogeek/UML-3-Experiments",
}


def set_run(run, *, font: str, size: int, bold: bool = False, italic: bool = False, color=None) -> None:
    run.font.name = font
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    if color is not None:
        run.font.color.rgb = color
    # Word picks the East Asian font separately; without this a theme font can win over the one set above
    run._element.rPr.rFonts.set(qn("w:eastAsia"), font)


def add_page_number(paragraph) -> None:
    """A PAGE field, so the foot numbers itself. python-docx has no field API, so the run carries the raw
    field characters."""
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = "PAGE"
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.append(begin)
    run._r.append(instr)
    run._r.append(end)
    set_run(run, font=BODY_FONT, size=9)


class OmgDocument:
    """An OMG-styled document. Knows the house style; knows nothing about UML3."""

    def __init__(self, running_title: str) -> None:
        self.doc = Document()
        self.running_title = running_title
        self._setup_page()
        self._setup_styles()

    def _setup_page(self) -> None:
        for section in self.doc.sections:
            section.page_width, section.page_height = Inches(8.5), Inches(11)   # US Letter, as OMG publishes
            section.left_margin = section.right_margin = Inches(1.0)
            section.top_margin = section.bottom_margin = Inches(1.0)

    def _setup_styles(self) -> None:
        normal = self.doc.styles["Normal"]
        normal.font.name = BODY_FONT
        normal.font.size = Pt(10)
        normal.element.rPr.rFonts.set(qn("w:eastAsia"), BODY_FONT)
        for level, size in ((1, 16), (2, 13), (3, 11)):
            style = self.doc.styles[f"Heading {level}"]
            style.font.name = HEADING_FONT
            style.font.size = Pt(size)
            style.font.bold = True
            style.font.color.rgb = RGBColor(0, 0, 0)
            style.element.rPr.rFonts.set(qn("w:eastAsia"), HEADING_FONT)

    def running_foot(self) -> None:
        """'<specification> v<version>, <part>' with the page number, as SysML v2 carries it."""
        footer = self.doc.sections[0].footer
        paragraph = footer.paragraphs[0]
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        set_run(paragraph.add_run(self.running_title + "      "), font=BODY_FONT, size=9)
        add_page_number(paragraph)

    def cover(self, cover: dict, part: str) -> None:
        right = self.doc.add_paragraph()
        right.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        set_run(right.add_run(cover["publication"]), font=HEADING_FONT, size=10, bold=True)
        self.doc.add_paragraph()
        for text, size in ((cover["title"], 24), (cover["version"], 14), (part, 18)):
            paragraph = self.doc.add_paragraph()
            set_run(paragraph.add_run(text), font=HEADING_FONT, size=size, bold=size != 14)
        self.doc.add_paragraph("_" * 78)
        for label, value in (("OMG Document Number:", cover["docNumber"]),
                             ("Date:", dt.date.today().strftime("%B %Y")),
                             ("Standard document URL:", cover["url"]),
                             ("Machine Readable File(s):", cover["machineReadable"])):
            paragraph = self.doc.add_paragraph()
            set_run(paragraph.add_run(label + " "), font=BODY_FONT, size=10, bold=True)
            set_run(paragraph.add_run(value), font=BODY_FONT, size=10)
        self.doc.add_paragraph("_" * 78)
        self.page_break()

    def legal_placeholder(self) -> None:
        """OMG's own legal text is not reproduced here; it is copied from a current specification."""
        self.heading("Notices", level=1, numbered=False)
        self.body("This page stands in for the OMG front matter, which is not generated. Copy it verbatim from a "
                  "current OMG specification, in this order: USE OF SPECIFICATION — TERMS, CONDITIONS & "
                  "NOTICES; LICENSES; PATENTS; GENERAL USE RESTRICTIONS; DISCLAIMER OF WARRANTY; RESTRICTED "
                  "RIGHTS LEGEND; TRADEMARKS; COMPLIANCE; OMG'S ISSUE REPORTING PROCEDURE. The copyright page, "
                  "one line per contributing organization, precedes it.")
        self.body("It is deliberately not retyped or paraphrased: it is OMG's text, and an approximation of a "
                  "legal notice is worse than an obvious gap.")
        self.page_break()

    def heading(self, text: str, level: int = 1, number: str | None = None, numbered: bool = True) -> None:
        paragraph = self.doc.add_heading(level=level)
        label = f"{number}\t{text}" if (numbered and number) else text
        set_run(paragraph.add_run(label), font=HEADING_FONT, size=(16, 13, 11)[min(level, 3) - 1], bold=True)

    def body(self, text: str) -> None:
        paragraph = self.doc.add_paragraph()
        set_run(paragraph.add_run(text), font=BODY_FONT, size=10)

    def table(self, headers: list[str], rows: list[list[str]], widths: list[float] | None = None) -> None:
        table = self.doc.add_table(rows=1, cols=len(headers))
        table.style = "Table Grid"
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        # Word ignores cell widths while autofit is on, and then breaks long names like SysML::ItemDefinition
        # mid-token. Fixed layout plus a width on every cell is what actually holds the columns.
        if widths:
            table.autofit = False
            layout = OxmlElement("w:tblLayout")
            layout.set(qn("w:type"), "fixed")
            table._tbl.tblPr.append(layout)
        for cell, text in zip(table.rows[0].cells, headers):
            cell.paragraphs[0].clear()
            set_run(cell.paragraphs[0].add_run(text), font=HEADING_FONT, size=9, bold=True)
        for row in rows:
            cells = table.add_row().cells
            for cell, text in zip(cells, row):
                cell.paragraphs[0].clear()
                set_run(cell.paragraphs[0].add_run(text), font=BODY_FONT, size=8)
        if widths:
            for row in table.rows:
                for cell, width in zip(row.cells, widths):
                    cell.width = Inches(width)
        # the header row repeats when a long table breaks across pages, as the published specifications do
        header_props = table.rows[0]._tr.get_or_add_trPr()
        repeat = OxmlElement("w:tblHeader")
        repeat.set(qn("w:val"), "true")
        header_props.append(repeat)
        self.doc.add_paragraph()

    def page_break(self) -> None:
        self.doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

    def landscape(self) -> float:
        """Starts a landscape section and returns the width available for a table. A six-column table of
        qualified names does not fit the 6.5 in text block of a portrait page - Word squeezes the columns and
        breaks names like SysML::ConnectionDefinition mid-token. Published OMG specifications turn wide tables
        sideways for the same reason. The footer carries over: new sections link to the previous one."""
        section = self.doc.add_section(WD_SECTION.NEW_PAGE)
        section.orientation = WD_ORIENT.LANDSCAPE
        # python-docx sets the flag but not the dimensions; they have to be swapped by hand
        section.page_width, section.page_height = Inches(11), Inches(8.5)
        section.left_margin = section.right_margin = Inches(0.8)
        section.top_margin = section.bottom_margin = Inches(0.8)
        return 11 - 1.6

    def save(self, path: Path) -> Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.doc.save(str(path))
        return path


def flatten(value) -> str:
    """The JSON keeps lists where a cell needs one string."""
    if isinstance(value, list):
        return ", ".join(str(v) for v in value)
    if isinstance(value, dict):
        return value.get("file", "") or ", ".join(f"{k}={v}" for k, v in value.items())
    return "" if value is None else str(value)


def annex_a(doc: OmgDocument) -> None:
    """Annex A, the UML 2.5.1 to UML3 mapping, from the same JSON the markdown report uses."""
    data = json.loads(TRACEABILITY.read_text(encoding="utf-8"))
    rows = data["rows"]

    doc.heading("UML 2.5.1 to UML3 mapping", level=1, number="Annex A")
    doc.body("(informative)")
    doc.body(data["description"])

    doc.heading("Status legend", level=2, number="A.1")
    doc.table(["Status", "Meaning"], [[k, v] for k, v in data["statusLegend"].items()], widths=[1.3, 5.2])

    doc.heading("Summary", level=2, number="A.2")
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["status"]] = counts.get(row["status"], 0) + 1
    summary = [[status, str(n)] for status, n in counts.items()]
    summary.append(["Total", str(len(rows))])
    doc.table(["Status", "Concepts"], summary, widths=[2.0, 1.2])

    width = doc.landscape()
    doc.heading("Classification", level=2, number="A.3")
    doc.body(f"Each of the {len(rows)} UML 2.x concepts, the SysML v2 or KerML element that carries it, and the "
             "UML3 element or keyword that names it. Every cited element is verified by the test suite.")
    # of the landscape text block, summing to 1; Status needs room for NATIVE+UML3 on one line
    share = [0.13, 0.11, 0.19, 0.18, 0.18, 0.21]
    doc.table(
        ["UML 2.x", "Status", "SysML v2 / KerML", "UML3", "Notation", "Notes"],
        [[flatten(r.get("uml2")), flatten(r.get("status")), flatten(r.get("sysml")), flatten(r.get("uml3")),
          flatten(r.get("notation")), ct.row_notes(r)] for r in rows],
        widths=[round(width * s, 2) for s in share])


def coverage_annex(doc: OmgDocument, map_name: str, letter: str, title: str) -> None:
    """Any of the coverage maps as an annex. They share a schema, so they share one renderer: a second copy is
    how the rationale went missing from Annex A."""
    data_path, _ = cl.MAPS[map_name]
    data = json.loads(data_path.read_text(encoding="utf-8"))
    rows, targets = data["rows"], data["targets"]

    doc.heading(title, level=1, number=f"Annex {letter}")
    doc.body("(informative)")
    doc.body(data["description"])

    doc.heading("Targets", level=2, number=f"{letter}.1")
    doc.table(["Target", "Version", "Evidence"],
              [[t["name"], t["version"], t.get("evidence", "")] for t in targets], widths=[1.3, 1.2, 4.0])
    doc.body(data["versionBasis"])

    doc.heading("Summary", level=2, number=f"{letter}.2")
    counts = {k: sum(1 for r in rows if r["coverage"] == k) for k in cl.COVERAGE}
    doc.table(["Coverage", "Meaning", "Concepts"],
              [[k, data["coverageLegend"][k], str(counts[k])] for k in cl.COVERAGE]
              + [["Total", "", str(len(rows))]], widths=[0.9, 4.4, 1.2])

    doc.heading("Coverage by concept", level=2, number=f"{letter}.3")
    doc.body(f"{counts['GAP']} concepts have no UML3 construct and {counts['TBD']} are unanalyzed; those "
             f"{counts['GAP'] + counts['TBD']} rows are what decide whether UML3 is sufficient here.")
    width = doc.landscape()
    # Coverage needs room for COVERED on one line; the shares sum to 1
    fixed = [0.18, 0.09, 0.15]
    rest = (1 - sum(fixed) - 0.16) / len(targets)
    share = fixed + [rest] * len(targets) + [0.16]
    doc.table(["Concept", "Coverage", "UML3"] + [t["name"] for t in targets] + ["Notes"],
              [[r["concept"], r["coverage"], ", ".join(r.get("uml3", []))]
               + [(r.get("targets") or {}).get(t["id"], "") for t in targets]
               + [cl.row_notes(r)] for r in rows],
              widths=[round(width * s, 2) for s in share])


COVERAGE_ANNEXES = {
    "annex-h": ("languages", "H", "UML3 coverage of implementation languages and platforms"),
    "annex-i": ("ddl", "I", "UML3 coverage of SQL DDL"),
    "annex-j": ("infrastructure", "J", "UML3 coverage of networking and cloud infrastructure"),
}
PARTS: dict = {"annex-a": ("Annex A: UML 2.5.1 to UML3 mapping", annex_a)}
for _part, (_map, _letter, _title) in COVERAGE_ANNEXES.items():
    PARTS[_part] = (f"Annex {_letter}: {_title}",
                    (lambda m, l, ti: lambda doc: coverage_annex(doc, m, l, ti))(_map, _letter, _title))


def to_pdf(docx_path: Path) -> Path | None:
    """Word is the converter: OMG documents are Word documents, and Word is what is installed here."""
    pdf_path = docx_path.with_suffix(".pdf")
    script = (
        "$w = New-Object -ComObject Word.Application; $w.Visible = $false; "
        f"$d = $w.Documents.Open('{docx_path}'); "
        "$d.Fields.Update() | Out-Null; "
        f"$d.SaveAs([ref]'{pdf_path}', [ref]17); $d.Close($false); $w.Quit()"
    )
    result = subprocess.run(["powershell", "-NoProfile", "-Command", script], capture_output=True, text=True)
    if result.returncode != 0 or not pdf_path.exists():
        print("PDF conversion failed:\n" + (result.stderr or result.stdout)[-500:], file=sys.stderr)
        return None
    return pdf_path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--part", default="annex-a", choices=sorted(PARTS))
    ap.add_argument("--out", default=str(ROOT / "logs" / "omg"))
    ap.add_argument("--pdf", action="store_true", help="also convert through Word")
    args = ap.parse_args()

    part_title, build = PARTS[args.part]
    doc = OmgDocument(running_title=f"{COVER['title']} {COVER['version']}")
    doc.running_foot()
    doc.cover(COVER, part_title)
    doc.legal_placeholder()
    build(doc)

    out = doc.save(Path(args.out) / f"UML3-{args.part}.docx")
    print(f"wrote {out} ({out.stat().st_size:,} bytes)")
    if args.pdf:
        pdf = to_pdf(out)
        if pdf is None:
            return 2
        print(f"wrote {pdf} ({pdf.stat().st_size:,} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
