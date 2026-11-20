/// Estado de lectura de un libro. El texto (rawValue) es lo que se ve y lo que se guarda en JSON.
enum ReadingStatus: String, CaseIterable, Codable {
    case toRead = "Por leer"
    case reading = "Leyendo"
    case read = "Leído"

    /// El estado siguiente (Por leer → Leyendo → Leído → Por leer),
    /// para cambiarlo con un clic desde la fila.
    var next: ReadingStatus {
        switch self {
        case .toRead: return .reading
        case .reading: return .read
        case .read: return .toRead
        }
    }
}
