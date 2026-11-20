import Foundation

/// F2: operaciones sobre las notas de un libro. Las usa el detalle a través de su
/// `@Binding`, así que cada cambio pasa por el ViewModel y se guarda.
extension Book {
    /// Añade una nota. Si el texto está vacío no añade nada y devuelve `false`.
    @discardableResult
    mutating func addNote(text: String, kind: NoteKind = .note, page: Int? = nil) -> Bool {
        guard let text = Note.cleanText(text) else { return false }
        notes.append(Note(text: text, kind: kind, page: page))
        return true
    }

    /// Sustituye la nota con el mismo id. Un texto vacío no se guarda: se conserva el anterior.
    mutating func updateNote(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var note = note
        if Note.cleanText(note.text) == nil {
            note.text = notes[index].text
        }
        notes[index] = note
    }

    mutating func removeNote(id: UUID) {
        notes.removeAll { $0.id == id }
    }

    /// Resumen para la fila de la biblioteca («2 notas · 1 cita»), o `nil` si no hay ninguna.
    var notesSummary: String? {
        let quotes = notes.filter { $0.kind == .quote }.count
        let plain = notes.count - quotes
        var parts: [String] = []
        if plain > 0 { parts.append(plain == 1 ? "1 nota" : "\(plain) notas") }
        if quotes > 0 { parts.append(quotes == 1 ? "1 cita" : "\(quotes) citas") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
