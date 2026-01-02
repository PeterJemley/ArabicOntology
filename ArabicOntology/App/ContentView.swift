import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    let isReadOnlyStore: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var searchResults: [Lemma] = []
    @State private var sentenceResults: [SentenceSearchResult] = []
    @State private var statistics: OntologyStatistics?
    @State private var selectedLemma: Lemma?
    @State private var searchMode: SearchMode = .arabic
    @State private var corpusSelections = CorpusSelection.defaultSelections()
    @State private var detailFilter = ""
    @State private var history: [SearchState] = []
    @State private var historyIndex = -1
    @State private var isNavigatingHistory = false
    @State private var includeArabicTokens = false
    @State private var showZeroMatchTokens = false
    private let maxSentenceMatchesPerToken = 10
    
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
                    guard !isNavigatingHistory else { return }
                    if searchText.isEmpty {
                        pushHistory(currentSearchState())
                    } else {
                        performSearch()
                    }
                }
                
                HStack(spacing: 6) {
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!canGoBack)
                    .accessibilityLabel("Back")
                    
                    Button {
                        goForward()
                    } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!canGoForward)
                    .accessibilityLabel("Forward")
                    
                    TextField(searchMode.placeholder, text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            performSearch()
                        }
                }
                .padding([.horizontal, .bottom])

                if searchMode == .sentence {
                    HStack(spacing: 16) {
                        Toggle("Include Arabic tokens", isOn: $includeArabicTokens)
                        Toggle("Show zero-match tokens", isOn: $showZeroMatchTokens)
                    }
                    .padding([.horizontal, .bottom])
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
                    .disabled(isImporting || isReadOnlyStore)
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
                LemmaDetailView(lemma: lemma, detailFilter: $detailFilter)
            } else {
                Text("Select a lemma")
                    .foregroundStyle(.secondary)
            }
        }
        .font(AppFontScale.font(.body))
        .onChange(of: selectedLemma) {
            guard !isNavigatingHistory else { return }
            updateCurrentHistory { state in
                state.selectedLemmaId = selectedLemma?.lemmaId
            }
        }
        .onChange(of: detailFilter) {
            guard !isNavigatingHistory else { return }
            updateCurrentHistory { state in
                state.detailFilter = detailFilter
            }
        }
        .onChange(of: includeArabicTokens) {
            handleSentenceOptionChange()
        }
        .onChange(of: showZeroMatchTokens) {
            handleSentenceOptionChange()
        }
    }
    
    // MARK: - Views
    
    private var importProgressView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Importing...")
                .font(AppFontScale.font(.headline))
            Text(importProgress)
                .font(AppFontScale.font(.caption))
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
                        .font(AppFontScale.font(.headline))
                    Text("Click \"Import Data\" to load CSV files")
                        .foregroundStyle(.secondary)
                }
            }
            
            if isReadOnlyStore {
                Section("Bundled Database") {
                    Text("Using a prebuilt store. Import is disabled.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Import Options") {
                    ForEach($corpusSelections) { $selection in
                        Toggle(isOn: $selection.isSelected) {
                            VStack(alignment: .leading) {
                                Text(selection.descriptor.displayName)
                                if let sentenceFile = selection.descriptor.sentenceFile {
                                    Text("Sentences: \(sentenceFile)")
                                        .font(AppFontScale.font(.caption))
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Sentences: none")
                                        .font(AppFontScale.font(.caption))
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
        }
        .textSelection(.enabled)
    }
    
    private var resultsList: some View {
        Group {
            if searchMode == .sentence {
                sentenceResultsList
            } else {
                lemmaResultsList
            }
        }
    }
    
    private var lemmaResultsList: some View {
        List(searchResults, selection: $selectedLemma) { lemma in
            NavigationLink(value: lemma) {
                lemmaRow(lemma)
            }
        }
        .textSelection(.enabled)
    }
    
    private var sentenceResultsList: some View {
        List(selection: $selectedLemma) {
            if sentenceResults.isEmpty {
                Text("No matches for any tokens")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sentenceResults) { result in
                    Section {
                        if result.lemmas.isEmpty {
                            Text("No matches")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(result.lemmas) { lemma in
                                NavigationLink(value: lemma) {
                                    lemmaRow(lemma)
                                }
                            }
                            if result.hiddenMatches > 0 {
                                Text("... and \(result.hiddenMatches) more")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.token)
                                .font(AppFontScale.font(.headline))
                            Text("Occurrences: \(result.occurrences) • Matches: \(result.lemmas.count) of \(result.totalMatches)")
                                .font(AppFontScale.font(.caption))
                                .foregroundStyle(.secondary)
                            if !result.isEnglish {
                                Text("Arabic token")
                                    .font(AppFontScale.font(.caption))
                                    .foregroundStyle(.secondary)
                            }
                            if result.positions.count > 1 {
                                Text("Positions: \(result.positionsText)")
                                    .font(AppFontScale.font(.caption))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .textSelection(.enabled)
    }
    
    @ViewBuilder
    private func lemmaRow(_ lemma: Lemma) -> some View {
        VStack(alignment: .leading) {
            Text(lemma.lemma)
                .font(AppFontScale.font(.headline))
            HStack {
                Text(lemma.posCategoryEnglish)
                if let root = lemma.rootRef {
                    Text("•")
                    Text(root.root)
                }
            }
            .font(AppFontScale.font(.caption))
            .foregroundStyle(.secondary)
        }
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
    
    private func performSearch(selecting lemmaId: String? = nil, recordHistory: Bool = true) {
        let queryService = QueryService(modelContext: modelContext)
        guard !searchText.isEmpty else {
            searchResults = []
            sentenceResults = []
            if let lemmaId {
                selectedLemma = try? queryService.lemma(byId: lemmaId)
            }
            if recordHistory && !isNavigatingHistory {
                pushHistory(currentSearchState())
            }
            return
        }
        
        if searchMode == .sentence {
            let tokens = sentenceTokens(from: searchText)
            let hasEnglishTokens = tokens.contains { $0.isEnglish }
            let filteredTokens = (hasEnglishTokens && !includeArabicTokens)
                ? tokens.filter { $0.isEnglish }
                : tokens
            let results = sentenceSearchResults(from: filteredTokens, using: queryService)
            sentenceResults = results.grouped
            searchResults = results.flattened
            
            if let lemmaId {
                selectedLemma = searchResults.first { $0.lemmaId == lemmaId }
                    ?? (try? queryService.lemma(byId: lemmaId))
            } else {
                selectedLemma = nil
            }
            
            if recordHistory && !isNavigatingHistory {
                pushHistory(currentSearchState())
            }
            return
        }
        
        do {
            sentenceResults = []
            switch searchMode {
            case .arabic:
                searchResults = try queryService.lemmas(matching: searchText)
            case .english:
                searchResults = try queryService.lemmas(byGloss: searchText)
            case .formToken:
                searchResults = try queryService.lemmas(byFormToken: searchText)
            case .root:
                searchResults = try queryService.lemmas(byRoot: searchText)
            case .sentence:
                searchResults = []
            }
            
            if let lemmaId {
                selectedLemma = searchResults.first { $0.lemmaId == lemmaId }
                    ?? (try? queryService.lemma(byId: lemmaId))
            } else {
                selectedLemma = nil
            }
            
            if recordHistory && !isNavigatingHistory {
                pushHistory(currentSearchState())
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

    private func handleSentenceOptionChange() {
        guard !isNavigatingHistory else { return }
        if searchMode == .sentence, !searchText.isEmpty {
            performSearch()
        } else {
            updateCurrentHistory { state in
                state.includeArabicTokens = includeArabicTokens
                state.showZeroMatchTokens = showZeroMatchTokens
            }
        }
    }
    
    private struct SentenceToken {
        let text: String
        let position: Int
        let isEnglish: Bool
    }
    
    private func sentenceTokens(from text: String) -> [SentenceToken] {
        var tokens: [SentenceToken] = []
        var scalars = String.UnicodeScalarView()
        var currentHasArabic = false
        var position = 0
        
        func flushToken() {
            guard !scalars.isEmpty else { return }
            position += 1
            let token = String(scalars)
            tokens.append(SentenceToken(text: token, position: position, isEnglish: !currentHasArabic))
            scalars.removeAll(keepingCapacity: true)
            currentHasArabic = false
        }
        
        for scalar in text.unicodeScalars {
            if CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) {
                scalars.append(scalar)
                if isArabicScalar(scalar) {
                    currentHasArabic = true
                }
            } else {
                flushToken()
            }
        }
        
        flushToken()
        return tokens
    }
    
    private func sentenceSearchResults(
        from tokens: [SentenceToken],
        using queryService: QueryService
    ) -> (grouped: [SentenceSearchResult], flattened: [Lemma]) {
        var grouped: [SentenceSearchResult] = []
        var flattened: [Lemma] = []
        var flattenedSeen: Set<String> = []
        
        var groupedTokens: [String: (token: String, positions: [Int], isEnglish: Bool)] = [:]
        var orderedKeys: [String] = []
        
        for token in tokens {
            let tokenKey = normalizedTokenKey(token.text, isEnglish: token.isEnglish)
            guard !tokenKey.isEmpty else { continue }
            guard !isStopWord(tokenKey, isEnglish: token.isEnglish) else { continue }
            
            if var group = groupedTokens[tokenKey] {
                group.positions.append(token.position)
                groupedTokens[tokenKey] = group
            } else {
                groupedTokens[tokenKey] = (token: token.text, positions: [token.position], isEnglish: token.isEnglish)
                orderedKeys.append(tokenKey)
            }
        }
        
        for tokenKey in orderedKeys {
            guard let group = groupedTokens[tokenKey] else { continue }
            let token = group.token
            let allLemmas: [Lemma]
            
            if group.isEnglish {
                let glossMatches = (try? queryService.lemmas(byGloss: token)) ?? []
                
                var seen: Set<String> = []
                allLemmas = glossMatches.filter { seen.insert($0.lemmaId).inserted }
            } else {
                let headwordMatches = (try? queryService.lemmas(matching: token)) ?? []
                let formMatches = (try? queryService.lemmas(byFormToken: token)) ?? []
                
                var seen: Set<String> = []
                allLemmas = (headwordMatches + formMatches).filter {
                    seen.insert($0.lemmaId).inserted
                }
            }
            
            let sortedLemmas = allLemmas.sorted {
                $0.lemma.localizedStandardCompare($1.lemma) == .orderedAscending
            }
            
            let limitedLemmas = Array(sortedLemmas.prefix(maxSentenceMatchesPerToken))
            if sortedLemmas.isEmpty && !showZeroMatchTokens {
                continue
            }
            
            grouped.append(
                SentenceSearchResult(
                    tokenKey: tokenKey,
                    token: token,
                    positions: group.positions,
                    lemmas: limitedLemmas,
                    totalMatches: sortedLemmas.count,
                    isEnglish: group.isEnglish
                )
            )
            
            for lemma in limitedLemmas where flattenedSeen.insert(lemma.lemmaId).inserted {
                flattened.append(lemma)
            }
        }
        
        return (grouped, flattened)
    }
    
    private func normalizedTokenKey(_ token: String, isEnglish: Bool) -> String {
        if isEnglish {
            return token.lowercased()
        }
        return ArabicNormalizer.normalize(token)
    }
    
    private func isStopWord(_ tokenKey: String, isEnglish: Bool) -> Bool {
        if isEnglish {
            if tokenKey.count < 2 { return true }
            return Self.englishStopWords.contains(tokenKey)
        }
        return Self.arabicStopWords.contains(tokenKey)
    }
    
    private func isArabicToken(_ token: String) -> Bool {
        token.unicodeScalars.contains { scalar in
            isArabicScalar(scalar)
        }
    }
    
    private func isArabicScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x0600...0x06FF, 0x0750...0x077F, 0x08A0...0x08FF,
            0xFB50...0xFDFF, 0xFE70...0xFEFF:
            return true
        default:
            return false
        }
    }
    
    private static let englishStopWords: Set<String> = [
        "a", "an", "the", "and", "or", "but", "if", "then", "than", "as", "of",
        "to", "in", "on", "for", "with", "at", "by", "from", "up", "down", "out",
        "over", "under", "into", "onto", "off", "without",
        "is", "are", "was", "were", "be", "been", "being", "am",
        "do", "does", "did", "doing",
        "have", "has", "had", "having",
        "can", "could", "will", "would", "shall", "should", "may", "might", "must",
        "it", "this", "that", "these", "those", "here", "there",
        "i", "you", "he", "she", "we", "they", "me", "him", "her", "us", "them",
        "my", "your", "his", "its", "our", "their", "mine", "yours", "hers", "ours", "theirs",
        "not", "no", "yes", "only", "also", "just", "very", "so",
        "because", "while", "though", "although"
    ]
    
    private static let arabicStopWords: Set<String> = {
        let raw = [
            "\u{0648}", // waw
            "\u{0641}\u{064A}", // fi
            "\u{0645}\u{0646}", // min
            "\u{0639}\u{0644}\u{0649}", // ala
            "\u{0625}\u{0644}\u{0649}", // ila
            "\u{0627}\u{0644}\u{0649}", // ila
            "\u{0639}\u{0646}", // an
            "\u{0628}", // bi
            "\u{0643}", // ka
            "\u{0644}", // li
            "\u{0627}\u{0644}", // al
            "\u{0623}\u{0648}", // aw
            "\u{0627}\u{0648}", // aw
            "\u{062B}\u{0645}", // thumma
            "\u{0644}\u{0643}\u{0646}", // lakin
            "\u{0644}\u{0623}\u{0646}", // li'an
            "\u{0644}\u{0627}\u{0646}", // li'an
            "\u{0645}\u{0639}", // ma'a
            "\u{062D}\u{062A}\u{0649}", // hatta
            "\u{0647}\u{0630}\u{0627}", // hatha
            "\u{0647}\u{0630}\u{0647}", // hathih
            "\u{0630}\u{0644}\u{0643}", // dhalik
            "\u{062A}\u{0644}\u{0643}", // tilka
            "\u{0647}\u{0648}", // huwa
            "\u{0647}\u{064A}", // hiya
            "\u{0647}\u{0645}", // hum
            "\u{0647}\u{0646}", // hunna
            "\u{0646}\u{062D}\u{0646}", // nahnu
            "\u{0627}\u{0646}\u{0627}", // ana
            "\u{0623}\u{0646}\u{0627}", // ana
            "\u{0627}\u{0646}\u{062A}", // anta
            "\u{0623}\u{0646}\u{062A}", // anta
            "\u{0645}\u{0627}", // ma
            "\u{0644}\u{0627}", // la
            "\u{0644}\u{0645}", // lam
            "\u{0644}\u{0646}" // lan
        ]
        
        return Set(raw.map { ArabicNormalizer.normalize($0) })
    }()
    
    private var canGoBack: Bool {
        historyIndex > 0
    }
    
    private var canGoForward: Bool {
        historyIndex >= 0 && historyIndex < history.count - 1
    }
    
    private func goBack() {
        restoreHistory(at: historyIndex - 1)
    }
    
    private func goForward() {
        restoreHistory(at: historyIndex + 1)
    }
    
    private func restoreHistory(at index: Int) {
        guard history.indices.contains(index) else { return }
        
        isNavigatingHistory = true
        historyIndex = index
        
        let state = history[index]
        searchText = state.searchText
        searchMode = state.searchMode
        detailFilter = state.detailFilter
        includeArabicTokens = state.includeArabicTokens
        showZeroMatchTokens = state.showZeroMatchTokens
        
        if state.searchText.isEmpty {
            searchResults = []
            if let lemmaId = state.selectedLemmaId {
                let queryService = QueryService(modelContext: modelContext)
                selectedLemma = try? queryService.lemma(byId: lemmaId)
            } else {
                selectedLemma = nil
            }
            isNavigatingHistory = false
            return
        }
        
        performSearch(selecting: state.selectedLemmaId, recordHistory: false)
        isNavigatingHistory = false
    }
    
    private func currentSearchState() -> SearchState {
        SearchState(
            searchText: searchText,
            searchMode: searchMode,
            selectedLemmaId: selectedLemma?.lemmaId,
            detailFilter: detailFilter,
            includeArabicTokens: includeArabicTokens,
            showZeroMatchTokens: showZeroMatchTokens
        )
    }
    
    private func pushHistory(_ state: SearchState) {
        if historyIndex >= 0 && historyIndex < history.count && history[historyIndex] == state {
            return
        }
        
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)..<history.count)
        }
        
        history.append(state)
        historyIndex = history.count - 1
    }
    
    private func updateCurrentHistory(_ update: (inout SearchState) -> Void) {
        guard historyIndex >= 0 && historyIndex < history.count else { return }
        update(&history[historyIndex])
    }
}

// MARK: - Supporting Views

enum SearchMode: String, CaseIterable, Identifiable {
    case arabic
    case english
    case sentence
    case formToken
    case root
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .arabic: return "Arabic"
        case .english: return "English"
        case .sentence: return "Sentence"
        case .formToken: return "Form Token"
        case .root: return "Root"
        }
    }
    
    var placeholder: String {
        switch self {
        case .arabic: return "Search Arabic lemmas..."
        case .english: return "Search English gloss..."
        case .sentence: return "Search sentence..."
        case .formToken: return "Search form token..."
        case .root: return "Search root..."
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

struct SearchState: Equatable {
    var searchText: String
    var searchMode: SearchMode
    var selectedLemmaId: String?
    var detailFilter: String
    var includeArabicTokens: Bool
    var showZeroMatchTokens: Bool
}

struct SentenceSearchResult: Identifiable {
    let tokenKey: String
    let token: String
    let positions: [Int]
    let lemmas: [Lemma]
    let totalMatches: Int
    let isEnglish: Bool
    
    var id: String { tokenKey }
    var occurrences: Int { positions.count }
    var hiddenMatches: Int { max(0, totalMatches - lemmas.count) }
    var positionsText: String {
        positions.map(String.init).joined(separator: ", ")
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
    @Binding var detailFilter: String
    @State private var debouncedFilter = ""
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lemma.lemma)
                        .font(AppFontScale.font(.title2, scale: AppFontScale.headword, weight: .semibold))
                    Text("ID: \(lemma.lemmaId) | Dialect: \(lemma.dialect?.name ?? "Unknown")")
                        .font(AppFontScale.font(.caption))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                TextField("Filter details...", text: $detailFilter)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing, 24)
                    .overlay(alignment: .trailing) {
                        if !detailFilter.isEmpty {
                            Button {
                                detailFilter = ""
                                debouncedFilter = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                            .accessibilityLabel("Clear filter")
                        }
                    }
                    .task(id: detailFilter) {
                        let currentFilter = detailFilter
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        if Task.isCancelled { return }
                        debouncedFilter = currentFilter
                    }
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
                                    .font(AppFontScale.font(.headline))
                                if let gloss = concept.gloss {
                                    Text(gloss)
                                        .font(AppFontScale.font(.caption))
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
                                    .font(AppFontScale.font(.headline))
                                if let dialect = corresp.dialect {
                                    Text(dialect.name)
                                        .font(AppFontScale.font(.caption))
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
                                    .font(AppFontScale.font(.headline))
                                if let gloss = form.gloss {
                                    Text(gloss)
                                        .font(AppFontScale.font(.caption))
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
        !debouncedFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var lowercasedFilter: String {
        debouncedFilter.lowercased()
    }
    
    private var normalizedFilter: String {
        ArabicNormalizer.normalize(debouncedFilter)
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
    ContentView(isReadOnlyStore: false)
        .modelContainer(for: [Concept.self, Root.self, Dialect.self, Lemma.self, Form.self, Sentence.self, GlossIndexEntry.self])
}
