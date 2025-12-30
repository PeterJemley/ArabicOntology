import Foundation
import SwiftData

struct CorpusDescriptor: Identifiable, Hashable {
    let id: String
    let displayName: String
    let datasetFile: String
    let sentenceFile: String?
    let dialectCode: String
    
    static let all: [CorpusDescriptor] = [
        CorpusDescriptor(
            id: "baladi",
            displayName: "Baladi - Lebanese Dialect Corpus",
            datasetFile: "Baladi-dataset.csv",
            sentenceFile: "Baladi_RowText_sentences.csv",
            dialectCode: "lebanese"
        ),
        CorpusDescriptor(
            id: "nabra",
            displayName: "Nabra - Syrian Dialect Corpus",
            datasetFile: "Nabra-dataset.csv",
            sentenceFile: "Nabra_RowText_sentences.csv",
            dialectCode: "syrian"
        ),
        CorpusDescriptor(
            id: "curras",
            displayName: "Curras - Palestinian Dialect Corpus",
            datasetFile: "Curras-dataset.csv",
            sentenceFile: "Curras_RowText_sentences.csv",
            dialectCode: "palestinian"
        ),
        CorpusDescriptor(
            id: "lisan_iraqi",
            displayName: "Lisan - Iraqi Dialect Corpus",
            datasetFile: "Lisan-Iraqi-dataset.csv",
            sentenceFile: "Lisan-Iraqi_RowText_sentences.csv",
            dialectCode: "iraqi"
        ),
        CorpusDescriptor(
            id: "lisan_libyan",
            displayName: "Lisan - Libyan Dialect Corpus",
            datasetFile: "Lisan-Libyan-dataset.csv",
            sentenceFile: "Lisan-Libyan_RowText_sentences.csv",
            dialectCode: "libyan"
        ),
        CorpusDescriptor(
            id: "lisan_sudanese",
            displayName: "Lisan - Sudanese Dialect Corpus",
            datasetFile: "Lisan-Sudanese-dataset.csv",
            sentenceFile: "Lisan-Sudanese_RowText_sentences.csv",
            dialectCode: "sudanese"
        ),
        CorpusDescriptor(
            id: "lisan_yemeni",
            displayName: "Lisan - Yemeni Dialect Corpus",
            datasetFile: "Lisan-Yemeni-dataset.csv",
            sentenceFile: "Lisan-Yemeni_RowText_sentences.csv",
            dialectCode: "yemeni"
        )
    ]
}

/// Service for importing CSV data into SwiftData store
@MainActor
final class ImportService {
    
    private let modelContext: ModelContext
    private let dataDirectory: URL
    private let selectedCorpora: [CorpusDescriptor]
    
    // Progress reporting
    var progressCallback: ((String) -> Void)?
    
    // Caches for relationship linking
    private var dialectCache: [String: Dialect] = [:]
    private var rootCache: [String: Root] = [:]
    private var lemmaCache: [String: Lemma] = [:]
    private var conceptCache: [String: Concept] = [:]
    private var sentenceCache: [String: Sentence] = [:]
    private var formKeyCache: Set<String> = []
    private var glossKeyCache: Set<String> = []
    
    init(modelContext: ModelContext, dataDirectory: URL, selectedCorpora: [CorpusDescriptor]) {
        self.modelContext = modelContext
        self.dataDirectory = dataDirectory
        self.selectedCorpora = selectedCorpora
    }
    
    private func report(_ message: String) {
        print(message)
        progressCallback?(message)
    }
    
    // MARK: - Main Import
    
    func importAll() async throws {
        report("Starting import...")
        report("Loading existing data...")
        try preloadCaches()
        
        // Phase 1: Independent entities
        report("Phase 1: Importing dialects, concepts, sentences...")
        try await importDialects()
        try await importConcepts()
        try await importSentences()
        
        // Phase 2: Qabas (Roots + Lemmas)
        report("Phase 2: Importing Qabas lemmas and roots...")
        try await importQabas()
        
        // Phase 3: Relationships
        report("Phase 3: Building relationships...")
        try await importConceptHierarchy()
        try await buildLemmaConceptLinks()
        
        // Phase 4: Corpus Forms
        if selectedCorpora.isEmpty {
            report("Phase 4: Skipping corpus forms (none selected)")
        } else {
            report("Phase 4: Importing corpus forms (this takes a while)...")
            try await importCorpora()
        }
        
        // Phase 5: Correspondence
        if selectedCorpora.isEmpty {
            report("Phase 5: Skipping correspondences (no corpora selected)")
        } else {
            report("Phase 5: Building lemma correspondences...")
            try await buildCorrespondences()
        }
        
        // Save
        report("Saving database...")
        try modelContext.save()
        report("Import complete!")
    }

    private func preloadCaches() throws {
        dialectCache.removeAll()
        rootCache.removeAll()
        lemmaCache.removeAll()
        conceptCache.removeAll()
        sentenceCache.removeAll()
        formKeyCache.removeAll()
        glossKeyCache.removeAll()
        
        for dialect in try modelContext.fetch(FetchDescriptor<Dialect>()) {
            dialectCache[dialect.code] = dialect
        }
        for root in try modelContext.fetch(FetchDescriptor<Root>()) {
            rootCache[root.root] = root
        }
        for lemma in try modelContext.fetch(FetchDescriptor<Lemma>()) {
            lemmaCache[lemma.lemmaId] = lemma
        }
        for concept in try modelContext.fetch(FetchDescriptor<Concept>()) {
            conceptCache[concept.conceptId] = concept
        }
        
        if !selectedCorpora.isEmpty {
            for sentence in try modelContext.fetch(FetchDescriptor<Sentence>()) {
                sentenceCache[sentence.sentenceId] = sentence
            }
            
            let formCount = try modelContext.fetchCount(FetchDescriptor<Form>())
            if formCount > 0 {
                for form in try modelContext.fetch(FetchDescriptor<Form>()) {
                    formKeyCache.insert(form.formKey)
                }
            }
            
            let glossCount = try modelContext.fetchCount(FetchDescriptor<GlossIndexEntry>())
            if glossCount > 0 {
                for entry in try modelContext.fetch(FetchDescriptor<GlossIndexEntry>()) {
                    glossKeyCache.insert(entry.key)
                }
            }
        }
    }
    
    // MARK: - Phase 1: Independent Entities
    
    private func importDialects() async throws {
        print("Importing dialects...")
        
        for def in Dialect.predefined {
            if dialectCache[def.code] != nil {
                continue
            }
            let dialect = Dialect(
                code: def.code,
                name: def.name,
                region: def.region,
                corpusSource: def.corpusSource
            )
            modelContext.insert(dialect)
            dialectCache[def.code] = dialect
        }
        
        // Map Qabas language values to dialects
        // Note: Qabas "language" is actually register (MSA vs colloquial vs foreign),
        // not dialect. We map all to MSA here by design. The actual dialect assignment
        // for Forms comes from corpus provenance (which file it was imported from).
        if let msa = dialectCache["msa"] {
            dialectCache["فصحى حديثة"] = msa
            dialectCache["عامية"] = msa       // Colloquial register → MSA
            dialectCache["أجنبية"] = msa      // Foreign loanwords → MSA
        }
        
        print("  Imported \(Dialect.predefined.count) dialects")
    }
    
    private func importConcepts() async throws {
        print("Importing concepts...")
        
        let url = dataDirectory.appendingPathComponent("Concepts.csv")
        let rows = try CSVParser.parse(contentsOf: url)
        
        try CSVParser.validate(rows, requiredColumns: [
            "conceptId", "arabicSynset", "dataSourceId"
        ], file: "Concepts.csv")
        
        for row in rows {
            let conceptId = CSVParser.requiredString(row, "conceptId")
            if conceptCache[conceptId] != nil {
                continue
            }
            let concept = Concept(
                conceptId: conceptId,
                arabicSynset: CSVParser.requiredString(row, "arabicSynset"),
                englishSynset: CSVParser.string(row, "englishSynset"),
                gloss: CSVParser.string(row, "gloss"),
                example: CSVParser.string(row, "example"),
                dataSourceId: CSVParser.int(row, "dataSourceId") ?? 0
            )
            modelContext.insert(concept)
            conceptCache[concept.conceptId] = concept
        }
        
        print("  Imported \(rows.count) concepts")
    }
    
    private func importSentences() async throws {
        print("Importing sentences...")
        
        let sentenceFiles = selectedCorpora.compactMap { corpus -> (String, String)? in
            guard let sentenceFile = corpus.sentenceFile else { return nil }
            return (sentenceFile, corpus.dialectCode)
        }
        
        guard !sentenceFiles.isEmpty else {
            print("  No sentence corpora selected, skipping")
            return
        }
        
        var totalCount = 0
        
        for (filename, dialectCode) in sentenceFiles {
            let url = dataDirectory.appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("  Warning: \(filename) not found, skipping")
                continue
            }
            
            let rows = try CSVParser.parse(contentsOf: url)
            
            // Skip empty/header-only files
            guard !rows.isEmpty else {
                print("  Warning: \(filename) has no data rows, skipping")
                continue
            }
            
            let dialect = dialectCache[dialectCode]
            
            var insertedCount = 0
            
            for row in rows {
                let sentenceId = CSVParser.requiredString(row, "Sentence_id")
                let text = CSVParser.requiredString(row, "sentence")
                
                guard !sentenceId.isEmpty, !text.isEmpty else { continue }
                
                // Create composite key: dialect + sentenceId
                let key = "\(dialectCode):\(sentenceId)"
                if sentenceCache[key] != nil {
                    continue
                }
                
                let sentence = Sentence(sentenceId: key, text: text)
                sentence.dialect = dialect
                modelContext.insert(sentence)
                sentenceCache[key] = sentence
                insertedCount += 1
            }
            
            totalCount += insertedCount
            print("  \(filename): \(insertedCount) sentences")
        }
        
        print("  Total: \(totalCount) sentences")
    }
    
    // MARK: - Phase 2: Qabas
    
    private func importQabas() async throws {
        print("Importing Qabas lemmas and roots...")
        
        let url = dataDirectory.appendingPathComponent("Qabas-dataset.csv")
        let rows = try CSVParser.parse(contentsOf: url)
        
        try CSVParser.validate(rows, requiredColumns: [
            "lemma_id", "lemma", "language", "pos_cat", "pos"
        ], file: "Qabas-dataset.csv")
        
        var rootCount = 0
        
        for row in rows {
            let lemmaId = CSVParser.requiredString(row, "lemma_id")
            if lemmaCache[lemmaId] != nil {
                continue
            }
            
            // Extract or create Root
            let rootText = CSVParser.string(row, "root")
            var root: Root? = nil
            
            if let rootText = rootText, !rootText.isEmpty {
                if let existing = rootCache[rootText] {
                    root = existing
                } else {
                    root = Root(root: rootText)
                    modelContext.insert(root!)
                    rootCache[rootText] = root
                    rootCount += 1
                }
            }
            
            // Create Lemma
            let lemma = Lemma(
                lemmaId: lemmaId,
                lemma: CSVParser.requiredString(row, "lemma"),
                language: CSVParser.requiredString(row, "language"),
                posCategory: CSVParser.requiredString(row, "pos_cat"),
                pos: CSVParser.requiredString(row, "pos"),
                augmentation: CSVParser.string(row, "augmentation"),
                number: CSVParser.string(row, "number"),
                person: CSVParser.string(row, "person"),
                gender: CSVParser.string(row, "gender"),
                voice: CSVParser.string(row, "voice"),
                transitivity: CSVParser.string(row, "transitivity"),
                uninflected: CSVParser.bool(row, "uninflected")
            )
            
            lemma.rootRef = root
            lemma.dialect = dialectCache[lemma.language]
            
            modelContext.insert(lemma)
            lemmaCache[lemma.lemmaId] = lemma
        }
        
        print("  Imported \(rows.count) lemmas")
        print("  Imported \(rootCount) unique roots")
    }
    
    // MARK: - Phase 3: Relationships
    
    private func importConceptHierarchy() async throws {
        print("Building concept hierarchy...")
        
        let url = dataDirectory.appendingPathComponent("Relations.csv")
        let rows = try CSVParser.parse(contentsOf: url)
        
        try CSVParser.validate(rows, requiredColumns: [
            "concept_id", "subTypeOfID"
        ], file: "Relations.csv")
        
        var linkCount = 0
        
        for row in rows {
            let conceptId = CSVParser.requiredString(row, "concept_id")
            let parentId = CSVParser.string(row, "subTypeOfID")
            
            guard let parentId = parentId, parentId != "0" else { continue }
            guard let concept = conceptCache[conceptId] else { continue }
            guard let parent = conceptCache[parentId] else { continue }
            
            concept.parent = parent
            linkCount += 1
        }
        
        print("  Built \(linkCount) parent-child links")
    }
    
    private func buildLemmaConceptLinks() async throws {
        print("Building lemma-concept links via text matching...")
        
        // Build normalized lemma lookup
        var normalizedLemmas: [String: [Lemma]] = [:]
        for lemma in lemmaCache.values {
            let normalized = ArabicNormalizer.normalize(lemma.lemma)
            normalizedLemmas[normalized, default: []].append(lemma)
        }
        
        var linkCount = 0
        
        for concept in conceptCache.values {
            for term in concept.arabicTerms {
                let normalized = ArabicNormalizer.normalize(term)
                if let lemmas = normalizedLemmas[normalized] {
                    for lemma in lemmas {
                        if !lemma.concepts.contains(where: { $0.conceptId == concept.conceptId }) {
                            lemma.concepts.append(concept)
                            linkCount += 1
                        }
                    }
                }
            }
        }
        
        print("  Built \(linkCount) lemma-concept links")
    }
    
    // MARK: - Phase 4: Corpus Forms
    
    private func importCorpora() async throws {
        for corpus in selectedCorpora {
            try await importCorpus(
                filename: corpus.datasetFile,
                dialectCode: corpus.dialectCode
            )
        }
    }
    
    private func importCorpus(filename: String, dialectCode: String) async throws {
        report("Importing \(filename)...")
        
        let url = dataDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("  Warning: \(filename) not found, skipping")
            return
        }
        
        let rows = try CSVParser.parse(contentsOf: url)
        let dialect = dialectCache[dialectCode]
        
        // Skip empty/header-only files for optional corpora
        guard !rows.isEmpty else {
            print("  Warning: \(filename) has no data rows, skipping")
            return
        }
        
        // Determine token column (CODA for Nabra, Token otherwise)
        let tokenKey = dialectCode == "syrian" ? "CODA" : "Token"
        
        try CSVParser.validate(rows, requiredColumns: [
            "sentenceId", "wordPosition", tokenKey, "MSALemmaID", "DALemmaID"
        ], file: filename)
        
        var formCount = 0
        var linkedCount = 0
        
        for row in rows {
            let token = CSVParser.requiredString(row, tokenKey)
            guard !token.isEmpty else { continue }
            
            let sentenceId = CSVParser.requiredString(row, "sentenceId")
            guard !sentenceId.isEmpty else { continue }
            let wordPosition = CSVParser.int(row, "wordPosition") ?? 0
            let formKey = "\(dialectCode):\(sentenceId):\(wordPosition)"
            
            if formKeyCache.contains(formKey) {
                continue
            }
            
            let form = Form(
                formKey: formKey,
                token: token,
                rawToken: CSVParser.string(row, "rawToken"),
                gloss: CSVParser.string(row, "Gloss"),
                pos: CSVParser.string(row, "POS"),
                prefixes: CSVParser.string(row, "Prefixes"),
                stem: CSVParser.string(row, "Stem"),
                suffixes: CSVParser.string(row, "Suffixes"),
                wordPosition: wordPosition,
                personFeature: CSVParser.string(row, "Person"),
                genderFeature: CSVParser.string(row, "Gender"),
                numberFeature: CSVParser.string(row, "Number"),
                subdialect: CSVParser.string(row, "subdialect")
            )
            
            form.dialect = dialect
            
            // Link to DA lemma
            if let daLemmaId = CSVParser.string(row, "DALemmaID"), daLemmaId != "0" {
                form.lemma = lemmaCache[daLemmaId]
                if form.lemma != nil { linkedCount += 1 }
            }
            
            // Link to MSA lemma
            if let msaLemmaId = CSVParser.string(row, "MSALemmaID"), msaLemmaId != "0" {
                form.msaLemma = lemmaCache[msaLemmaId]
            }
            
            // Link to sentence
            let sentenceKey = "\(dialectCode):\(sentenceId)"
            form.sentence = sentenceCache[sentenceKey]
            
            modelContext.insert(form)
            indexGloss(for: form)
            formKeyCache.insert(formKey)
            formCount += 1
        }
        
        print("  Imported \(formCount) forms (\(linkedCount) linked to lemmas)")
    }
    
    private func indexGloss(for form: Form) {
        guard let gloss = form.gloss else { return }
        
        let tokens = EnglishGlossNormalizer.tokens(from: gloss)
        guard !tokens.isEmpty else { return }
        
        let lemmas = [form.lemma, form.msaLemma].compactMap { $0 }
        guard !lemmas.isEmpty else { return }
        
        for lemma in lemmas {
            for token in tokens {
                let key = "\(token)|\(lemma.lemmaId)"
                if glossKeyCache.contains(key) {
                    continue
                }
                
                let entry = GlossIndexEntry(key: key, token: token, lemma: lemma)
                modelContext.insert(entry)
                glossKeyCache.insert(key)
            }
        }
    }
    
    // MARK: - Phase 5: Correspondences
    
    private func buildCorrespondences() async throws {
        print("Building lemma correspondences...")
        
        // Collect unique (MSA, DA) pairs from forms
        var pairs: Set<String> = []
        
        let fetchDescriptor = FetchDescriptor<Form>()
        let forms = try modelContext.fetch(fetchDescriptor)
        
        for form in forms {
            guard let msaLemma = form.msaLemma, let daLemma = form.lemma else { continue }
            guard msaLemma.lemmaId != daLemma.lemmaId else { continue }
            
            // Create canonical pair key (sorted to avoid duplicates)
            let key = [msaLemma.lemmaId, daLemma.lemmaId].sorted().joined(separator: ":")
            pairs.insert(key)
        }
        
        print("  Found \(pairs.count) unique lemma pairs")
        
        // Build symmetric correspondences
        var linkCount = 0
        
        for pair in pairs {
            let ids = pair.split(separator: ":").map(String.init)
            guard ids.count == 2,
                  let lemma1 = lemmaCache[ids[0]],
                  let lemma2 = lemmaCache[ids[1]] else { continue }
            
            if !lemma1.correspondences.contains(where: { $0.lemmaId == lemma2.lemmaId }) {
                lemma1.correspondences.append(lemma2)
                linkCount += 1
            }
            if !lemma2.correspondences.contains(where: { $0.lemmaId == lemma1.lemmaId }) {
                lemma2.correspondences.append(lemma1)
                linkCount += 1
            }
        }
        
        print("  Built \(linkCount) correspondence links")
    }
}
