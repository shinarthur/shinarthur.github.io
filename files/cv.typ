// Simple numbering for non-book documents
#let equation-numbering = "(1)"
#let callout-numbering = "1"
#let subfloat-numbering(n-super, subfloat-idx) = {
  numbering("1a", n-super, subfloat-idx)
}

// Theorem configuration for theorion
// Simple numbering for non-book documents (no heading inheritance)
#let theorem-inherited-levels = 0

// Theorem numbering format (can be overridden by extensions for appendix support)
// This function returns the numbering pattern to use
#let theorem-numbering(loc) = "1.1"

// Default theorem render function
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  if full-title != "" and full-title != auto and full-title != none {
    strong[#full-title.]
    h(0.5em)
  }
  body
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



// Stub replacing Quarto's default `article` template. Unused: typst-show.typ
// never calls it, because the document configures itself from R/cv-theme.R.
// Nothing to edit here -- edit R/cv-theme.R.
#let article(..args) = args.pos().last()
#let brand-color = (:)
#let brand-color-background = (:)
#let brand-logo = (:)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
  columns: 1,
)

// Quarto would normally wrap the document in its `article` template here,
// which sets its own page size, fonts and heading styles. This CV sets all of
// that itself from R/cv-theme.R, so this partial is deliberately empty.
// Nothing to edit here -- edit R/cv-theme.R.


#import "@preview/fontawesome:0.5.0": *

// ============================================================================
// Page setup. Global defaults live in R/cv-defaults.R; per-section spacing is
// passed into the functions below, so a section file can override anything.
// ============================================================================

#set page(
  paper: "a4",
  margin: (top: 0.75in, bottom: 0.75in, left: 0.75in, right: 0.75in),
  footer: align(center)[#text(size: 10pt)[#smallcaps[Shin]#h(0.8em) · #h(0.8em)#context counter(page).display()]],
)
#set text(font: "New Computer Modern", size: 12pt)
#set par(leading: 0.65em, spacing: 0pt, justify: true)
#set smartquote(enabled: true)
#show link: it => text(fill: rgb("#00384D"))[#it]

// ---- section heading -------------------------------------------------------

#let cv-section(title, size: 14pt, above: 14pt, below: 6pt,
                rule-gap: 2pt, rule-weight: 0.6pt, rule-color: gray,
                caps: true) = block(above: above, below: below, width: 100%)[
  #text(size: size)[#if caps [#smallcaps(title)] else [#title]]
  #v(rule-gap, weak: true)
  #line(length: 100%, stroke: rule-weight + rule-color)
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
  above: gap, below: 0pt, width: 100%,
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
  above: above, below: 0pt, width: 100%,
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
  above: above, below: 0pt, width: 100%,
)[
  #grid(columns: (year-width, 1fr), column-gutter: year-gap, row-gutter: gap,
    ..rows.map(((y, body)) => (align(right)[#y], body)).flatten())
]

// ---- stacked lines / referees ----------------------------------------------

#let cv-stack(items, above: 6pt, gap: 5pt) = block(
  above: above, below: 0pt, width: 100%,
)[
  #grid(columns: (1fr,), row-gutter: gap, ..items)
]
#align(center)[
  #text(size: 20pt)[#smallcaps[Arthur Jun. Shin]]
  #v(10pt, weak: true)
  #text(size: 10pt)[Fisher Hall, Princeton NJ 08544  ·  #fa-envelope()#h(0.4em)#link("mailto:shinarthur@princeton.edu")[shinarthur\@princeton.edu]  ·  #fa-earth-americas()#h(0.4em)#link("https://shinarthur.github.io")[shinarthur.github.io]]
]
#v(17pt, weak: true)
#cv-section([Education], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.65em)
#cv-entry((
  (strong[Princeton University], emph[2026 - Present], 0.65em),
  (pad(left: 1.1em, [Ph.D., Department of Politics]), [], 0.65em),
  (pad(left: 1.1em, [_Subfield: International Relations_]), [], 0.65em),
), gap: 13pt, right-width: 4cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  (strong[National University of Singapore], emph[2023 - 2025], 0.65em),
  (pad(left: 1.1em, [Master in International Affairs]), [], 0.65em),
), gap: 13pt, right-width: 4cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  (strong[University of Hong Kong], emph[2018 - 2019], 0.65em),
  (pad(left: 1.1em, [Master of International and Public Affairs (Distinction)]), [], 0.65em),
), gap: 13pt, right-width: 4cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  (strong[University College London], emph[2014 - 2017], 0.65em),
  (pad(left: 1.1em, [Bachelor of Laws, LL.B. (Honors)]), [], 0.65em),
), gap: 13pt, right-width: 4cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
]
#cv-section([Working Papers], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.65em)
#cv-pubs((["Diversified Balancing: How External Security Threats Drive Arms Supplier Diversification"], ["Introducing the Security Council and Use of Force Justification (SCRUFJ) Text Corpus Dataset" - with Chu, J.], ["How Firms Respond to Regulatory Ambiguity: Rhetorical Political Alignment After China's Tech Crackdown" - with Zhang, Z. & Zhang, C.],), above: 13pt, gap: 15pt, number-width: 2em, number-gap: 1.6em, bold: true, reverse: true, marker: "number", bullet: [  •])
]
#cv-section([Policy Publications], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.65em)
#cv-pubs(([Lew, S., *Shin, A*, Ludwig, M. (2024).  "Court Decisions on Gerrymandering Can Mobilize Voters."  _Georgetown Public Policy Review, Elections Edition,_ 26-30.], [San Andres, E. Vasquez, G., Chen, T., *Shin, A.* (2024).  "Enhancing MSME Data Interoperability in the APEC Region." _APEC Issues Paper_ No. 14.],), above: 13pt, gap: 15pt, number-width: 2em, number-gap: 1.6em, bold: true, reverse: true, marker: "number", bullet: [  •])
]
#cv-section([Presentations], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.4em)
#cv-entry((
  ([2026\. Chu, J, *Shin, A.* "Introducing the Security Council and Use of Force Justification Text Corpus Dataset." _Pacific International Politics Conference_ (USA).], [], 0.5em),
), gap: 13pt, right-width: 0cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([2026\. Zhang, Z., *Shin, A.*, Zhang, C. "Signaling Nationalism: How Firms Use Political Rhetoric under Regulatory Uncertainty during China's 2020 Tech Crackdown." _LKYSPP IR Brownbag_ (Singapore).], [], 0.5em),
), gap: 13pt, right-width: 0cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([2026\. 'Zhang, Z, *Shin, A*, and Zhang, C. "Signaling Nationalism."  _Asia-Pacific Politics and Public Administration Conference_ (Hong Kong).], [], 0.5em),
), gap: 13pt, right-width: 0cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([2025\. *Shin, A*. "Diversified Balancing: How External Security Threats Drive Arms Supplier Diversification." _Pacific International Politics Conference_ (Japan).], [], 0.5em),
), gap: 13pt, right-width: 0cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([2025\. Lew, S., *Shin, A.*, Lee, J., Tan, K. "Informing the Digital Economy Framework Agreement Through the Language of Current Agreements." _Asia Competitiveness Institute Annual Research Conference_ (Singapore).], [], 0.5em),
), gap: 13pt, right-width: 0cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([2024\. Lew, S., *Shin, A.*, Lee, J. "Digital Economy Agreements as Data: A Natural Language Processing Analysis of the Digital Economy of ASEAN." _Asia Competitiveness Institute Data and Policy Analytics Seminar Series_ (online).], [], 0.5em),
), gap: 13pt, right-width: 0cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
]
#cv-section([Awards & Honors], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.65em)
#cv-years((
  ([2025], [*Graduate Student Paper Award*, Pacific International Politics Conference]),
  ([], [*Best Master in International Affairs Student Prize*, LKYSPP]),
  ([], [*Best Master in International Affairs Senior Essay Medal*, LKYSPP]),
  ([], [*Dean's List Award - Spring 2025*, LKYSPP]),
  ([2024], [*Merit Scholarship for Academic Excellence*, LKYSPP]),
  ([], [*Dean's Leadership Award - First Prize*, LKYSPP]),
  ([], [*Dean's List Award - Spring & Fall 2024*, LKYSPP]),
  ([2023], [*Dean's List Award - Fall 2023*, LKYSPP]),
  ([2016], [*UK National Round Semifinalist*, Jessup International Law Competition]),
  ([2014], [*Provost's Excellence Scholarship Award*, UCL]),
), above: 13pt, gap: 0.9em, year-width: 1.4cm, year-gap: 1.6em)
]
#cv-section([Research & Professional Experience], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.4em)
#cv-entry((
  ([*Research Assistant* to Dr. Jacob Shapiro, Princeton University], emph[2026], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([*Research Assistant* to Dr. Jonathan Chu, National University of Singapore], emph[2023 - 2026], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([*Research Assistant* to Dr. Kai Quek, University of Hong Kong], emph[2024 - 2025], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([*Research Intern* at the Asia-Pacific Economic Cooperation], emph[2024], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([*Graduate Research Analyst* at Asia Competitiveness Institute], emph[2023 - 2024], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([*Research Assistant* to Dr. Lami Kim, U.S. Army War College], emph[2022 - 2023], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([*National Service Agent* at Korean Credit Guarantee Fund], emph[2020 - 2022], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([*Legal Intern* at Clifford Chance LLP], emph[2017], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([*Legal Intern* at Rahmat Lim \& Partners], emph[2016], 0.5em),
), gap: 13pt, right-width: 2.5cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
]
#cv-section([Teaching Experience], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.4em)
#cv-entry((
  ([International Relations of Asia, _National University of Singapore_], emph[2025], 0.5em),
), gap: 13pt, right-width: 1cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([Foreign Policy Analysis, _National University of Singapore_], emph[2024], 0.5em),
), gap: 13pt, right-width: 1cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([Survey Design for Researchers and Decision-Makers, _National University of Singapore_], emph[2024], 0.5em),
), gap: 13pt, right-width: 1cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
#cv-entry((
  ([3 Campus East Asia Program, _University of Hong Kong_], emph[2019], 0.5em),
), gap: 13pt, right-width: 1cm, bullet-gap: 14pt, bullet-item-gap: 3pt, bullet-indent: 1.1em, bullet-body-gap: 0.6em, bullet-marker: [  •])
]
#cv-section([Skills], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.65em)
#cv-stack(([*Computer/Programming:* R, Stata, LaTeX, SQL, Qualtrics], [*Languages:* English (native), Korean (native), Mandarin (conversational)],), above: 13pt, gap: 0.9em)
]
#pagebreak()
#cv-section([References], size: 14pt, above: 22pt, below: 13pt, rule-gap: 6pt, rule-weight: 0.6pt, rule-color: rgb("#5d5d5d"), caps: true)
#[
#set par(leading: 0.65em)
#cv-stack((
[
  #strong[Jonathan Art. Chu]
  #v(6pt, weak: true)
  Associate Professor
  #v(6pt, weak: true)
  National University of Singapore
  #v(6pt, weak: true)
  Email: #link("mailto:jonchu@nus.edu.sg")[jonchu\@nus.edu.sg]
],
[
  #strong[Kai Quek]
  #v(6pt, weak: true)
  Associate Professor of Politics
  #v(6pt, weak: true)
  University of Hong Kong
  #v(6pt, weak: true)
  Email: #link("mailto:quek@hku.hk")[quek\@hku.hk]
],
[
  #strong[Adam Yao Liu]
  #v(6pt, weak: true)
  Assistant Professor
  #v(6pt, weak: true)
  National University of Singapore
  #v(6pt, weak: true)
  Email: #link("mailto:sppliuy@nus.edu.sg")[sppliuy\@nus.edu.sg]
],
), above: 13pt, gap: 16pt)
]



