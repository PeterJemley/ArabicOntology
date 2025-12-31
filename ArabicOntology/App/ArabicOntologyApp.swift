import SwiftUI
import SwiftData

@main
struct ArabicOntologyApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Concept.self,
            Root.self,
            Dialect.self,
            Lemma.self,
            Form.self,
            Sentence.self,
            GlossIndexEntry.self
        ])
        
        // Store in Application Support directory
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let appFolder = appSupport.appendingPathComponent("ArabicOntology", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        let storeURL = appFolder.appendingPathComponent("ArabicOntology.store")
        print("Database location: \(storeURL.path)")
        
        let config = ModelConfiguration(
            "ArabicOntology",
            schema: schema,
            url: storeURL,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
