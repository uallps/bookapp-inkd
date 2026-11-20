import Foundation

/// F2: una anotación personal vinculada a un libro (vive en `Book.notes`).
/// El modelo existe en todos los productos; la interfaz solo con el trait `Notas`.
struct Note: Identifiable, Codable {
    var id = UUID()
    /// Nunca vacío (ver `Note.cleanText`).
    var text: String
    var kind: NoteKind = .note
    /// Página del libro a la que se refiere, si se indica.
    var page: Int?
    var createdAt = Date()
}

/// Tipo de anotación: una nota propia o una cita literal del libro.
enum NoteKind: String, CaseIterable, Codable {
    case note = "Nota"
    case quote = "Cita"
}

extension Note {
    /// El texto sin espacios sobrantes, o `nil` si queda vacío.
    static func cleanText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// La página escrita en un campo de texto: un número positivo, o `nil` si no lo es.
    static func parsePage(_ text: String) -> Int? {
        guard let page = Int(text.trimmingCharacters(in: .whitespaces)), page > 0 else { return nil }
        return page
    }
}
