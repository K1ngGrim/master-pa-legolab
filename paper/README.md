# Architecture paper

English conference paper on the middleware architecture, independent of the
German thesis in `../thesis`. It describes the architecture only; the
instantiation in Section V is condensed to what is needed to support the cost
model. No product, vendor or platform names appear in the text, so the paper
covers the whole class of request-driven links with a very small MTU.

## Files

| File | Purpose |
|---|---|
| `paper.typ` | The paper. |
| `refs.bib` | References, grouped by topic. |
| `template/ieee-template.typ` | IEEE template, copied unchanged from the AI-Lab report so both papers build from the same file. |

## Building

```
typst compile paper.typ paper.pdf
```

Requires the font Times New Roman, which the template sets.

## Notes

- Equations are numbered `(1)`, `(2)`, … and referenced as `(@eq:name)`. The
  parentheses are written in the text because `supplement: none` makes Typst
  print the bare number.
- The layer stack and the requirement list are Typst tables rather than
  images, so the paper builds without external figures.
- Section numbering is Roman for level 1 and alphabetic for level 2, which is
  why the text refers to "Section IV-C" and similar in prose.
