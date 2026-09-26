# OMG document conventions

What a document has to look like to be an OMG specification, taken from a published one rather than from memory:
**OMG Systems Modeling Language (SysML) 2.0, Part 1: Language Specification**, read at
`E:\_Documents\_SysMLV2\Standards\SysMLv2.pdf` (the copy on hand is `formal/2025-09-03`; omg.org now lists the
same version 2.0 as `formal/26-03-02` for Part 1 and `formal/26-03-03` for Part 2 — cite the current number).
The RFP this project answers, `ad/2026-04-01`, follows the separate **Abbreviated RFP Template ab/22-09-05**,
whose Sections 1–5 are fixed boilerplate from `ab/22-09-01` and whose Section 6 carries the RFP-specific content.

This file exists so that "OMG conforming" is a checkable property and not an opinion. It describes the target;
`tools/` will generate against it, as `check_traceability.py` already generates the markdown traceability report
from `traceability/uml2-to-uml3.json`.

## Why this is cheap for this project

Every document here is already generated from structured sources: the traceability report from JSON, the
requirements catalog from `requirements/*.sysml`, the keyword tables from `library/`. Markdown is one rendering.
An OMG document is a second rendering of the same content, not a second copy to keep in step.

## Document structure

A specification has, in this order:

1. **Cover page.** OMG logo top right; "An OMG&reg; *(group)* Publication" right-aligned; the specification's own
   logo left; the title in large bold sans; the version; the part, when the specification has parts. Then a rule,
   and the block: **OMG Document Number**, **Date**, **Standard document URL**, **Machine Readable File(s)**,
   and a closing rule.
2. **Copyright page.** One `Copyright © <years>, <organization>` line per contributing organization.
3. **Legal boilerplate**, verbatim and unaltered: USE OF SPECIFICATION — TERMS, CONDITIONS & NOTICES; LICENSES;
   PATENTS; GENERAL USE RESTRICTIONS; DISCLAIMER OF WARRANTY; RESTRICTED RIGHTS LEGEND; TRADEMARKS; COMPLIANCE;
   OMG'S ISSUE REPORTING PROCEDURE. The warranty and liability paragraphs are set in capitals.
4. **Preface**: about OMG, OMG Specifications, OMG Headquarters.
5. **Table of Contents.**
6. **The clauses**, numbered from 1. The first six are fixed by the OMG/ISO skeleton:

| Clause | Title | What goes in it |
|---|---|---|
| 1 | Scope | what the specification defines, and for whom |
| 2 | Conformance | what a conforming model is, and the ways a tool can conform |
| 3 | Normative References | the documents the specification depends on, with their document numbers |
| 4 | Terms and Definitions | may be a single sentence pointing into the body |
| 5 | Symbols | may be a single sentence pointing at the notation clause |
| 6 | Introduction | Document Overview, Document Organization, Acknowledgements |
| 7+ | technical clauses | the specification proper |

7. **Annexes**, marked normative or informative.

Clauses 4 and 5 are short in SysML v2 — "Various terms and definitions are specified throughout the body of this
specification." — but they are present. The skeleton is not optional; the content of each part can be brief.

## Conformance, which is the clause a new specification must earn

SysML v2 states it in three parts, and it is the pattern to follow:

* **What the specification comprises** — this document together with the machine-readable files on the cover page,
  and which takes precedence when they disagree.
* **When a model conforms** — "A SysML model **shall** conform to this specification only if it can be represented
  according to the syntactic requirements specified in Clause 8."
* **How a tool conforms**, as numbered, nameable levels that a product can claim: Abstract Syntax Conformance,
  Concrete Syntax Conformance (with Textual Notation and Graphical Notation variants), Semantic Conformance, each
  saying what the tool must provide and which subclause defines it.

UML3 can state the same three levels, because it has the same shape: a library and keywords (abstract syntax), a
textual notation (UML3 and its SysUML form), and a graphical notation (the diagram kinds of `UML3Views`). The
requirements catalog already carries the per-requirement verification method that a conformance clause needs.

## House style

* **Normative language**: *shall* for requirements, *should* for recommendations, *may* for permission. Never
  "must" in normative sentences — SysML v2 uses "must" only inside descriptive prose.
* **Cross references** are written `Clause 8`, `8.2`, `8.2.2` — the word "Clause" for a whole clause, the bare
  number for a subclause.
* **Headings** are sans-serif and bold, numbered `1`, `1.1`, `1.1.1`; **body** is serif.
* **Running foot** carries the specification name, version and part with the page number, on the outer edge:
  `Systems Modeling Language v2.0, Part 1    7`.
* **Figures and tables** are numbered and captioned.

## Output formats

OMG submissions are Word documents, and the PDF is produced from them. On this machine: no `pandoc` and no
`wkhtmltopdf`, but `pip`, **Word COM 16.0** and **LaTeX** are present, so the intended chain is
`python-docx` → `.docx` carrying the OMG styles → Word COM → PDF. `pdftotext` is present and is how this file was
derived from the published specification; it is also how `check_docs.py` already verifies clause citations.

## Open points

1. ~~Which document first.~~ **Settled**: the specification's layout is in
   [UML3-SPECIFICATION-OUTLINE.md](UML3-SPECIFICATION-OUTLINE.md) — Clause 7 the UML metamodel, 8 the UML3
   language, 9 the extension of SysML v2, then the mapping, requirements, example and tutorial annexes, which may
   be separate volumes. The traceability annex is the pilot for the renderer, because it is already generated.
2. **The OMG specification template.** `E:\_Documents\_OMG` holds the RFP and the Policies and Procedures, but no
   specification template with the real Word styles. Without it the styles here are reconstructed from the
   published PDF: close, but not authoritative.
3. **The legal boilerplate** must be copied from a current OMG specification rather than retyped, and the
   copyright list depends on who submits.
