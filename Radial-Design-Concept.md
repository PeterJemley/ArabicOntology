# Radial Design Concept

## Why this matters
The radial interaction model is the primary UI concept after dialects and
languages. It is intended to make relationships between lemmas, forms, and
dialectal variants feel immediate, spatial, and discoverable.

## Purpose
- Provide a non-hierarchical view of lexical relationships.
- Make dialectal variation visible at a glance.
- Support fast navigation across related lemmas without a long list drill-down.

## Core concept
A selected word (or lemma) sits at the center. Related items radiate outward
in clusters that represent dialects, correspondences, forms, and concepts.

Example interpretation:
- Center: Selected lemma (headword).
- Inner ring: Dialect clusters (Lebanese, Syrian, Iraqi, etc).
- Outer ring(s): Dialect-specific forms and glosses.
- Connectors: Links from dialect clusters to each form.

## Interaction model
- Select a lemma in the list or search results.
- Radial view appears as a focused overlay or a dedicated panel.
- Hover or click nodes to reveal glosses, examples, and metadata.
- Click a node to pivot the center and re-render the radial graph.

## Information density
The radial view is not a full data dump. It should prioritize:
- Dialect coverage for the selected lemma.
- Most relevant forms per dialect.
- High-confidence correspondences.

## Visual language
- Non-hierarchical layout to avoid a "tree" feel.
- Consistent ring meanings (dialects on the same ring, forms on another).
- Color encodes dialect and remains stable across the app.
- Node size can reflect frequency or confidence where available.

## Accessibility and usability
- Keyboard selection should mirror mouse interactions.
- Provide text-based fallback (list view) for large datasets.
- Ensure clear focus/selection states.

## Wireframe ideas (text-only)
Radial overlay on top of detail pane:
```
         [Form]   [Form]
            \       /
             [Dial]
                |
[Form] -- [Lemma] -- [Dial] -- [Form]
                |
             [Dial]
            /     \
        [Form]   [Form]
```

Split view panel (detail on right, radial on left):
```
| Radial View | Lemma Details |
|   (nodes)   |   (lists)     |
```

## Token-to-node mapping
Input token (from search or selection) maps to:
- Center node: the selected lemma.
- Dialect nodes: one per dialect where forms exist.
- Form nodes: the forms for each dialect (token + optional gloss).
- Correspondence nodes: linked lemmas in other dialects.
- Concept nodes: concept synsets (optional ring or side cluster).

Rules of thumb:
- Cap forms per dialect (for example, top 5 by frequency or confidence).
- If a form has a gloss, show gloss on hover or secondary label.
- If no forms are available, show the dialect node in a disabled style.

## Example data walkthrough
Selected lemma: "كَتَبَ"
- Dialects present: Lebanese, Syrian
- Lebanese forms: "بيكتب" (gloss: "he writes"), "كتابة" (gloss: "writing")
- Syrian forms: "عم يكتب" (gloss: "is writing")

Radial result:
- Center: "كَتَبَ"
- Ring 1: Lebanese, Syrian
- Ring 2: forms attached to each dialect node
- Hover: show gloss and metadata (POS, root, lemma ID)

## Implementation outline (later)
- Build a view model with grouped nodes per dialect.
- Set a cap on nodes per ring for performance.
- Use a deterministic layout for stable positioning.
- Animate transitions on pivot to keep context.

## Non-goals
- This is not a full network visualization tool.
- It does not replace global search, but it can serve as a primary exploration
  view for a selected lemma. Lists remain as a fallback for bulk scanning and
  accessibility.

## Next steps
- Validate the concept with real data.
- Define the minimal node set per dialect.
- Decide whether it appears as an overlay or a split view panel.
