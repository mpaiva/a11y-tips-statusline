---
description: Search WCAG 2.2 success criteria by keyword, ID, level, or natural language query
---

Search the WCAG 2.2 success criteria for: **$ARGUMENTS**

Use the WCAG JSON file at `~/.claude/wcag-search.json` to find matching criteria.

## Query Interpretation

Before searching, interpret the query "$ARGUMENTS" to determine the best search strategy.

### Step 1: Identify Query Type

1. **Exact ref_id** (pattern like `1.4.3`, `2.1.1`) -> Direct lookup by ref_id
2. **Level filter** (`A`, `AA`, `AAA`, or `level:X`) -> Filter by conformance level
3. **Combined** (`level:AA contrast`) -> Apply level filter AND keyword search
4. **Natural language / Keywords** -> Extract semantic keywords and search

### Step 2: Natural Language Processing

For natural language queries, use this mapping to extract relevant WCAG search terms:

| User Might Say | Search Keywords | Primary Criteria |
|----------------|-----------------|------------------|
| alt text, image description, alternative text | non-text, text alternative, image | 1.1.1 |
| color contrast, readable text, contrast ratio | contrast | 1.4.3, 1.4.6, 1.4.11 |
| keyboard access, tab navigation, no mouse | keyboard | 2.1.1, 2.1.2, 2.1.4 |
| screen reader, assistive technology, AT | name, role, value, programmatic | 4.1.2 |
| focus visible, focus indicator, focus ring | focus | 2.4.7, 2.4.11, 2.4.12 |
| form labels, input labels, field labels | label | 3.3.2, 1.3.1 |
| skip link, skip to content, bypass | bypass | 2.4.1 |
| heading structure, h1-h6, semantic headings | heading, info and relationships | 1.3.1, 2.4.6 |
| captions, subtitles, deaf, hard of hearing | caption | 1.2.2, 1.2.4 |
| audio description, blind, visually impaired | audio description | 1.2.3, 1.2.5 |
| drag and drop, dragging | drag | 2.5.7 |
| button size, touch target, tap target, click area | target size | 2.5.5, 2.5.8 |
| reduce motion, animation, vestibular, parallax | motion | 2.3.3 |
| flashing, seizures, photosensitive, epilepsy | flash | 2.3.1, 2.3.2 |
| error messages, validation, form errors | error | 3.3.1, 3.3.3 |
| autocomplete, autofill, input purpose | input purpose, identify | 1.3.5 |
| zoom, magnification, pinch zoom, text size | resize, reflow | 1.4.4, 1.4.10 |
| mobile, responsive, orientation, portrait | orientation | 1.3.4 |
| timeout, session, time limit | time limit, timing | 2.2.1, 2.2.6 |
| consistent navigation, menu order | consistent | 3.2.3, 3.2.4 |
| language, lang attribute | language | 3.1.1, 3.1.2 |
| ARIA, accessible name, role | name, role, value | 4.1.2 |
| colorblind, color alone, color meaning | use of color | 1.4.1 |
| pause, stop, auto-play, moving content | pause, stop, hide | 2.2.2 |
| link purpose, link text, click here | link purpose | 2.4.4, 2.4.9 |
| page title, document title | page titled | 2.4.2 |
| authentication, login, password | accessible authentication | 3.3.8 |
| cognitive, memory, learning disability | cognitive | 3.3.7, 3.3.8 |

### Step 3: Execute Search Strategy

**Tiered Search Approach:**

1. **Tier 1**: If query matches ref_id pattern -> direct lookup
2. **Tier 2**: If query matches level pattern -> filter by level
3. **Tier 3**: Extract keywords from natural language using the mapping table above, then search title and description
4. **Tier 4 (Fallback)**: If no results, broaden search to related terms or search guideline-level content

## jq Query Patterns

All output should use **ANSI color code 178 (yellow)** to match the a11y-tips statusline.

```bash
# Exact ref_id lookup - YELLOW OUTPUT
jq -r '[.[].guidelines[].success_criteria[] | select(.ref_id == "X.X.X")] | .[] | "\u001b[1m\u001b[38;5;178mWCAG \(.ref_id) (\(.level)): \(.title)\u001b[0m\n\u001b[38;5;178m\(.description)\u001b[0m\n\u001b[38;5;178mURL: \(.url)\u001b[0m\n"' ~/.claude/wcag-search.json

# Level filter - YELLOW OUTPUT
jq -r '[.[].guidelines[].success_criteria[] | select(.level == "AA")] | .[] | "\u001b[38;5;178mWCAG \(.ref_id): \(.title)\u001b[0m"' ~/.claude/wcag-search.json

# Single keyword search - YELLOW OUTPUT
jq -r '[.[].guidelines[].success_criteria[] | select((.title | ascii_downcase | contains("KEYWORD")) or (.description | ascii_downcase | contains("KEYWORD")))] | .[] | "\u001b[1m\u001b[38;5;178mWCAG \(.ref_id) (\(.level)): \(.title)\u001b[0m\n\u001b[38;5;178m\(.description)\u001b[0m\n\u001b[38;5;178mURL: \(.url)\u001b[0m\n"' ~/.claude/wcag-search.json

# Multi-keyword OR search (for semantic expansion) - YELLOW OUTPUT
jq -r '[.[].guidelines[].success_criteria[] | select((.title | ascii_downcase | test("keyword1|keyword2|keyword3")) or (.description | ascii_downcase | test("keyword1|keyword2|keyword3")))] | .[] | "\u001b[1m\u001b[38;5;178mWCAG \(.ref_id) (\(.level)): \(.title)\u001b[0m\n\u001b[38;5;178m\(.description)\u001b[0m\n\u001b[38;5;178mURL: \(.url)\u001b[0m\n"' ~/.claude/wcag-search.json

# Combined: level + keyword - YELLOW OUTPUT
jq -r '[.[].guidelines[].success_criteria[] | select(.level == "AA") | select((.title | ascii_downcase | contains("KEYWORD")) or (.description | ascii_downcase | contains("KEYWORD")))] | .[] | "\u001b[1m\u001b[38;5;178mWCAG \(.ref_id) (\(.level)): \(.title)\u001b[0m\n\u001b[38;5;178m\(.description)\u001b[0m\n\u001b[38;5;178mURL: \(.url)\u001b[0m\n"' ~/.claude/wcag-search.json

# Guideline-level fallback search
jq -r '[.[].guidelines[] | select((.title | ascii_downcase | contains("KEYWORD")) or (.description | ascii_downcase | contains("KEYWORD")))] | .[] | "\u001b[38;5;178mGuideline \(.ref_id): \(.title)\u001b[0m"' ~/.claude/wcag-search.json
```

ANSI codes reference:

**Reset:**
- `\u001b[0m` = reset all formatting

**Font weights:**
- `\u001b[1m` = bold
- `\u001b[2m` = dim
- `\u001b[3m` = italic
- `\u001b[4m` = underline

**Colors:**
- `\u001b[32m` = green
- `\u001b[34m` = blue
- `\u001b[36m` = cyan
- `\u001b[93m` = bright yellow
- `\u001b[97m` = bright white
- `\u001b[38;5;178m` = yellow (256-color, matches statusline)

**Combined (for this design):**
- `\u001b[1;93m` = bold bright yellow (header)
- `\u001b[1;97m` = bold bright white (result numbers)
- `\u001b[1;36m` = bold cyan (ref ID)
- `\u001b[36m` = cyan (level badge)
- `\u001b[1;38;5;178m` = bold yellow (title)
- `\u001b[2;4;34m` = dim underline blue (URL)
- `\u001b[3;32m` = italic green (plain language)
- `\u001b[2;3m` = dim italic (why it matters)

## Fallback Behavior

If the initial search returns no results:

1. **Check the mapping table** for related terms and try those keywords
2. **Broaden the search** using the multi-keyword OR pattern with related terms
3. **Search guideline-level content** if success criteria search fails
4. **Provide helpful output**:

```
No exact matches for "[original query]".

Searching related terms: [extracted keywords]...

[Yellow formatted results if any]

Related criteria you might try:
- /wcag [suggested term 1]
- /wcag [suggested term 2]
```

## Report Format (WCAG 1.4.8 Compliant + Visual Design)

Structure ALL search results following WCAG 1.4.8 Visual Presentation:
- **Line length**: Max 80 characters - wrap long descriptions
- **Alignment**: Left-aligned only (no justification)
- **Line spacing**: Blank line between sections within a result
- **Paragraph spacing**: Double blank line between numbered results

### Visual Design Spec

Apply colors and formatting to create clear visual hierarchy:

| Element | Color | Weight | ANSI Code |
|---------|-------|--------|-----------|
| Header bar + title | Bright yellow | Bold | `\u001b[1;93m` |
| Result number `[1]` | White | Bold | `\u001b[1;97m` |
| Ref ID `WCAG 2.4.7` | Cyan | Bold | `\u001b[1;36m` |
| Level badge `[Level AA]` | Cyan | Normal | `\u001b[36m` |
| Criterion title | Yellow | Bold | `\u001b[1;38;5;178m` |
| Description | Default | Normal | (reset) |
| 🔗 URL | Blue | Dim + Underline | `\u001b[2;4;34m` |
| 💡 Plain language | Green | Italic | `\u001b[3;32m` |
| 👥 Why it matters | Default | Dim + Italic | `\u001b[2;3m` |
| Separator `─────` | Default | Dim | `\u001b[2m` |

### Formatting Rules

1. **Header/separator lines**: Exactly 80 characters using box drawing chars
2. **Description text**: Wrap at ~70 chars with 4-space indent
3. **After header**: Double blank line after "Found X criteria" summary
4. **Between results**: Double blank line + separator + double blank line
5. **Within results**: Double blank line between sections (description, URL, 💡, 👥)
6. **Level format**: Use badge style `[Level AA]` instead of `(AA)`
7. **Icons**: Use 🔗 for URL, 💡 for plain language, 👥 for why it matters

### Report Structure

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WCAG 2.2 Search Results: "[query]"                    ← bold bright yellow
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Found X criteria │ Levels: A (n), AA (n), AAA (n)



[1] WCAG X.X.X [Level AA]: Title
 ↑   ↑          ↑          ↑
 │   │          │          └─ bold yellow
 │   │          └─ cyan
 │   └─ bold cyan
 └─ bold white

    Description text from WCAG, wrapped at approximately 70 characters
    to stay within 80-char limit with the 4-space indent.     ← default


    🔗 https://www.w3.org/TR/WCAG22/#...                       ← dim blue underline


    💡 Simple explanation wrapped at 70 chars if needed        ← italic green
       to maintain readable line lengths.


    👥 Who benefits and how, also wrapped appropriately.       ← dim italic


────────────────────────────────────────────────────────────────────────────────


```

## Plain Language Guidelines

For each criterion, add plain language after the URL:
- Target 6th-8th grade reading level
- Use active voice ("Add descriptions to images" not "Descriptions should be added")
- Avoid jargon - use substitutions below
- Keep to 2-3 sentences max

**Term substitutions:**

| Technical Term | Say Instead |
|----------------|-------------|
| text alternative | text description |
| assistive technology | screen readers and other tools |
| programmatically determined | detected by software automatically |
| operable | works, can be used |
| perceivable | can be seen, heard, or felt |
| conformance | meeting the requirements |
| user agent | browser |
| synchronized media | video with sound |
| cognitive load | mental effort |
| focus indicator | visible highlight showing where you are |
| viewport | screen or window |

## Complete Example

The following shows the visual design with generous spacing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WCAG 2.2 Search Results: "zoom"                              [bold bright yellow]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Found 2 criteria │ Levels: AA (2)



[1] WCAG 1.4.4 [Level AA]: Resize text

    Except for captions and images of text, text can be resized
    without assistive technology up to 200 percent without loss of
    content or functionality.


    🔗 https://www.w3.org/TR/WCAG22/#resize-text


    💡 Users must be able to zoom text to 200% using browser
       settings without content breaking or overlapping.


    👥 People with low vision need to enlarge text to read
       comfortably.


────────────────────────────────────────────────────────────────────────────────


[2] WCAG 1.4.10 [Level AA]: Reflow

    Content can be presented without loss of information or
    functionality, and without requiring scrolling in two dimensions.


    🔗 https://www.w3.org/TR/WCAG22/#reflow


    💡 At 400% zoom (320px viewport), content should reflow into
       a single column with no horizontal scrolling.


    👥 Users who zoom heavily shouldn't have to scroll left and
       right to read each line.


────────────────────────────────────────────────────────────────────────────────


Related searches: /wcag resize | /wcag reflow | /wcag text size
```
