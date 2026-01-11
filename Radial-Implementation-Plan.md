# Radial View Implementation Plan

## Objective
Implement a "Lemma-centric" radial visualization that displays a selected lemma, its dialectal variants (correspondences), and their attested forms.

## Core Concept
- **Center**: The selected Lemma (Headword).
- **Ring 1 (Dialects/Correspondences)**: Nodes representing dialectal variants (lemmas in other dialects) linked to the center.
- **Ring 2 (Forms)**: Nodes representing specific attested forms radiating from their respective dialect lemmas.

## Data Traversal Strategy
1.  **Input**: A selected `Lemma` object.
2.  **Dialect Grouping**:
    - Identify the dialect of the center lemma.
    - Traverse `lemma.correspondences` to find related lemmas in other dialects.
    - Group these lemmas by their `Dialect` (e.g., Syrian, Lebanese, Iraqi).
3.  **Form Retrieval**:
    - For each lemma (both the center and its correspondences), access the `forms` relationship.
    - **Note**: We will *not* limit the number of forms per dialect initially. We want to observe the full density of data before applying any arbitrary caps.

## Visualization Logic (Canvas)
- **Layout**: Polar coordinate system.
    - Center: (0, 0)
    - Ring 1 Radius: Fixed distance for Dialect/Lemma nodes.
    - Ring 2 Radius: Fixed distance (larger) for Form nodes.
- **Distribution**:
    - Distribute Dialect clusters evenly around the circle (0 to 360 degrees).
    - Within each Dialect sector, distribute its Form nodes.
- **Visual Elements**:
    - **Lines**: 
        - Center to Dialect Lemma.
        - Dialect Lemma to Form.
    - **Nodes**:
        - Center: Large, distinctive color.
        - Dialect Lemma: Medium, colored by region/dialect.
        - Form: Small, lighter color.
    - **Labels**:
        - Text placed near nodes (handling rotation/orientation to remain readable).

## Components
1.  **`RadialViewModel`**:
    - Input: `Lemma`
    - Logic: Flattens the graph into a set of Nodes and Edges for the View to render.
    - Output: `[Node]`, `[Edge]` structs with coordinates.
2.  **`RadialView`**:
    - SwiftUI View using `Canvas`.
    - Draws the graph based on the ViewModel's data.
    - Interactive scaling/panning (ZoomableScrollView) might be needed if the graph is huge.

## Integration
- Add a "Radial View" toggle or tab in `LemmaDetailView`.
- Ensure it updates when `selectedLemma` changes.

## Next Steps
1.  Create `ArabicOntology/App/RadialView.swift` containing the ViewModel and View.
2.  Integrate into `LemmaDetailView`.
3.  Run and test with a lemma that has correspondences (e.g., "كتب").
