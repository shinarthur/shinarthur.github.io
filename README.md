# shinarthur

Personal academic website, built with [Quarto](https://quarto.org) and published
to GitHub Pages. Every file is hand-edited — there is no generator, so what you
open is what renders.

```
_quarto.yml       site title, nav, footer, theme wiring
index.qmd         home — profile rail (photo, links) + about text
research.qmd      publications, working papers, work in progress
cv.qmd            CV page; PDF lives in files/
styles/
  theme.scss      design tokens + header/footer rules
  styles.css      page grid and content blocks
images/           profile photo
files/            CV and paper PDFs
```

## Everyday edits

**Add a paper.** Copy a `.pub` block in `research.qmd` and renumber the
`[n]{.pubnum}` values below it. The pieces are optional — drop `.status`,
`.award`, the `<details>` abstract or the link row if an entry does not need
them.

```markdown
::::: {.pub}
[1]{.pubnum}

::: {.pub-body}
**[Article title](https://doi.org/...)** [Forthcoming]{.status}<br>
with [Coauthor](https://example.com).<br>
[*Journal Name*, 2026.]{.venue}

<details>
<summary>Abstract</summary>

Abstract text.

</details>

[[PDF](files/paper.pdf)]
:::

:::::
```

**Add a page.** Create `newpage.qmd` and add it under `navbar: right:` in
`_quarto.yml`.

**Replace the portrait.** Drop a roughly 289×338 (or any 6:7) image into
`images/` and point `about: image:` in `index.qmd` at it.

**Move the whole site.** `styles/theme.scss`. Change `$accent` and every link,
publication number and active nav item follows. Change `--measure` and the home
page and interior pages re-lay out together.

## Content blocks

| Wrapper | For | Inner spans |
| --- | --- | --- |
| `::::: {.pub}` + `::: {.pub-body}` | Publications | `[n]{.pubnum}`, `{.status}`, `{.venue}`, `{.award}` |
| `::: {.course}` | CV / course entries | `{.course-meta}` |
| `::: {.updates}` around a list | Dated lines | `{.u-date}` |
| `[text]{.eyebrow}` inside an `##` | Small uppercase kicker | — |
| `[text]{.lead}` | Opening sentence | — |

## Design

A blend of three sites, measured at a 1280px viewport rather than eyeballed.

| Layer | From | What it contributes |
| --- | --- | --- |
| Header | [realworlddatascience.net](https://realworlddatascience.net) | Pinned bar with a black block flush top-left, white uppercase Oswald name, links bottom-aligned against it, bone ground, 1px black rule. 104px tall here. |
| Body and rail | [chriswblair.com](https://chriswblair.com) | Source Sans 3 at 17px/1.6, navy `#1f4e79`, bold in-text links, numbered publication rows, a 17em rounded portrait with bordered pill links beneath. |
| Page grid | [academicpages](https://github.com/academicpages/academicpages.github.io) / [tanjingling.github.io](https://tanjingling.github.io) | Rail + gutter + 760px measure, left of centre with whitespace right; rule *under* each h2. |

The profile rail is a home-page feature. Interior pages centre the same 760px
measure inside rail+gutter+measure, so the absent rail does not read as a hole
down the left.

### Two Quarto gotchas

Worth knowing before touching `styles/styles.css`:

- Quarto appends its **own** rules after a user theme's `scss:rules`, so
  overrides of `.quarto-about-*`, the page grid and heading styles only land
  from `styles.css`, the last stylesheet in the head. A few still need
  `!important`; they are grouped at the bottom under "Hard overrides".
- `main.content` and the about block sit in Quarto's `page-columns` CSS grid.
  `max-width` can only shrink an item inside its track, never move it, so both
  get `grid-column: 1 / -1` and then an explicit `width` and `margin-left`.
  That is what keeps the text column on the same x on every page. It depends on
  `page-layout: full`, set in `_quarto.yml`.

## Build

```bash
quarto preview
```

```bash
quarto render
```

No R packages needed — nothing runs before the render.

## Deploy

`.github/workflows/publish.yml` renders on every push to `main` and deploys to
GitHub Pages. Enable it once under **Settings → Pages → Source → GitHub
Actions**.

## Placeholders

All prose is bracketed placeholder text. `images/profile.svg` is a grey
stand-in. Search for `EXAMPLE` for the remaining stub URLs, and confirm the
contact address in `_quarto.yml` and `index.qmd`.
