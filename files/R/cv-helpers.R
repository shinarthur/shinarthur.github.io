#-------------------------------------------------------------------------------
# cv-helpers.R  --  plumbing.
#
# Reads sections/*.yml and writes Typst. You edit sections/*.yml (content AND
# style) and cv.qmd (which sections, in what order). This file only needs
# opening if you want a new `layout:`.
#
# How style resolution works: cv_defaults from R/cv-defaults.R, overridden by
# the section's own `style:` block, passed as arguments to the Typst layout
# functions. So a section's spacing is decided entirely inside that section.
#-------------------------------------------------------------------------------

library(yaml)

source("R/cv-defaults.R")

SECTION_DIR <- "sections"

#-------------------------------------------------------------------------------
#   Utilities
#-------------------------------------------------------------------------------

read_section <- function(name) {
  path <- if (file.exists(name)) name else file.path(SECTION_DIR, paste0(name, ".yml"))
  if (!file.exists(path)) stop("no section file: ", path)
  txt <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  tryCatch(yaml::yaml.load(txt), error = function(e) {
    stop(sprintf(
      "%s is not valid YAML.\n  %s\n\n%s",
      path, conditionMessage(e),
      paste(
        "Most often this is an unquoted line starting with a special",
        "character. YAML reads a leading * as an alias and & as an anchor, so",
        "*Research Assistant* fails to parse. Wrap the whole line in single",
        "quotes:\n",
        "    - '*Research Assistant* to Dr. Chu | 2023 - 2026'\n",
        "The same applies to a line containing \": \" (quote it) or starting",
        "with %, @, `, >, |, {, [ or ?.", sep = " ")),
      call. = FALSE)
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Section `style:` beats cv_defaults.
resolve_style <- function(d) modifyList(cv_defaults, d$style %||% list())

emit <- function(...) {
  cat("\n```{=typst}\n", paste0(..., collapse = ""), "\n```\n", sep = "")
}

# "@" starts a reference in Typst markup, so a bare email needs escaping.
esc <- function(x) gsub("@", "\\@", x, fixed = TRUE)

# Typst reads certain characters at the START of content as list markup, which
# silently indents the text. A entry opening "2026. Chu, J" becomes an ordered
# list item numbered 2026; one opening "- " or "+ " becomes a bullet. Escape the
# marker so the text stays text.
esc_leading <- function(x) {
  x <- sub("^(\\s*)([0-9]+)\\.(\\s)", "\\1\\2\\\\.\\3", x)   # 2026.
  x <- sub("^(\\s*)([-+/])(\\s)",     "\\1\\\\\\2\\3", x)     # -  +  /
  x
}

ct  <- function(x) paste0("[", esc_leading(esc(paste(x, collapse = ""))), "]")
tstr  <- function(x) paste0("\"", x, "\"")
tbool <- function(x) if (isTRUE(x)) "true" else "false"

# A line in `lines:` is either
#   - a plain string, taking the entry's row_gap and indent, or
#   - a mapping overriding either of those for that one line:
#         - text: Ph.D., Department of Politics | 2026 - Present
#           indent: 1em     # how far in this line sits
#           gap: 6pt        # space above this line
parse_line <- function(ln, row_gap) {
  if (is.character(ln)) return(list(text = ln, gap = row_gap, indent = NULL))
  if (is.list(ln)) {
    if (!is.null(ln$text)) {
      return(list(text = ln$text, gap = ln$gap %||% row_gap, indent = ln$indent))
    }
    # An unquoted line containing ": " (e.g. `- Subfields: International
    # Relations`) is read by YAML as a mapping. Put it back together.
    if (length(ln) == 1L && !is.null(names(ln)) && is.character(ln[[1]])) {
      return(list(text = paste0(names(ln)[1], ": ", ln[[1]]),
                  gap = row_gap, indent = NULL))
    }
  }
  stop("could not read a line in `lines:`. If it contains a colon, quote it, ",
       "e.g. 'Subfields: International Relations'.")
}

# " | " in a line pushes everything after it to the right margin.
split_row <- function(line) {
  parts <- strsplit(line, " | ", fixed = TRUE)[[1]]
  list(left  = parts[1],
       right = if (length(parts) > 1) paste(parts[-1], collapse = " | ") else "")
}

# Wrap a content block in a Typst function, or leave it alone.
wrap <- function(body, fn, on) if (isTRUE(on)) paste0(fn, body) else body

#-------------------------------------------------------------------------------
#   Preamble: page setup and the layout functions (spacing comes in per call)
#-------------------------------------------------------------------------------
cv_preamble <- function(header = "header", defaults = cv_defaults) {
  h <- read_section(header)
  th <- modifyList(defaults, h$style %||% list())

  footer <- paste0(
    "align(center)[#text(size: ", th$footer_size, ")[#",
    wrap(ct(h$footer %||% ""), "smallcaps", th$footer_smallcaps),
    "#h(0.8em) · #h(0.8em)#context counter(page).display()]]")

  emit(sprintf('
#import "@preview/fontawesome:0.5.0": *

// ============================================================================
// Page setup. Global defaults live in R/cv-defaults.R; per-section spacing is
// passed into the functions below, so a section file can override anything.
// ============================================================================

#set page(
  paper: %s,
  margin: (top: %s, bottom: %s, left: %s, right: %s),
  footer: %s,
)
#set text(font: %s, size: %s)
#set par(leading: %s, spacing: 0pt, justify: %s)
#set smartquote(enabled: true)
#show link: it => text(fill: rgb(%s))[%s]

// ---- section heading -------------------------------------------------------

#let cv-section(title, size: 14pt, above: 14pt, below: 6pt,
                rule-gap: 2pt, rule-weight: 0.6pt, rule-color: gray,
                caps: true) = block(above: above, below: below, width: 100%%)[
  #text(size: size)[#if caps [#smallcaps(title)] else [#title]]
  #v(rule-gap, weak: true)
  #line(length: 100%%, stroke: rule-weight + rule-color)
]

// ---- one line of an entry: free text left, fixed-width column right --------

#let cv-row(lhs, rhs, right-width: 4cm) = grid(
  columns: (1fr, right-width), column-gutter: 0.8em,
  lhs, align(right)[#rhs],
)

// ---- bullets ---------------------------------------------------------------

#let cv-bullets(items, above: 3pt, item-gap: 3pt,
                indent: 1.1em, body-gap: 0.6em, marker: [•]) = block(
  above: above, below: 0pt,
)[
  #grid(columns: (indent, 1fr), column-gutter: body-gap, row-gutter: item-gap,
    ..items.map(it => (marker, it)).flatten())
]

// ---- an entry: any number of lines, then optional bullets ------------------

// `rows` are (left, right, gap-above) triples. The gap on the first row is
// ignored -- space above an entry is `gap`.
#let cv-entry(rows, bullets: (), gap: 9pt, right-width: 4cm,
              bullet-gap: 3pt, bullet-item-gap: 3pt, bullet-indent: 1.1em,
              bullet-body-gap: 0.6em, bullet-marker: [•]) = block(
  above: gap, below: 0pt, width: 100%%,
)[
  #for (i, row) in rows.enumerate() {
    let (l, r, g) = row
    if i > 0 { v(g) }
    cv-row(l, r, right-width: right-width)
  }
  #if bullets.len() > 0 [#cv-bullets(bullets, above: bullet-gap,
      item-gap: bullet-item-gap, indent: bullet-indent,
      body-gap: bullet-body-gap, marker: bullet-marker)]
]

// ---- numbered list ---------------------------------------------------------

// `marker` is "number", "bullet" or "none".
#let cv-pubs(items, above: 6pt, gap: 5pt, number-width: 1.8em,
             number-gap: 0.6em, bold: true, reverse: true,
             marker: "number", bullet: [•]) = block(
  above: above, below: 0pt, width: 100%%,
)[
  #let n = items.len()
  #grid(columns: (number-width, 1fr), column-gutter: number-gap, row-gutter: gap,
    ..items.enumerate().map(((i, it)) => {
      let label = if marker == "bullet" { bullet } else if marker == "none" { [] }
                  else { [#(if reverse { n - i } else { i + 1 }).] }
      let cell = if bold and marker == "number" { strong(label) } else { label }
      (align(right)[#cell], it)
    }).flatten())
]

// ---- year-labelled rows ----------------------------------------------------

#let cv-years(rows, above: 6pt, gap: 5pt,
              year-width: 1.6cm, year-gap: 0.6em) = block(
  above: above, below: 0pt, width: 100%%,
)[
  #grid(columns: (year-width, 1fr), column-gutter: year-gap, row-gutter: gap,
    ..rows.map(((y, body)) => (align(right)[#y], body)).flatten())
]

// ---- stacked lines / referees ----------------------------------------------

#let cv-stack(items, above: 6pt, gap: 5pt) = block(
  above: above, below: 0pt, width: 100%%,
)[
  #grid(columns: (1fr,), row-gutter: gap, ..items)
]
',
    tstr(th$paper), th$margin_top, th$margin_bottom, th$margin_left, th$margin_right,
    footer,
    tstr(th$font), th$size,
    th$leading, tbool(th$justify),
    tstr(th$link_color),
    if (isTRUE(th$link_underline)) "#underline(it)" else "#it"))
}

#-------------------------------------------------------------------------------
#   Header
#-------------------------------------------------------------------------------
cv_header <- function(name = "header", defaults = cv_defaults) {
  h <- read_section(name)
  th <- modifyList(defaults, h$style %||% list())

  bits <- vapply(h$contact %||% list(), function(c) {
    label <- esc(c$text)
    if (!is.null(c$link)) label <- sprintf("#link(\"%s\")[%s]", c$link, label)
    if (!is.null(c$icon)) {
      label <- sprintf("#fa-%s()#h(%s)%s", c$icon, th$icon_gap, label)
    }
    label
  }, character(1))

  parts <- character(0)
  if (!is.null(h$name)) {
    parts <- c(parts, sprintf("  #text(size: %s)[#%s]\n  #v(%s, weak: true)\n",
                              th$name_size,
                              wrap(ct(h$name), "smallcaps", th$name_smallcaps),
                              th$header_gap))
  }
  parts <- c(parts, sprintf("  #text(size: %s)[%s]\n", th$contact_size,
                            paste(bits, collapse = th$contact_sep)))

  emit(sprintf("#align(center)[\n%s]\n#v(%s, weak: true)\n",
               paste(parts, collapse = ""), th$header_below))
}

#-------------------------------------------------------------------------------
#   Layouts
#-------------------------------------------------------------------------------

# entries: each entry is a list of `lines`, plus optional `bullets`.
render_entries <- function(d, th) {
  paste0(vapply(d$entries, function(e) {
    indent  <- e$indent %||% th$line_indent
    from    <- e$indent_from %||% th$indent_from
    row_gap <- e$row_gap %||% th$row_gap
    rows <- vapply(seq_along(e$lines), function(i) {
      p   <- parse_line(e$lines[[i]], row_gap)
      txt <- p$text
      g   <- p$gap
      r <- split_row(txt)
      lhs <- wrap(ct(r$left), "strong", i == 1 && isTRUE(th$title_bold))
      # A line's own `indent:` wins; otherwise the section's line_indent applies
      # from line `indent_from` onwards. Only the left-hand text moves, so the
      # right column stays pinned to the margin.
      ind_i <- p$indent %||% (if (i >= from) indent else "0pt")
      if (!identical(ind_i, "0pt")) {
        lhs <- sprintf("pad(left: %s, %s)", ind_i, lhs)
      }
      rhs <- if (nzchar(r$right)) wrap(ct(r$right), "emph", th$right_italic) else "[]"
      sprintf("  (%s, %s, %s)", lhs, rhs, g)
    }, character(1))
    args <- c(sprintf("(\n%s,\n)", paste(rows, collapse = ",\n")))
    if (length(e$bullets %||% list()) > 0) {
      args <- c(args, sprintf("bullets: (%s,)",
                              paste(vapply(unlist(e$bullets), ct, character(1)),
                                    collapse = ", ")))
    }
    args <- c(args, sprintf("gap: %s", e$gap %||% th$entry_gap),
              sprintf("right-width: %s", th$right_width),
              sprintf("bullet-gap: %s", th$bullet_gap),
              sprintf("bullet-item-gap: %s", th$bullet_item_gap),
              sprintf("bullet-indent: %s", th$bullet_indent),
              sprintf("bullet-body-gap: %s", th$bullet_body_gap),
              sprintf("bullet-marker: %s", ct(th$bullet_marker)))
    sprintf("#cv-entry(%s)\n", paste(args, collapse = ", "))
  }, character(1)), collapse = "")
}

render_numbered <- function(d, th) {
  sprintf(paste("#cv-pubs((%s,), above: %s, gap: %s, number-width: %s,",
                "number-gap: %s, bold: %s, reverse: %s, marker: %s, bullet: %s)\n"),
          paste(vapply(unlist(d$items), ct, character(1)), collapse = ", "),
          th$section_below, th$pub_gap, th$pub_number_width, th$pub_number_gap,
          tbool(th$pub_number_bold), tbool(th$pub_reverse),
          tstr(th$pub_marker), ct(th$bullet_marker))
}

# years: `year` (optional) + `text` + optional `note`.
render_years <- function(d, th) {
  rows <- vapply(d$items, function(r) {
    body <- if (is.null(r$note)) ct(r$text) else sprintf(
      "[\n    %s\n    #v(%s, weak: true)\n    #emph%s\n  ]",
      esc(r$text), th$note_gap, ct(r$note))
    sprintf("  (%s, %s)", ct(r$year %||% ""), body)
  }, character(1))
  sprintf("#cv-years((\n%s,\n), above: %s, gap: %s, year-width: %s, year-gap: %s)\n",
          paste(rows, collapse = ",\n"), th$section_below, th$item_gap,
          th$year_width, th$year_gap)
}

render_lines <- function(d, th) {
  sprintf("#cv-stack((%s,), above: %s, gap: %s)\n",
          paste(vapply(unlist(d$items), ct, character(1)), collapse = ", "),
          th$section_below, th$item_gap)
}

render_references <- function(d, th) {
  blocks <- vapply(d$people, function(p) {
    detail <- paste0(sprintf("\n  #v(%s, weak: true)\n  %s",
                             th$ref_line_gap, esc(unlist(p$lines))), collapse = "")
    mail <- if (is.null(p$email)) "" else sprintf(
      "\n  #v(%s, weak: true)\n  Email: #link(\"mailto:%s\")[%s]",
      th$ref_line_gap, p$email, esc(p$email))
    sprintf("[\n  #strong%s%s%s\n]", ct(p$name), detail, mail)
  }, character(1))
  sprintf("#cv-stack((\n%s,\n), above: %s, gap: %s)\n",
          paste(blocks, collapse = ",\n"), th$section_below, th$ref_gap)
}

#-------------------------------------------------------------------------------
#   Render one section
#-------------------------------------------------------------------------------
cv_section <- function(name) {
  d  <- read_section(name)
  th <- resolve_style(d)

  body <- switch(d$layout %||% "entries",
    entries    = render_entries(d, th),
    numbered   = render_numbered(d, th),
    years      = render_years(d, th),
    lines      = render_lines(d, th),
    references = render_references(d, th),
    stop("unknown layout '", d$layout, "' in ", name))

  heading <- sprintf(
    "#cv-section(%s, size: %s, above: %s, below: %s, rule-gap: %s, rule-weight: %s, rule-color: rgb(%s), caps: %s)\n",
    ct(d$section), th$section_size, th$section_above,
    th$section_below, th$rule_gap, th$rule_weight, tstr(th$rule_color),
    tbool(th$section_smallcaps))

  # Scope this section's line spacing to this section.
  emit(sprintf("%s#[\n#set par(leading: %s)\n%s]\n", heading, th$leading, body))
}

cv_raw <- function(...) emit(...)
