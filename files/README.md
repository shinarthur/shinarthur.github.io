# CV — Typst version

```bash
quarto render cv.qmd
```

About 3 seconds. Needs Quarto and R (`knitr`, `yaml`); Typst ships inside
Quarto, no TeX involved.

## Where things live

| File | What it decides |
| ---- | --------------- |
| `cv.qmd` | Which sections appear, in what order, and where pages break |
| `sections/*.yml` | **One section each: its content _and_ its style** |
| `R/cv-defaults.R` | Fallback style values, when a section does not say otherwise |
| `R/cv-helpers.R` | Plumbing. Open it only to add a new `layout:` |

Day to day you should only open `cv.qmd` and one file in `sections/`.

## A section file

Each one is self-contained: a `style:` block and the content, in the same file.

```yaml
section: Education
layout: entries

style:
  entry_gap: 9pt        # between entries
  row_gap: 3pt          # between the lines of one entry
  bullet_gap: 3pt       # last line -> first bullet
  bullet_item_gap: 3pt  # between bullets
  leading: 0.4em        # wrapped lines inside a paragraph

entries:
  - lines:
      - Princeton University
      - Ph.D. in Politics | 2026 - Present
      - 'Fields: International Relations'
```

Any key from `R/cv-defaults.R` can go in any section's `style:`, and it wins
there. Change a value in `cv-defaults.R` to move the whole CV; change it in a
section to move that section only.

## Writing entries

An entry is a **list of lines**. Add, remove or reorder them freely — there are
no fixed `title` / `position` / `location` / `date` fields any more.

- `" | "` inside a line pushes everything after it to the right margin.
- The **first line** of an entry is bold (`title_bold: false` to stop that).
- Anything after `" | "` is italic (`right_italic: false` to stop that).
- `*bold*`, `_italic_`, and `"quotes"` (curled automatically) work anywhere.
- `bullets:` under an entry adds the bullet list.

So two roles at one institution is just a third line, and an extra detail line
is just a fourth:

```yaml
- lines:
    - Lee Kuan Yew School of Public Policy, NUS | Singapore
    - Research Assistant to Dr. Jonathan Chu (Full Time) | Jul 2025 - Jul 2026
    - Research Assistant to Dr. Jonathan Chu (Part Time) | Sep 2023 - Jun 2025
  bullets:
    - Conducted large-scale web scraping of all UN Security Council resolutions.
```

## Indentation

Putting spaces in the YAML does nothing — YAML strips leading whitespace from
plain scalars. Use these instead.

| Style key | Indents |
| --------- | ------- |
| `line_indent` + `indent_from` | an entry's lines |
| `bullet_indent` | the bullet marker |
| `bullet_body_gap` | marker → bullet text |
| `pub_number_width` + `pub_number_gap` | numbered-list text |
| `year_width` + `year_gap` | text in `years` sections |

`indent_from` says which line the indent starts on: `1` indents every line, `2`
gives a hanging indent with the institution flush left and the rest stepped in.

```yaml
style:
  line_indent: 1.2em
  indent_from: 2
```

Only the left-hand text moves — anything after `" | "` stays pinned to the right
margin. If you indent an entry's lines, raise `bullet_indent` to match or the
bullets will sit to the left of the text above them.

A single entry can override the section:

```yaml
- indent: 2em
  indent_from: 1
  lines:
    - ...
```

## Layouts

| `layout:` | Content key | Shape |
| --------- | ----------- | ----- |
| `entries` | `entries:` | lines + optional bullets |
| `numbered` | `items:` | reverse-numbered list |
| `years` | `items:` | `year` column, `text`, optional italic `note` |
| `lines` | `items:` | stacked lines |
| `references` | `people:` | `name`, `lines`, linked `email` |

In `years`, `year` is optional: leave it out and the row lines up under the year
above it.

## The header

`sections/header.yml`. Each contact item takes an `icon` (any Font Awesome name
minus the `fa-` prefix: `envelope`, `github`, `globe`, `linkedin`, `orcid`,
`phone`, `location-dot`), the `text` to show, and an optional `link`.

```yaml
contact:
  - icon: envelope
    text: shinarthur@princeton.edu
    link: mailto:shinarthur@princeton.edu
  - icon: github
    text: shinarthur.github.io
    link: https://shinarthur.github.io
```

## Adding a section

1. Write `sections/<name>.yml` with `section:`, `layout:`, `style:` and content.
2. Add `cv_section("<name>")` to `cv.qmd` where you want it.

To drop a section, comment out its line in `cv.qmd`. To move it, move the line.

## Notes

- **Line spacing**: `leading` is the space between wrapped lines *inside* a
  paragraph. It does not touch the gap between an entry's lines — that is
  `row_gap` — nor between entries, which is `entry_gap`. Turn all three to
  loosen the CV as a whole. Typst's own default `leading` is `0.65em`.
- **Lengths**: `10pt`, `0.75in`, `1.2em`, `2mm`. `em` scales with the font size.
- **Escapes**: write `\$` for a literal dollar sign; `$` starts maths in Typst.
  Email addresses are escaped automatically.
- `typst-show.typ` and `typst-template.typ` are deliberate stubs replacing
  Quarto's default `article` template, which would otherwise impose its own page
  setup over these settings.
