# Arabic Dialect Ontology
## Design Proposal v4

## Document Purpose

This document captures the design decisions for an Arabic dialect ontology supporting localization and translation work. It records findings from empirical examination of the seven dialect corpora (Baladi, Nabra, Curras, Lisan-Iraqi, Lisan-Libyan, Lisan-Sudanese, Lisan-Yemeni), the Qabas lexicon, and the Arabic Ontology concepts. It then presents creative principles derived from those findings and the resulting structural design.

---

## Part I: Foundation

### 1.1 Core Principles

**The translator is an author.** The source text is a creative constraint, not a script to decode. The target text is a new work that must achieve equivalent effect in a different cultural context.

**Resources serve the author.** Corpora, glossaries, ontologies, and tools are consultable—they inform decisions but don't make them.

**MSA is a dialect.** I have classified Modern Standard Arabic as one dialect among equals (the formal/prestige variety), not as the base from which other dialects derive. In this radial design, all varieties connect to concepts and roots as equal spokes—none is the "standard" from which others derive.

**Concept and Root are independent dimensions.** Concept captures meaning (semantic). Root captures derivation (morphological). Concept and root are independent dimensions. A query can enter through either.

### 1.2 Open-World and Closed-World Assumptions

These terms describe what we assume about missing data. Open-world: absence of information means "not yet recorded," not "impossible." Closed-world: presence is definitive.

### 1.3 Two Modes of Translation Work

**Mode A: Functional Text** — UI elements, system messages, standardized strings.
- Goal: Clarity, consistency, instant recognition
- Consistency matters—same term, same translation
- Register is typically formal or neutral
- Glossary functions as constraint
- MSA↔Dialect correspondences are useful
- Examples: "Settings," "Save," "Press X to continue," "Inventory"

**Mode B: Creative Text** — Dialogue, narrative, character voice, humor, cultural references.
- Goal: Equivalent effect in target culture
- Consistency may yield to voice and context
- Register varies by character, situation, tone
- Creativity is required; literal translation frequently fails
- Glossary functions as memory, not constraint
- May require re-authoring, not translation

---

## Part II: Resource Base

### 2.1 Dialect Corpora

Total: ~92,000 unique lemmas across 7 dialect corpora, with ~1.27 million tokens in ~56,000 example sentences.

All corpora are equally legitimate sources. Dialect choice is a team decision based on target market, character voice, client requirements, and collaborative judgment.

#### Common Schema

All corpora share a common structure: each token (word occurrence) is linked to its dictionary headword (lemma) via the MSALemmaID and DALemmaID fields.

| Field | Description |
|-------|-------------|
| sentenceId, wordPosition | Locates the token within corpus sentences |
| rawToken, Token | The token as written and normalized |
| MSALemma, MSALemmaID | The corresponding MSA lemma and its Qabas ID |
| DALemma, DALemmaID | The dialect lemma and its Qabas ID |
| POS, Prefixes, Stem, Suffixes | Morphological analysis |
| Person, Gender, Number | Grammatical features |
| Gloss | English rendering |

#### Schema Variations

**Nabra uses CODA instead of Token.** CODA (Conventional Orthography for Dialectal Arabic) refers to standardized spelling conventions for dialectal Arabic, which traditionally lacks written norms. This column serves the same function as Token in other corpora.

**Nabra includes subdialect.** The corpus annotates 10 Syrian subdialects, enabling finer-grained regional analysis.

### 2.2 What the Corpora Provide

1. **Natural dialect speech.** Sentences showing how lemmas appear in context, what register they signal, how they combine.
2. **Other translators' English renderings.** Glosses show how corpus annotators rendered dialect lemmas in English—a resource for comprehension, not a constraint.
3. **Morphological patterns.** How verbs conjugate, how nouns inflect, how clitics attach in each dialect.
4. **Dialect-specific vocabulary.** Iraqi ماكو (there isn't), Libyan توّاً (now), Sudanese زول (person), Lebanese هيدا (this).
5. **MSA↔Dialect correspondences.** Direct lemma mappings like هُنَا↔هون. These are useful for functional text where consistency with MSA is desired.

### 2.3 Qabas Lexicographic Database

| Measure | Value |
|---------|-------|
| Total lemmas | 58,466 |
| Lemmas with roots | 57,080 (97.6%) |
| Unique roots | 15,236 |
| MSA lemmas (فصحى حديثة) | 50,899 |
| Foreign lemmas (أجنبية) | 6,045 |
| Dialect lemmas (عامية) | 1,522 |
| SAMA mappings | 34,353 |

**Schema:** lemma_id, lemma, language, pos_cat, pos, root, augmentation, number, person, gender, voice, transitivity, uninflected

**Key features:** 97.6% of lemmas have root information. Includes morphological features. Links to SAMA morphological analyzer. The uninflected flag marks lemmas that do not inflect.

**Note — Register ≠ Dialect:** The Qabas language field indicates register (فصحى حديثة = MSA, عامية = colloquial, أجنبية = foreign), not dialect. All values map to MSA for dialect queries. Actual dialect association for forms comes from corpus provenance (which file the form was imported from).

### 2.4 Arabic Ontology (Concepts)

| Measure | Value |
|---------|-------|
| Total concepts | 13,755 |
| Well-designed (dataSourceId=200) | 9,700 |
| Concepts with English synsets | 10,939 |
| Polysemous lemmas | 11,394 |

**Schema:** conceptId, arabicSynset, englishSynset, gloss, example, dataSourceId

**Key features:** Synsets group synonymous Arabic lemmas per concept. Hierarchical structure via Relations.csv. The example field provides usage illustrations. 11,394 lemmas appear in multiple concepts (polysemy—treated as open-world).

### 2.5 Linkage Between Resources

| Link | Method | Coverage |
|------|--------|----------|
| Corpus → Qabas Lemma | MSALemmaID / DALemmaID | 98%+ |
| Qabas Lemma → Root | root column | 97.6% |
| Qabas Lemma → Concept | Text match (synset) | 76.6% |

---

## Part III: Ontology Structure

### 3.1 Entities

| Entity | Description | Source |
|--------|-------------|--------|
| Concept | A meaning unit with Arabic/English synonyms | Concepts.csv |
| Lemma | A dictionary headword in a specific variety (MSA or dialect) | Qabas-dataset.csv |
| Root | Consonantal skeleton from which lemmas derive | Qabas root column |
| Form | A surface realization of a lemma in a corpus sentence | Dialect corpora |
| Dialect | A variety of Arabic, including MSA as one among equals | Qabas language + corpus |
| Sentence | A usage context containing one or more forms | *_RowText_sentences.csv |

#### Entity Attributes

- **Concept:** conceptId, arabicSynset, englishSynset, gloss, example, dataSourceId, parent (hierarchy)
- **Lemma:** lemmaId, lemma, language, posCategory, pos, root, augmentation, number, person, gender, voice, transitivity, uninflected
- **Root:** root (the consonantal skeleton, e.g., "ك ت ب")
- **Form:** token, rawToken, gloss, pos, prefixes, stem, suffixes, person, gender, number, wordPosition, subdialect (Nabra only)
- **Dialect:** code, name, region, corpusSource
- **Sentence:** sentenceId, text, dialect

### 3.2 Relationships

| Relationship | Direction | Cardinality | Source |
|--------------|-----------|-------------|--------|
| expresses | Lemma ↔ Concept | many-to-many | Text matching |
| derives-from | Lemma → Root | many-to-one | Qabas root column |
| belongs-to | Lemma → Dialect | many-to-one | Qabas language field |
| realizes | Form → Lemma | many-to-one | DALemmaID |
| msa-equivalent | Form → Lemma | many-to-one | MSALemmaID |
| attested-in | Form → Sentence | many-to-one | sentenceId |
| spoken-in | Form → Dialect | many-to-one | Corpus provenance |
| subtype-of | Concept → Concept | many-to-one | Relations.csv |
| corresponds-to | Lemma ↔ Lemma | many-to-many | Extracted from Forms |

#### The corresponds-to Relationship

This relationship is central to the radial design. It captures translational equivalence across dialects without privileging any variety:

- **Symmetric:** if lemma A corresponds to lemma B, then B corresponds to A
- **Cross-dialect:** connects lemmas from different varieties (including MSA)
- **Distinct from synonymy:** correspondence is attestational (annotators marked these as equivalents), not purely semantic
- **Built from corpus data:** extracted from (MSALemmaID, DALemmaID) pairs
- **Transitive deduction:** if Lebanese L₁ → MSA M and Iraqi L₂ → MSA M, then L₁ ↔ L₂

**Example:** The lemmas هُنَا (MSA), هون (Lebanese), هون (Syrian), هون (Palestinian) all correspond to each other. None is the "base" form.

### 3.3 Dual Radial Structure

The ontology supports two independent entry points:

**Entry Point 1: Concept-Centered.** Start with a meaning, find all lemmas across dialects that express it.

**Entry Point 2: Root-Centered.** Start with a consonantal root, find all derived lemmas and their meanings.

Neither dimension is primary. The user chooses their entry point based on their question.

### 3.4 Complete Data Flow

The full traversal from concept to attestation:

```
CONCEPT (meaning) → via expresses → LEMMA (dictionary headword)
LEMMA → via derives-from → ROOT (morphological family)
LEMMA → via belongs-to → DIALECT (variety)
LEMMA → via corresponds-to → LEMMA (cross-dialect equivalents)
LEMMA → via realizes (inverse) → FORM (surface realization in corpus)
FORM → via attested-in → SENTENCE (usage context)
```

---

## Part IV: Corpus Value by Use Case

### 4.1 For Concept-Based Queries (Creative Translation)

- "What lemmas express ANGER in Iraqi?" → Concept → Lemmas filtered by dialect
- "How does this lemma inflect?" → Lemma → Forms → morphological annotations
- "Show me this lemma in context" → Lemma → Forms → Sentences

### 4.2 For Root-Based Queries (Morphological Exploration)

- "What lemmas derive from this root?" → Root → Lemmas (15,236 unique roots)
- "Show me the semantic field of root ك-ت-ب" → Root → Lemmas → Concepts

### 4.3 For Cross-Dialect Queries

- "What's the Lebanese equivalent of this MSA lemma?" → Lemma → corresponds-to → filter by dialect
- "Show me all dialect variants of this lemma" → Lemma → corresponds-to → all

---

## Part V: Handling Special Cases

### 5.1 Polysemy (One Lemma, Multiple Meanings)

The ontology treats polysemy as open-world. If a lemma appears in multiple concept synsets, all links are valid. The lemma عَطَفَ appears in 23 concepts (bend, show compassion, incline toward...). This is the lemma's semantic range, not a data error. Context resolves which meaning is active.

### 5.2 Synonymy (Multiple Lemmas, Same Meaning)

Handled via concept synsets. The concept MOSQUE has synset مَسْجِدٌ | جَامِعٌ — both lemmas express the same concept.

### 5.3 Missing Roots

Some dialect lemmas lack root information: عَمْ (still), وِيْن (where), بِد (want). These lemmas are valid; root is open-world and can be added when known.

### 5.4 Dialect-Specific Concepts

Some concepts may exist in one dialect but not others. The concept exists; it simply has lemmas only in certain dialects. Querying "how do I express X in dialect Y" may return empty—this is informative, not an error.

---

## Part VI: Integration with Translation Workflow

### 6.1 Workflow Summary

1. **Survey the Source:** Read/play. Understand tone, characters, problems.
2. **Establish Voice and Dialect:** Decide which dialect(s), register range, strategies.
3. **Identify Functional vs. Creative:** Tag segments. This determines approach.
4. **Build Initial Terminology:** For functional text, establish UI/system terms. Glossary = constraint.
5. **Translate Creatively:** For creative text, prioritize effect. Glossary = reference.
6. **Record Decisions:** Capture terms and notable creative solutions.
7. **Review and Revise:** Check consistency (functional) and voice (creative).

---

## Part VII: Data Files Summary

| File | Contents | Size | Entities |
|------|----------|------|----------|
| Qabas-dataset.csv | 58K lemmas with roots | ~5MB | Lemma + Root |
| Concepts.csv | 14K concept definitions | ~2MB | Concept |
| Relations.csv | Concept hierarchy | ~500KB | Concept→Concept |
| Baladi-dataset.csv | Lebanese forms | ~2MB | Form |
| Nabra-dataset.csv | Syrian forms | ~12MB | Form |
| Curras-dataset.csv | Palestinian forms | ~11MB | Form |
| Lisan-Iraqi-dataset.csv | Iraqi forms | ~9MB | Form |
| Lisan-Libyan-dataset.csv | Libyan forms | ~10MB | Form |
| Lisan-Sudanese-dataset.csv | Sudanese forms | ~10MB | Form |
| Lisan-Yemeni-dataset.csv | Yemeni forms | ~125MB | Form |
| *_RowText_sentences.csv | Sentence contexts | varies | Sentence |

---

## Part VIII: Design Rationale

### 8.1 Why Concept-Centered (Not MSA-Centered)

Traditional Arabic NLP treats MSA as the base form, implying dialects are "deviations." A concept-centered structure treats all varieties as equal expressions of meaning, supports direct dialect↔dialect queries, and matches the translator-as-author model.

### 8.2 Why Explicit Lemma↔Lemma Correspondence

The corresponds-to relationship captures cross-dialect equivalence directly, without routing through MSA. This aligns with treating MSA as one dialect among equals. The relationship is symmetric and supports queries like "what's the Iraqi equivalent of this Lebanese lemma?" without privileging any variety.

### 8.3 Why Root and Concept Are Independent Dimensions

Root is fundamental to Arabic morphology but independent of meaning. One root yields many lemmas with different concepts (ك-ت-ب → كَتَبَ WRITE, كِتَاب BOOK, كَاتِب WRITER). Making root and concept independent dimensions enables both semantic and morphological entry points.

### 8.4 Why Open-World for Polysemy

Forcing disambiguation would require arbitrary decisions about "primary" sense. Open-world polysemy records the full semantic range and defers disambiguation to usage context.

---

## Part IX: Next Steps

### 9.1 Immediate (Data Integration)

- Implement SwiftData models for macOS/iOS
- Build import service for all corpora
- Build Lemma↔Concept links via text matching
- Build Lemma↔Lemma correspondence from corpus MSA/DA pairs
- Verify coverage and document gaps

### 9.2 Medium-Term (Tool Development)

- Radial visualization interface
- Translation workflow integration
- Glossary management system

### 9.3 Long-Term (Enrichment)

- Add roots for dialect lemmas currently missing them
- Extend concept coverage from dialect-specific vocabulary
- Add register annotations

---

## Part X: Citation and Licensing

### 10.1 Required Citations

**Qabas:** Jarrar & Hammouda (2024), LREC-COLING; Jarrar & Amayreh (2019), NLDB.

**Arabic Ontology:** Jarrar (2021), Applied Ontology Journal.

**Curras:** El Haff, Jarrar, Hammouda & Zaraket (2022), LREC; Jarrar, Habash, Alrimawi, Akra & Zalmout (2017), Language Resources and Evaluation.

**Other Corpora:** See Birzeit SinaLab documentation for individual corpus citations.

### 10.2 Licensing

All data is copyright Birzeit University. Usage must comply with individual dataset licenses. The ontology design in this document is original work building upon these resources.

---

*Document created: December 27, 2025 | Updated: December 30, 2025 (v4)*
