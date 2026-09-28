// ─────────────────────────────────────────────────────────────────────────────
// ieee-template.typ  —  IEEE Conference Paper Template for Typst
// Usage:
//   #import "ieee-template.typ": ieee
//   #show: ieee.with(title: "...", authors: (...), abstract: [...], ...)
// ─────────────────────────────────────────────────────────────────────────────

#let ieee(
  title: "Untitled Paper",

  // Each author: (name: "…", affiliation: "…", email: "…")
  authors: (),

  // Content for the abstract block
  abstract: [],

  // List of index term strings
  index-terms: (),

  // The rest of the document (injected by #show: ieee.with(…))
  doc,
) = {

  // ── Page ───────────────────────────────────────────────────────────────────
  set page(
    paper: "us-letter",
    margin: (top: 0.75in, bottom: 1in, left: 0.625in, right: 0.625in),
    numbering: "1",
    number-align: bottom + center,
  )

  // ── Base typography ────────────────────────────────────────────────────────
  set text(font: "Times New Roman", size: 10pt, lang: "en")
  set par(justify: true, leading: 0.55em, spacing: 0.9em)

  // ── Heading numbering: Roman for level-1, alpha for level-2 ───────────────
  set heading(
    numbering: (..nums) => {
      let v = nums.pos()
      if v.len() == 1 { numbering("I.", v.at(0)) }
      else             { numbering("A.", v.at(1)) }
    }
  )

  show heading.where(level: 1): it => {
    v(1.2em, weak: true)
    align(center,
      text(size: 10pt, weight: "regular")[
        #if it.numbering != none {
          smallcaps(
            context counter(heading).display("I.")
          )
          h(0.4em)
        }
        #smallcaps(it.body)
      ]
    )
    v(0.65em, weak: true)
  }

  show heading.where(level: 2): it => {
    v(0.9em, weak: true)
    text(size: 10pt, style: "italic", weight: "regular")[
      #context counter(heading).display(
        (..n) => numbering("A.", n.pos().at(1))
      )
      #h(0.3em)#it.body
    ]
    v(0.5em, weak: true)
  }

  // ── Figures & tables ───────────────────────────────────────────────────────
  set figure(gap: 0.6em)
  show figure.caption: set text(size: 9pt)

  // ── Bibliography ───────────────────────────────────────────────────────────
  set bibliography(style: "ieee", title: "References")
  show bibliography: set text(size: 9pt)

  // ── Footnotes ──────────────────────────────────────────────────────────────
  set footnote.entry(separator: line(length: 30%, stroke: 0.5pt))

  // ══════════════════════════════════════════════════════════════════════════
  // TITLE BLOCK  (full width)
  // ══════════════════════════════════════════════════════════════════════════
  align(center)[
    #v(0.5em)
    #text(size: 24pt, weight: "bold")[#title]

    #v(0.9em)

    // Author block — names on one line, affiliation + email below
    #let n = authors.len()
    #grid(
      columns: range(n).map(_ => 1fr),
      gutter: 1em,
      ..authors.map(a => align(center)[
        #text(size: 11pt)[#a.name] \
        #text(size: 10pt, style: "italic")[
          #a.affiliation \
          #a.email \
          Student ID: #a.parcel_nr
        ]
      ])
    )
  ]

  v(1.2em)

  // ── Abstract (full width, indented) ───────────────────────────────────────
  pad(x: 0.5in)[
    #text(size: 9pt)[
      #text(weight: "bold")[Abstract—]#abstract

      #if index-terms.len() > 0 {
        v(0.35em)
        text(weight: "bold")[Index Terms—]
        index-terms.join(", ")
      }
    ]
  ]

  v(0.75em)
  line(length: 100%, stroke: 0.5pt)
  v(0.5em)

  // ══════════════════════════════════════════════════════════════════════════
  // TWO-COLUMN BODY
  // ══════════════════════════════════════════════════════════════════════════
  columns(2, gutter: 0.25in, doc)
}
