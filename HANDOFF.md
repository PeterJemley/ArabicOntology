# Project Handoff - January 10, 2026

## Overview

- **Prebuilt SwiftData Store Flow**: Implemented a copy-on-first-run and read-only fallback mechanism so the app ships with data but allows later imports. (`ArabicOntology/App/ArabicOntologyApp.swift`)
- **Typography Scaling**: Added global scaling (+60%) and headword-specific scaling (+20%) via a centralized helper. (`ArabicOntology/App/AppFontScale.swift`, `ArabicOntology/App/ContentView.swift`)
- **Expanded Search**: Capabilities now include English gloss, form token, root, and sentence. Added a sentence-mode UI with grouping, caps, stop-words, and toggles. (`ArabicOntology/App/ContentView.swift`, `ArabicOntology/App/QueryService.swift`)
- **Navigation & UX**: Added back/forward history and a debounced detail filter with a clear button. Headword rows now show ID and dialect. (`ArabicOntology/App/ContentView.swift`)
- **Lexicographical Documentation**: Fully documented models (concepts, lemmas, roots, forms, dialects, sentences, gloss index) with data-centric comments. (`ArabicOntology/Models/*.swift`)

## Data Store & Prebuilt Workflow

- The app prefers a bundled store but copies it into `Application Support` on first run to make it writable. If copying fails, it opens the bundled store as read-only.
- **Bundled Files**: Located at `ArabicOntology/Resources/PrebuiltStore/` (`ArabicOntology.store`, `.store-wal`, `.store-shm`).
- **Resetting/Re-seeding**: Delete the files in `~/Library/Containers/com.peterjemley.ArabicOntology/Data/Library/Application Support/ArabicOntology/` and relaunch.
- **Import UI**: Enabled if the store is writable (standard path); disabled only if forced into read-only mode from the bundle.
- **Note on File Size**: The store is ~99.8 MB. Refer to `Large-File-Storage-Note.md` for guidance on Git LFS.

## Search Modes & Behavior

- **Modes**: Arabic headword, English gloss, Form Token (CODA/Token), Root, Sentence.
- **English Gloss**: Uses a gloss index first, then scans forms for matches. (`ArabicOntology/App/QueryService.swift`, `ArabicOntology/Models/GlossIndexEntry.swift`)
- **Form Token**: Checks `Form.token` and `Form.rawToken`, falling back to normalized in-memory matching.
- **Root Search**: Accepts inputs with/without spaces; uses normalized variants.
- **UX**: Result lists are text-selectable for easy copy/paste.

## Sentence Mode (Current Behavior)

- **Tokenization**: Input is split into `SentenceToken` values (preserving order, detecting language).
- **Logic**: English tokens are used by default if present; "Include Arabic tokens" toggle expands search.
- **Grouping**: Tokens are grouped by a normalized key, preserving first-appearance order.
- **Filtering**: Stop-words are filtered (English/Arabic); English tokens < 2 chars are skipped.
- **Results**: Sorted alphabetically, capped at 10 per token (`maxSentenceMatchesPerToken`). Headers show occurrences and positions.

## History & Detail Pane

- **State Persistence**: History stores `searchText`, `searchMode`, `selectedLemmaId`, `detailFilter`, `includeArabicTokens`, and `showZeroMatchTokens`.
- **Detail Filter**: Debounced (250ms), shared across lemmas, and restored via history.
- **Detail UI**: Supports text selection; headword rows include ID and dialect.

## Documentation Reference

- `Radial-Design-Concept.md`: Rationale, interaction model, wireframes, and node mapping.
- `Large-File-Storage-Note.md`: GitHub size warnings and LFS strategy.
- `Arabic-Dialect-Ontology-Design-Proposal-v4.md`: Original core proposal.

## Repo State (Relevant Commits)

- `866021e`: Prebuilt store seeding + search UX expansion + typography scaling.
- `4637d96`: LFS note + radial design concept docs.
- `0c1f3ca`: Detailed lexicographical model documentation.

## What We’ll Do Next

1. **Normalization Documentation**: Add detailed comments in `ArabicOntology/App/QueryService.swift`, `ArabicOntology/Models/ArabicNormalizer.swift`, and `ArabicOntology/Models/EnglishGlossNormalizer.swift`.
2. **Sentence Search Tuning**: Iterate on precision vs. breadth, ordering, stop-word tuning, and per-token caps based on real-world examples.
3. **LFS Decision**: Decide whether to move bundled store files to Git LFS once the data format is finalized.
