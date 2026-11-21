#if Progreso
import Foundation

/// Dónde guarda F1 el progreso de los libros. Mismo patrón que `StorageProvider`:
/// el ViewModel del progreso solo conoce este protocolo.
protocol ProgressStorageProvider {
    func loadProgress() async throws -> [BookProgress]
    func saveProgress(_ entries: [BookProgress]) async throws
}

/// Guarda el progreso en su propio fichero, `progress.json`, junto a `books.json`.
/// Va siempre en JSON, también cuando en Apple los libros se guardan en SwiftData:
/// el progreso no depende de cómo guarde el núcleo sus libros.
final class JSONProgressStorageProvider: ProgressStorageProvider {
    private let fileURL: URL

    init(filename: String = "progress.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadProgress() async throws -> [BookProgress] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([BookProgress].self, from: data)
    }

    func saveProgress(_ entries: [BookProgress]) async throws {
        let data = try JSONEncoder().encode(entries)
        // La carpeta Documentos no existe en todos los sistemas (por ejemplo, un Linux mínimo).
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL)
    }
}

/// Progreso en memoria, para pruebas: no escribe nada en disco. Empieza vacío.
final class MockProgressStorageProvider: ProgressStorageProvider {
    private var storedEntries: [BookProgress] = []

    func loadProgress() async throws -> [BookProgress] {
        storedEntries
    }

    func saveProgress(_ entries: [BookProgress]) async throws {
        storedEntries = entries
    }
}
#endif
