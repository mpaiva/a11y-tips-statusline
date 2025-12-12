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
- `\u001b[1m` = bold
- `\u001b[38;5;178m` = yellow (color 178)
- `\u001b[0m` = reset

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

## Output Format

For each matching criterion, display in yellow (color 178):
- **Ref ID** and **Level** (e.g., "WCAG 1.4.3 (AA)") - bold yellow
- **Title** - bold yellow (same line as ref/level)
- **Description** (include special_cases if present) - yellow
- **URL** to the official WCAG specification - yellow

If no results found after fallback, output in plain text with suggestions.
