# Arabic Dialect Ontology — Prototype

A SwiftData-based ontology for Arabic dialects supporting localization and translation work.

## Quick Start

### 1. Create Xcode Project

**Requirements:** macOS 14 (Sonoma) or later, Xcode 15+, Swift 5.9+

1. File → New → Project
2. Select **macOS → App**
3. Product Name: `ArabicOntology`
4. Interface: SwiftUI
5. Language: Swift
6. Storage: None (we configure SwiftData manually)

### 2. Add Source Files

Drag the three folders into Xcode's Project Navigator:

1. Drag `Models/`, `Importer/`, `App/` into the project
2. In the dialog: select **Create groups**
3. Ensure **Add to targets** has `ArabicOntology` checked

All 11 Swift files should now appear in your project with target membership set to the app.

### 3. Prepare Data Folder

Collect CSV files in one folder:

```
data/
├── Qabas-dataset.csv             # Required — lemmas and roots
├── Concepts.csv                  # Required — concept definitions
├── Relations.csv                 # Required — concept hierarchy
├── Baladi-dataset.csv            # Optional — Lebanese forms
├── Baladi_RowText_sentences.csv  # Optional — Lebanese sentences
├── Nabra-dataset.csv             # Optional — Syrian forms
├── Nabra_RowText_sentences.csv   # Optional — Syrian sentences
├── Curras-dataset.csv            # Optional — Palestinian forms
├── Curras_RowText_sentences.csv  # Optional — Palestinian sentences
├── Lisan-Iraqi-dataset.csv       # Optional — Iraqi forms
├── Lisan-Iraqi_RowText_sentences.csv
├── Lisan-Libyan-dataset.csv      # Optional — Libyan forms
├── Lisan-Libyan_RowText_sentences.csv
├── Lisan-Sudanese-dataset.csv    # Optional — Sudanese forms
├── Lisan-Sudanese_RowText_sentences.csv
├── Lisan-Yemeni-dataset.csv      # Optional — Yemeni forms
└── Lisan-Yemeni_RowText_sentences.csv
```

**Note:** The three required files give you the lexicon (58K lemmas, 16K roots, 14K concepts). Missing corpus files are skipped with warnings — but without them you won't have Forms, Sentences, or dialect correspondences. For comparing translations, include all corpus files.

### 4. Run App and Import

1. Build and run
2. Click "Import Data"
3. Select your data folder
4. Wait for import (~10-15 min for full dataset)
5. Search and explore

**Database location:** `~/Library/Application Support/ArabicOntology/ArabicOntology.store`

To reset and re-import, quit the app and delete this file.

## Project Structure

```
ArabicOntology/
├── Models/                 # SwiftData entities
│   ├── Concept.swift
│   ├── Root.swift
│   ├── Dialect.swift
│   ├── Lemma.swift
│   ├── Form.swift
│   ├── Sentence.swift
│   └── ArabicNormalizer.swift
├── Importer/
│   ├── ImportService.swift # CSV → SwiftData
│   └── CSVParser.swift
└── App/
    ├── ArabicOntologyApp.swift
    ├── ContentView.swift
    └── QueryService.swift
```

## Entity Summary

| Entity | Count | Description |
|--------|------:|-------------|
| Concept | ~14,000 | Meaning units with Arabic/English synsets |
| Root | ~16,000 | Consonantal skeletons (ك ت ب) |
| Lemma | ~58,000 | Dictionary headwords |
| Form | ~1,270,000 | Attested tokens in corpora |
| Sentence | ~56,000 | Usage contexts |
| Dialect | 8 | MSA + 7 regional varieties |

## Design Principles

1. **MSA is a dialect** — treated as one variety among equals
2. **Concept and Root are independent dimensions** — query through either
3. **Correspondence is symmetric** — no dialect is privileged
4. **Open-world polysemy** — one lemma can express multiple concepts
5. **Register ≠ Dialect** — Qabas `language` field indicates register (MSA/colloquial/foreign), not dialect; all map to MSA for queries; actual dialect comes from corpus provenance

## Citations

See the Design Proposal document for full citation requirements for:
- Qabas lexicon (Birzeit University)
- Arabic Ontology (Birzeit University)
- Dialect corpora (Birzeit SinaLab)
