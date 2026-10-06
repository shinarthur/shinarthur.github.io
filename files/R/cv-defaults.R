#-------------------------------------------------------------------------------
# cv-defaults.R  --  fallback values only.
#
# You should not need to open this file often. Every key below can be overridden
# inside any section file, in its `style:` block:
#
#     style:
#       entry_gap: 12pt
#       leading: 0.5em
#
# Change it here to move the whole CV; change it in a section to move one
# section. A section's `style:` always wins.
#
# Values are Typst lengths: 10pt, 0.75in, 1.2em, 2mm. Use `em` to make a gap
# scale with the font size.
#-------------------------------------------------------------------------------

cv_defaults <- list(

  ## Page (global only -- a section cannot change these) ------------------------
  paper        = "a4",
  margin_top   = "0.75in",
  margin_bottom = "0.75in",
  margin_left  = "0.75in",
  margin_right = "0.75in",
  font         = "New Computer Modern",
  size         = "12pt",
  justify      = TRUE,
  # Links: colour only, no underline.
  link_color     = "#00384D",
  link_underline = FALSE,

  ## Line spacing --------------------------------------------------------------
  # Space between wrapped lines inside one paragraph. Typst's own default is
  # 0.65em. This is the dial for "the whole thing feels too tight / too airy".
  leading = "0.65em",

  ## Header --------------------------------------------------------------------
  name_size      = "20pt",
  name_smallcaps = TRUE,
  contact_size   = "10pt",
  contact_sep    = "  ·  ",
  icon_gap       = "0.4em",   # icon -> the text beside it
  header_gap     = "6pt",     # name -> contact line
  header_below   = "10pt",    # contact line -> first section

  ## Section headings ----------------------------------------------------------
  section_size      = "14pt",
  section_smallcaps = TRUE,
  section_above     = "22pt",   # previous content -> heading
  section_below     = "13pt",    # rule -> first entry
  rule_gap          = "6pt",    # heading text -> rule
  rule_weight       = "0.6pt",
  rule_color        = "#5d5d5d",

  ## Entries -------------------------------------------------------------------
  entry_gap    = "13pt",    # between entries
  row_gap      = "0.65em",    # between the lines of one entry
  right_width  = "4cm",    # right-hand column, for whatever follows " | "

  # Indent for an entry's lines. Only the left-hand text moves; anything after
  # " | " stays pinned to the right margin.
  #   line_indent = "0pt"  no indent (flush left)
  #   indent_from = 1      indent every line
  #   indent_from = 2      hanging indent: line 1 flush, the rest indented
  # Putting spaces in the YAML does nothing -- YAML strips them. Use this.
  line_indent  = "1.1em",
  indent_from  = 2,

  title_bold   = TRUE,     # first line of an entry is bold (left side only)
  right_italic = TRUE,    # everything after " | " is italic

  ## Bullets -------------------------------------------------------------------
  bullet_gap      = "14pt",     # last line of the entry -> first bullet
  bullet_item_gap = "3pt",     # between bullets
  bullet_indent   = "1.1em",   # left edge -> marker
  bullet_body_gap = "0.6em",   # marker -> text
  bullet_marker   = "  •",

  ## Numbered lists ------------------------------------------------------------
  pub_gap          = "15pt",
  pub_number_width = "2em",
  pub_number_gap   = "1.6em",
  pub_marker       = "number",  # "number", "bullet" or "none"
  pub_number_bold  = TRUE,   # bold the numbers ("number" only)
  pub_reverse      = TRUE,   # count down, so the newest keeps the highest number

  ## Year-labelled lists (teaching, awards) ------------------------------------
  year_width = "1.4cm",
  year_gap   = "1.6em",
  item_gap   = "0.9em",    # between rows
  note_gap   = "0.65em",    # row -> its italic note

  ## References ----------------------------------------------------------------
  ref_gap      = "16pt",   # between referees
  ref_line_gap = "6pt",   # between the lines of one referee

  ## Footer --------------------------------------------------------------------
  footer_size      = "10pt",
  footer_smallcaps = TRUE
)
