import Foundation

/// Simple CSV parser that handles quoted fields and various line endings
struct CSVParser {
    
    /// Parse CSV file at path
    static func parse(contentsOf url: URL) throws -> [[String: String]] {
        let content = try String(contentsOf: url, encoding: .utf8)
        return parse(content)
    }
    
    /// Parse CSV string
    static func parse(_ content: String) -> [[String: String]] {
        // Normalize line endings
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        let lines = normalized.components(separatedBy: "\n")
        guard let headerLine = lines.first else { return [] }
        
        let headers = parseRow(headerLine)
        var results: [[String: String]] = []
        
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let values = parseRow(line)
            var row: [String: String] = [:]
            
            for (index, header) in headers.enumerated() {
                if index < values.count {
                    row[header] = values[index]
                } else {
                    row[header] = ""
                }
            }
            
            results.append(row)
        }
        
        return results
    }
    
    /// Parse a single CSV row, handling quoted fields
    private static func parseRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()
        
        while let char = iterator.next() {
            if char == "\"" {
                if inQuotes {
                    // Check for escaped quote
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else {
                            inQuotes = false
                            if next == "," {
                                fields.append(current)
                                current = ""
                            } else {
                                current.append(next)
                            }
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        
        fields.append(current)
        return fields.map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

// MARK: - Validation

extension CSVParser {
    
    /// Validate that required columns exist in parsed data
    static func validate(_ rows: [[String: String]], requiredColumns: [String], file: String) throws {
        guard let firstRow = rows.first else {
            throw CSVError.emptyFile(file)
        }
        
        let presentColumns = Set(firstRow.keys)
        let missingColumns = requiredColumns.filter { !presentColumns.contains($0) }
        
        if !missingColumns.isEmpty {
            throw CSVError.missingColumns(file: file, columns: missingColumns)
        }
    }
}

enum CSVError: LocalizedError {
    case emptyFile(String)
    case missingColumns(file: String, columns: [String])
    
    var errorDescription: String? {
        switch self {
        case .emptyFile(let file):
            return "CSV file is empty: \(file)"
        case .missingColumns(let file, let columns):
            return "CSV file '\(file)' missing required columns: \(columns.joined(separator: ", "))"
        }
    }
}

// MARK: - Convenience Extensions

extension CSVParser {
    
    /// Get string value, returning nil for empty or NULL
    static func string(_ row: [String: String], _ key: String) -> String? {
        guard let value = row[key], !value.isEmpty, value != "NULL" else {
            return nil
        }
        return value
    }
    
    /// Get required string value
    static func requiredString(_ row: [String: String], _ key: String) -> String {
        row[key] ?? ""
    }
    
    /// Get integer value
    static func int(_ row: [String: String], _ key: String) -> Int? {
        guard let value = row[key] else { return nil }
        return Int(value)
    }
    
    /// Get boolean value (checks for presence of non-empty value)
    static func bool(_ row: [String: String], _ key: String) -> Bool {
        guard let value = row[key], !value.isEmpty else { return false }
        return true
    }
}
