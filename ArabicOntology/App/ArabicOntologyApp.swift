import SwiftUI
import SwiftData

@main
struct ArabicOntologyApp: App {
    
    private let store: StoreConfiguration
    
    init() {
        store = StoreConfiguration.make()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(isReadOnlyStore: store.isReadOnly)
        }
        .modelContainer(store.container)
    }
}

private struct StoreConfiguration {
    let container: ModelContainer
    let isReadOnly: Bool
    
    static func make() -> StoreConfiguration {
        let schema = Schema([
            Concept.self,
            Root.self,
            Dialect.self,
            Lemma.self,
            Form.self,
            Sentence.self,
            GlossIndexEntry.self
        ])
        
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let appFolder = appSupport.appendingPathComponent("ArabicOntology", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        let storeURL = appFolder.appendingPathComponent("ArabicOntology.store")
        
        let bundledStore = bundledStoreFiles()
        if let bundledStore, !FileManager.default.fileExists(atPath: storeURL.path) {
            do {
                try copyBundledStore(bundledStore, to: appFolder)
            } catch {
                print("Warning: Could not copy bundled store: \(error)")
            }
        }
        
        if FileManager.default.fileExists(atPath: storeURL.path) {
            print("Database location: \(storeURL.path)")
            let config = ModelConfiguration(
                "ArabicOntology",
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
            
            do {
                return StoreConfiguration(
                    container: try ModelContainer(for: schema, configurations: [config]),
                    isReadOnly: false
                )
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
        
        if let bundledURL = bundledStore?.store {
            let config = ModelConfiguration(
                "ArabicOntology",
                schema: schema,
                url: bundledURL,
                allowsSave: false
            )
            
            do {
                return StoreConfiguration(
                    container: try ModelContainer(for: schema, configurations: [config]),
                    isReadOnly: true
                )
            } catch {
                fatalError("Could not create bundled ModelContainer: \(error)")
            }
        }
        
        let config = ModelConfiguration(
            "ArabicOntology",
            schema: schema,
            url: storeURL,
            allowsSave: true
        )
        
        do {
            return StoreConfiguration(
                container: try ModelContainer(for: schema, configurations: [config]),
                isReadOnly: false
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private static func bundledStoreFiles() -> BundledStoreFiles? {
        if let url = Bundle.main.url(
            forResource: "ArabicOntology",
            withExtension: "store",
            subdirectory: "PrebuiltStore"
        ) {
            return BundledStoreFiles(baseStoreURL: url)
        }
        
        if let url = Bundle.main.url(
            forResource: "ArabicOntology",
            withExtension: "store"
        ) {
            return BundledStoreFiles(baseStoreURL: url)
        }
        
        return nil
    }
    
    private static func copyBundledStore(_ bundled: BundledStoreFiles, to folder: URL) throws {
        let fileManager = FileManager.default
        let files = bundled.urls
        
        for sourceURL in files {
            let destinationURL = folder.appendingPathComponent(sourceURL.lastPathComponent)
            if fileManager.fileExists(atPath: destinationURL.path) {
                continue
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }
}

private struct BundledStoreFiles {
    let store: URL
    let wal: URL?
    let shm: URL?
    
    init(baseStoreURL: URL) {
        store = baseStoreURL
        
        let baseURL = baseStoreURL.deletingPathExtension()
        let walURL = baseURL.appendingPathExtension("store-wal")
        let shmURL = baseURL.appendingPathExtension("store-shm")
        
        wal = FileManager.default.fileExists(atPath: walURL.path) ? walURL : nil
        shm = FileManager.default.fileExists(atPath: shmURL.path) ? shmURL : nil
    }
    
    var urls: [URL] {
        [store, wal, shm].compactMap { $0 }
    }
}
