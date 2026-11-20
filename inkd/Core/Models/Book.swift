import Foundation

/// Un libro de la biblioteca. Codable: se puede guardar y leer en JSON.
struct Book: Identifiable, Codable {
    var id = UUID()
    /// Nunca vacío: el ViewModel no guarda un libro sin título (ver `Book.cleanTitle`).
    var title: String
    var author: String?
    var status: ReadingStatus = .toRead

    // Datos de las características opcionales. Como `priority` en la plantilla, están siempre
    // en el modelo: así todos los productos leen y guardan el mismo books.json sin perder
    // nada. Solo su interfaz y su comportamiento dependen del trait (`#if`).

    /// F2 Notas y citas (`inkd/Features/Notes/`).
    var notes: [Note] = []
    /// O1 Préstamos (`inkd/Features/Loans/`): a quién y desde cuándo. `nil` = no está prestado.
    var loanedTo: String?
    var loanDate: Date?
    /// O2 Fechas de lectura (`inkd/Features/ReadingDates/`).
    var startedAt: Date?
    var finishedAt: Date?
}

extension Book {
    /// Lee un libro aunque falten campos (un JSON anterior o de otro producto):
    /// lo que no está toma su valor por defecto. Solo el título es obligatorio.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        status = try container.decodeIfPresent(ReadingStatus.self, forKey: .status) ?? .toRead
        notes = try container.decodeIfPresent([Note].self, forKey: .notes) ?? []
        loanedTo = try container.decodeIfPresent(String.self, forKey: .loanedTo)
        loanDate = try container.decodeIfPresent(Date.self, forKey: .loanDate)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        finishedAt = try container.decodeIfPresent(Date.self, forKey: .finishedAt)
    }

    /// El título sin espacios al principio ni al final, o `nil` si queda vacío.
    /// Es la regla del núcleo «título no vacío», en un solo sitio.
    static func cleanTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// El autor es opcional: un texto vacío (o solo espacios) significa «sin autor».
    static func cleanAuthor(_ author: String?) -> String? {
        guard let author, !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return author
    }
}
