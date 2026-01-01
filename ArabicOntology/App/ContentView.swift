import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var searchResults: [Lemma] = []
    @State private var statistics: OntologyStatistics?
    @State private var selectedLemma: Lemma?
    @State private var searchMode: SearchMode = .arabic
    @State private var corpusSelections = CorpusSelection.defaultSelections()
    
    // Import state
    @State private var isImporting = false
    @State private var importProgress = ""
    @State private var showFolderPicker = false
    
    var body: some View {
        NavigationSplitView {
            VStack {
                // Search field
                Picker("Search Mode", selection: $searchMode) {
                    ForEach(SearchMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])
                .onChange(of: searchMode) {
                    if !searchText.isEmpty {
                        performSearch()
                    }
                }
                
                TextField(searchMode.placeholder, text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding([.horizontal, .bottom])
                    .onSubmit {
                        performSearch()
                    }
                
                // Results or statistics
                if isImporting {
                    importProgressView
                } else if searchResults.isEmpty && searchText.isEmpty {
                    statisticsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Arabic Ontology")
            .toolbar {
                ToolbarItem {
                    Button("Import Data") {
                        showFolderPicker = true
                    }
                    .disabled(isImporting)
                }
            }
            .fileImporter(
                isPresented: $showFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                handleFolderSelection(result)
            }
            .task {
                loadStatistics()
            }
        } detail: {
            if let lemma = selectedLemma {
                LemmaDetailView(lemma: lemma)
            } else {
                Text("Select a lemma")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Views
    
    private var importProgressView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Importing...")
                .font(.headline)
            Text(importProgress)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var statisticsView: some View {
        List {
            Section("Database Statistics") {
                if let stats = statistics {
                    StatRow(label: "Concepts", value: stats.conceptCount)
                    StatRow(label: "Roots", value: stats.rootCount)
                    StatRow(label: "Lemmas", value: stats.lemmaCount)
                    StatRow(label: "Forms", value: stats.formCount)
                    StatRow(label: "Sentences", value: stats.sentenceCount)
                    StatRow(label: "Dialects", value: stats.dialectCount)
                } else {
                    Text("No data loaded")
                        .font(.headline)
                    Text("Click \"Import Data\" to load CSV files")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Import Options") {
                ForEach($corpusSelections) { $selection in
                    Toggle(isOn: $selection.isSelected) {
                        VStack(alignment: .leading) {
                            Text(selection.descriptor.displayName)
                            if let sentenceFile = selection.descriptor.sentenceFile {
                                Text("Sentences: \(sentenceFile)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Sentences: none")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .opacity(selection.isSelected ? 1.0 : 0.45)
                    .animation(.easeInOut(duration: 0.15), value: selection.isSelected)
                }
            }
            
            Section("Required Files") {
                Text("Arabic Ontology Data - Concepts")
                Text("Arabic Ontology Data - Relations")
                Text("Qabas - Arabic Lexicographic Database")
            }
        }
        .textSelection(.enabled)
    }
    
    private var resultsList: some View {
        List(searchResults, selection: $selectedLemma) { lemma in
            NavigationLink(value: lemma) {
                VStack(alignment: .leading) {
                    Text(lemma.lemma)
                        .font(.headline)
                    HStack {
                        Text(lemma.posCategoryEnglish)
                        if let root = lemma.rootRef {
                            Text("•")
                            Text(root.root)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .textSelection(.enabled)
    }
    
    // MARK: - Actions
    
    private func handleFolderSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let folderURL = urls.first else { return }
            
            // Need to access security-scoped resource
            guard folderURL.startAccessingSecurityScopedResource() else {
                importProgress = "Error: Cannot access folder"
                return
            }
            
            Task {
                await runImport(from: folderURL)
                folderURL.stopAccessingSecurityScopedResource()
            }
            
        case .failure(let error):
            importProgress = "Error: \(error.localizedDescription)"
        }
    }
    
    private func runImport(from folderURL: URL) async {
        isImporting = true
        importProgress = "Starting import..."
        
        let selectedCorpora = corpusSelections
            .filter { $0.isSelected }
            .map { $0.descriptor }
        
        let importer = ImportService(
            modelContext: modelContext,
            dataDirectory: folderURL,
            selectedCorpora: selectedCorpora
        )
        importer.progressCallback = { message in
            Task { @MainActor in
                importProgress = message
            }
        }
        
        do {
            try await importer.importAll()
            importProgress = "Import complete!"
            loadStatistics()
        } catch {
            importProgress = "Error: \(error.localizedDescription)"
        }
        
        isImporting = false
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let queryService = QueryService(modelContext: modelContext)
        do {
            switch searchMode {
            case .arabic:
                searchResults = try queryService.lemmas(matching: searchText)
            case .english:
                searchResults = try queryService.lemmas(byGloss: searchText)
            case .formToken:
                searchResults = try queryService.lemmas(byFormToken: searchText)
            }
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }
    
    private func loadStatistics() {
        let queryService = QueryService(modelContext: modelContext)
        do {
            statistics = try queryService.statistics()
        } catch {
            print("Error loading statistics: \(error)")
        }
    }
}

// MARK: - Supporting Views

enum SearchMode: String, CaseIterable, Identifiable {
    case arabic
    case english
    case formToken
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .arabic: return "Arabic"
        case .english: return "English"
        case .formToken: return "Form Token"
        }
    }
    
    var placeholder: String {
        switch self {
        case .arabic: return "Search Arabic lemmas..."
        case .english: return "Search English gloss..."
        case .formToken: return "Search form token..."
        }
    }
}

struct CorpusSelection: Identifiable {
    let descriptor: CorpusDescriptor
    var isSelected: Bool
    
    var id: String {
        descriptor.id
    }
    
    static func defaultSelections() -> [CorpusSelection] {
        CorpusDescriptor.all
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            .map { descriptor in
                CorpusSelection(descriptor: descriptor, isSelected: true)
            }
    }
}

struct StatRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value.formatted())")
                .foregroundStyle(.secondary)
        }
    }
}

struct LemmaDetailView: View {
    let lemma: Lemma
    @State private var detailFilter = ""
    
    var body: some View {
        List {
            Section {
                TextField("Filter details...", text: $detailFilter)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Basic info
            Section("Lemma") {
                if filteredLemmaRows.isEmpty && isFiltering {
                    Text("No matching lemma details")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredLemmaRows, id: \.0) { row in
                        LabeledContent(row.0, value: row.1)
                    }
                }
            }
            
            // Root
            if !rootRows.isEmpty {
                Section("Root") {
                    if filteredRootRows.isEmpty && isFiltering {
                        Text("No matching root details")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredRootRows, id: \.0) { row in
                            LabeledContent(row.0, value: row.1)
                        }
                    }
                }
            }
            
            // Morphological features
            if !morphologyRows.isEmpty {
                Section("Morphology") {
                    if filteredMorphologyRows.isEmpty && isFiltering {
                        Text("No matching morphology")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredMorphologyRows, id: \.0) { row in
                            LabeledContent(row.0, value: row.1)
                        }
                    }
                }
            }
            
            // Concepts
            if !lemma.concepts.isEmpty {
                let title = sectionTitle(
                    base: "Concepts",
                    filtered: filteredConcepts.count,
                    total: lemma.concepts.count
                )
                Section(title) {
                    if filteredConcepts.isEmpty {
                        Text("No matching concepts")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredConcepts) { concept in
                            VStack(alignment: .leading) {
                                Text(concept.arabicSynset)
                                    .font(.headline)
                                if let gloss = concept.gloss {
                                    Text(gloss)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            
            // Correspondences
            if !lemma.correspondences.isEmpty {
                let title = sectionTitle(
                    base: "Correspondences",
                    filtered: filteredCorrespondences.count,
                    total: lemma.correspondences.count
                )
                Section(title) {
                    if filteredCorrespondences.isEmpty {
                        Text("No matching correspondences")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredCorrespondences) { corresp in
                            VStack(alignment: .leading) {
                                Text(corresp.lemma)
                                    .font(.headline)
                                if let dialect = corresp.dialect {
                                    Text(dialect.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            
            // Forms
            if !lemma.forms.isEmpty {
                let title = sectionTitle(
                    base: "Forms",
                    filtered: filteredForms.count,
                    total: lemma.forms.count
                )
                Section(title) {
                    if filteredForms.isEmpty {
                        Text("No matching forms")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredForms) { form in
                            VStack(alignment: .leading) {
                                Text(form.token)
                                    .font(.headline)
                                if let gloss = form.gloss {
                                    Text(gloss)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        if !isFiltering && lemma.forms.count > 20 {
                            Text("... and \(lemma.forms.count - 20) more")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .textSelection(.enabled)
        .navigationTitle(lemma.lemma)
    }
    
    private var isFiltering: Bool {
        !detailFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var lowercasedFilter: String {
        detailFilter.lowercased()
    }
    
    private var normalizedFilter: String {
        ArabicNormalizer.normalize(detailFilter)
    }
    
    private func matches(_ text: String) -> Bool {
        guard isFiltering else { return true }
        if text.lowercased().contains(lowercasedFilter) {
            return true
        }
        return ArabicNormalizer.normalize(text).contains(normalizedFilter)
    }

    private func matchesOptional(_ text: String?) -> Bool {
        guard let text else { return false }
        return matches(text)
    }
    
    private func sectionTitle(base: String, filtered: Int, total: Int) -> String {
        if isFiltering {
            return "\(base) (\(filtered) of \(total))"
        }
        return "\(base) (\(total))"
    }
    
    private var lemmaRows: [(String, String)] {
        var rows: [(String, String)] = [
            ("Headword", lemma.lemma),
            ("ID", lemma.lemmaId),
            ("Language", lemma.language),
            ("POS Category", lemma.posCategory),
            ("POS", lemma.pos)
        ]
        if let attested = attestedDialectsText {
            rows.append(("Attested Dialect(s)", attested))
        }
        return rows
    }
    
    private var filteredLemmaRows: [(String, String)] {
        filterRows(lemmaRows)
    }
    
    private var rootRows: [(String, String)] {
        guard let root = lemma.rootRef else { return [] }
        return [
            ("Root", root.root),
            ("Consonants", "\(root.consonantCount)")
        ]
    }
    
    private var filteredRootRows: [(String, String)] {
        filterRows(rootRows)
    }
    
    private var morphologyRows: [(String, String)] {
        var rows: [(String, String)] = []
        if let aug = lemma.augmentation { rows.append(("Augmentation", aug)) }
        if let num = lemma.number { rows.append(("Number", num)) }
        if let gen = lemma.gender { rows.append(("Gender", gen)) }
        if let voice = lemma.voice { rows.append(("Voice", voice)) }
        if let trans = lemma.transitivity { rows.append(("Transitivity", trans)) }
        if lemma.uninflected { rows.append(("Uninflected", "Yes")) }
        return rows
    }
    
    private var filteredMorphologyRows: [(String, String)] {
        filterRows(morphologyRows)
    }
    
    private func filterRows(_ rows: [(String, String)]) -> [(String, String)] {
        guard isFiltering else { return rows }
        return rows.filter { matches($0.0) || matches($0.1) }
    }
    
    private var filteredConcepts: [Concept] {
        guard isFiltering else { return lemma.concepts }
        return lemma.concepts.filter { concept in
            matches(concept.arabicSynset)
                || matchesOptional(concept.englishSynset)
                || matchesOptional(concept.gloss)
                || matchesOptional(concept.example)
        }
    }
    
    private var filteredCorrespondences: [Lemma] {
        guard isFiltering else { return lemma.correspondences }
        return lemma.correspondences.filter { corresp in
            matches(corresp.lemma)
                || matchesOptional(corresp.dialect?.name)
                || matchesOptional(corresp.dialect?.code)
        }
    }
    
    private var filteredForms: [Form] {
        if !isFiltering {
            return Array(lemma.forms.prefix(20))
        }
        return lemma.forms.filter { form in
            matches(form.token)
                || matchesOptional(form.rawToken)
                || matchesOptional(form.gloss)
                || matchesOptional(form.pos)
                || matchesOptional(form.prefixes)
                || matchesOptional(form.stem)
                || matchesOptional(form.suffixes)
                || matchesOptional(form.subdialect)
        }
    }
    
    private var attestedDialectsText: String? {
        let dialectNames = Set(lemma.forms.compactMap { $0.dialect?.name })
        guard !dialectNames.isEmpty else { return nil }
        return dialectNames.sorted().joined(separator: ", ")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Concept.self, Root.self, Dialect.self, Lemma.self, Form.self, Sentence.self, GlossIndexEntry.self])
}
