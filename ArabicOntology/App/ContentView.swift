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
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .arabic: return "Arabic"
        case .english: return "English"
        }
    }
    
    var placeholder: String {
        switch self {
        case .arabic: return "Search Arabic lemmas..."
        case .english: return "Search English gloss..."
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
    
    var body: some View {
        List {
            // Basic info
            Section("Lemma") {
                LabeledContent("Headword", value: lemma.lemma)
                LabeledContent("ID", value: lemma.lemmaId)
                LabeledContent("Language", value: lemma.language)
                LabeledContent("POS Category", value: lemma.posCategory)
                LabeledContent("POS", value: lemma.pos)
            }
            
            // Root
            if let root = lemma.rootRef {
                Section("Root") {
                    LabeledContent("Root", value: root.root)
                    LabeledContent("Consonants", value: "\(root.consonantCount)")
                }
            }
            
            // Morphological features
            Section("Morphology") {
                if let aug = lemma.augmentation { LabeledContent("Augmentation", value: aug) }
                if let num = lemma.number { LabeledContent("Number", value: num) }
                if let gen = lemma.gender { LabeledContent("Gender", value: gen) }
                if let voice = lemma.voice { LabeledContent("Voice", value: voice) }
                if let trans = lemma.transitivity { LabeledContent("Transitivity", value: trans) }
                if lemma.uninflected { LabeledContent("Uninflected", value: "Yes") }
            }
            
            // Concepts
            if !lemma.concepts.isEmpty {
                Section("Concepts (\(lemma.concepts.count))") {
                    ForEach(lemma.concepts) { concept in
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
            
            // Correspondences
            if !lemma.correspondences.isEmpty {
                Section("Correspondences (\(lemma.correspondences.count))") {
                    ForEach(lemma.correspondences) { corresp in
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
            
            // Forms
            if !lemma.forms.isEmpty {
                Section("Forms (\(lemma.forms.count))") {
                    ForEach(lemma.forms.prefix(20)) { form in
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
                    if lemma.forms.count > 20 {
                        Text("... and \(lemma.forms.count - 20) more")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .textSelection(.enabled)
        .navigationTitle(lemma.lemma)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Concept.self, Root.self, Dialect.self, Lemma.self, Form.self, Sentence.self, GlossIndexEntry.self])
}
