import Foundation
import SwiftData

/// Service for querying the Arabic ontology
@MainActor
final class QueryService {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Concept Queries
    
    /// Find concept by ID
    func concept(byId id: String) throws -> Concept? {
        let descriptor = FetchDescriptor<Concept>(
            predicate: #Predicate { $0.conceptId == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// Search concepts by Arabic synset term
    func concepts(matching query: String) throws -> [Concept] {
        let normalized = ArabicNormalizer.normalize(query)
        let descriptor = FetchDescriptor<Concept>()
        let all = try modelContext.fetch(descriptor)
        
        return all.filter { concept in
            concept.arabicTerms.contains { term in
                ArabicNormalizer.normalize(term).contains(normalized)
            }
        }
    }
    
    /// Search concepts by English synset term
    func concepts(matchingEnglish query: String) throws -> [Concept] {
        let lowercased = query.lowercased()
        let descriptor = FetchDescriptor<Concept>()
        let all = try modelContext.fetch(descriptor)
        
        return all.filter { concept in
            concept.englishTerms.contains { term in
                term.lowercased().contains(lowercased)
            }
        }
    }
    
    /// Get all lemmas expressing a concept
    func lemmas(forConcept concept: Concept) -> [Lemma] {
        concept.lemmas
    }
    
    /// Get lemmas for concept filtered by dialect
    func lemmas(forConcept concept: Concept, dialect: Dialect) -> [Lemma] {
        concept.lemmas.filter { $0.dialect?.code == dialect.code }
    }
    
    // MARK: - Root Queries
    
    /// Find root by consonantal skeleton
    func root(byRoot text: String) throws -> Root? {
        let descriptor = FetchDescriptor<Root>(
            predicate: #Predicate { $0.root == text }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// Search roots containing query
    func roots(containing query: String) throws -> [Root] {
        let descriptor = FetchDescriptor<Root>()
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.root.contains(query) }
    }
    
    /// Get all lemmas derived from a root
    func lemmas(fromRoot root: Root) -> [Lemma] {
        root.lemmas
    }
    
    /// Get concepts reachable from a root (via its lemmas)
    func concepts(fromRoot root: Root) -> [Concept] {
        let allConcepts = root.lemmas.flatMap { $0.concepts }
        // Deduplicate
        var seen: Set<String> = []
        return allConcepts.filter { seen.insert($0.conceptId).inserted }
    }
    
    // MARK: - Lemma Queries
    
    /// Find lemma by ID
    func lemma(byId id: String) throws -> Lemma? {
        let descriptor = FetchDescriptor<Lemma>(
            predicate: #Predicate { $0.lemmaId == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// Search lemmas by headword
    func lemmas(matching query: String) throws -> [Lemma] {
        let normalized = ArabicNormalizer.normalize(query)
        let descriptor = FetchDescriptor<Lemma>()
        let all = try modelContext.fetch(descriptor)
        
        return all.filter {
            ArabicNormalizer.normalize($0.lemma).contains(normalized)
        }
    }
    
    /// Search lemmas by English gloss token or phrase
    func lemmas(byGloss query: String) throws -> [Lemma] {
        let tokens = EnglishGlossNormalizer.tokens(from: query)
        guard !tokens.isEmpty else { return [] }
        
        var results: [Lemma] = []
        var seen: Set<String> = []
        
        for token in tokens {
            let descriptor = FetchDescriptor<GlossIndexEntry>(
                predicate: #Predicate { $0.token == token }
            )
            let entries = try modelContext.fetch(descriptor)
            for entry in entries {
                if let lemma = entry.lemma, seen.insert(lemma.lemmaId).inserted {
                    results.append(lemma)
                }
            }
        }
        
        if !results.isEmpty {
            return results
        }
        
        do {
            let descriptor = FetchDescriptor<Form>(
                predicate: #Predicate { $0.gloss != nil && $0.gloss!.contains(query) }
            )
            let forms = try modelContext.fetch(descriptor)
            for form in forms {
                if let lemma = form.lemma, seen.insert(lemma.lemmaId).inserted {
                    results.append(lemma)
                }
                if let lemma = form.msaLemma, seen.insert(lemma.lemmaId).inserted {
                    results.append(lemma)
                }
            }
        } catch {
            let lowercased = query.lowercased()
            let forms = try modelContext.fetch(FetchDescriptor<Form>())
            for form in forms {
                if form.gloss?.lowercased().contains(lowercased) == true {
                    if let lemma = form.lemma, seen.insert(lemma.lemmaId).inserted {
                        results.append(lemma)
                    }
                    if let lemma = form.msaLemma, seen.insert(lemma.lemmaId).inserted {
                        results.append(lemma)
                    }
                }
            }
        }
        
        return results
    }

    /// Search lemmas by form token (e.g., CODA)
    func lemmas(byFormToken query: String) throws -> [Lemma] {
        guard !query.isEmpty else { return [] }

        var results: [Lemma] = []
        var seen: Set<String> = []

        do {
            let descriptor = FetchDescriptor<Form>(
                predicate: #Predicate {
                    $0.token.contains(query) || ($0.rawToken?.contains(query) ?? false)
                }
            )
            let forms = try modelContext.fetch(descriptor)
            for form in forms {
                if let lemma = form.lemma, seen.insert(lemma.lemmaId).inserted {
                    results.append(lemma)
                }
                if let lemma = form.msaLemma, seen.insert(lemma.lemmaId).inserted {
                    results.append(lemma)
                }
            }
        } catch {
            // Fall back to normalized in-memory search if predicate is unsupported.
        }

        if !results.isEmpty {
            return results
        }

        let normalizedQuery = ArabicNormalizer.normalize(query)
        let forms = try modelContext.fetch(FetchDescriptor<Form>())
        for form in forms {
            let tokenMatches = ArabicNormalizer.normalize(form.token).contains(normalizedQuery)
            let rawMatches = form.rawToken.map {
                ArabicNormalizer.normalize($0).contains(normalizedQuery)
            } ?? false

            if tokenMatches || rawMatches {
                if let lemma = form.lemma, seen.insert(lemma.lemmaId).inserted {
                    results.append(lemma)
                }
                if let lemma = form.msaLemma, seen.insert(lemma.lemmaId).inserted {
                    results.append(lemma)
                }
            }
        }

        return results
    }
    
    /// Get lemmas by dialect
    func lemmas(inDialect dialect: Dialect) throws -> [Lemma] {
        let code = dialect.code
        let descriptor = FetchDescriptor<Lemma>(
            predicate: #Predicate { $0.dialect?.code == code }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get corresponding lemmas across dialects
    func correspondences(for lemma: Lemma) -> [Lemma] {
        lemma.correspondences
    }
    
    /// Get corresponding lemma in specific dialect
    func correspondence(for lemma: Lemma, inDialect dialect: Dialect) -> Lemma? {
        lemma.correspondences.first { $0.dialect?.code == dialect.code }
    }
    
    // MARK: - Form Queries
    
    /// Search forms by token
    func forms(matching query: String) throws -> [Form] {
        let normalized = ArabicNormalizer.normalize(query)
        let descriptor = FetchDescriptor<Form>()
        let all = try modelContext.fetch(descriptor)
        
        return all.filter {
            ArabicNormalizer.normalize($0.token).contains(normalized)
        }
    }
    
    /// Get forms for a lemma
    func forms(forLemma lemma: Lemma) -> [Form] {
        lemma.forms
    }
    
    /// Get forms in a specific dialect
    func forms(inDialect dialect: Dialect) throws -> [Form] {
        let code = dialect.code
        let descriptor = FetchDescriptor<Form>(
            predicate: #Predicate { $0.dialect?.code == code }
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Sentence Queries
    
    /// Get sentences containing a form
    func sentences(forLemma lemma: Lemma) -> [Sentence] {
        let allSentences = lemma.forms.compactMap { $0.sentence }
        // Deduplicate
        var seen: Set<String> = []
        return allSentences.filter { seen.insert($0.sentenceId).inserted }
    }
    
    /// Search sentences containing text
    func sentences(containing query: String) throws -> [Sentence] {
        let descriptor = FetchDescriptor<Sentence>()
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.text.contains(query) }
    }
    
    // MARK: - Dialect Queries
    
    /// Get all dialects
    func allDialects() throws -> [Dialect] {
        let descriptor = FetchDescriptor<Dialect>(
            sortBy: [SortDescriptor(\.code)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Find dialect by code
    func dialect(byCode code: String) throws -> Dialect? {
        let descriptor = FetchDescriptor<Dialect>(
            predicate: #Predicate { $0.code == code }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - Statistics
    
    /// Get counts of all entities
    func statistics() throws -> OntologyStatistics {
        OntologyStatistics(
            conceptCount: try modelContext.fetchCount(FetchDescriptor<Concept>()),
            rootCount: try modelContext.fetchCount(FetchDescriptor<Root>()),
            lemmaCount: try modelContext.fetchCount(FetchDescriptor<Lemma>()),
            formCount: try modelContext.fetchCount(FetchDescriptor<Form>()),
            sentenceCount: try modelContext.fetchCount(FetchDescriptor<Sentence>()),
            dialectCount: try modelContext.fetchCount(FetchDescriptor<Dialect>())
        )
    }
}

// MARK: - Statistics

struct OntologyStatistics {
    let conceptCount: Int
    let rootCount: Int
    let lemmaCount: Int
    let formCount: Int
    let sentenceCount: Int
    let dialectCount: Int
}
