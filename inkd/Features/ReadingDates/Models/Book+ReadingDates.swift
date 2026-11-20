import Foundation

/// O2 Fechas de lectura: cuándo se empezó y se terminó un libro.
/// Los datos (`startedAt`, `finishedAt`) están en `Book`; aquí, las reglas.
extension Book {
    /// Ajusta las fechas tras un cambio de estado. Lo llama el ViewModel con el estado anterior:
    /// - Por leer: sin fechas.
    /// - Leyendo: fecha de inicio (si no la tenía) y sin fecha de fin.
    /// - Leído: fecha de fin (y de inicio, si faltaba).
    mutating func updateReadingDates(from oldStatus: ReadingStatus, now: Date = Date()) {
        guard status != oldStatus else { return }
        switch status {
        case .toRead:
            startedAt = nil
            finishedAt = nil
        case .reading:
            if startedAt == nil { startedAt = now }
            finishedAt = nil
        case .read:
            if startedAt == nil { startedAt = now }
            finishedAt = now
        }
    }

    /// Corrige la fecha de inicio. No puede quedar después de la de fin: devuelve `false`.
    @discardableResult
    mutating func setStartedAt(_ date: Date) -> Bool {
        if let finishedAt, date > finishedAt { return false }
        startedAt = date
        return true
    }

    /// Corrige la fecha de fin. No puede quedar antes de la de inicio: devuelve `false`.
    @discardableResult
    mutating func setFinishedAt(_ date: Date) -> Bool {
        if let startedAt, date < startedAt { return false }
        finishedAt = date
        return true
    }

    /// Resumen para la fila de la biblioteca («Leído el 15 oct 2026»), o `nil` si no hay fechas.
    var readingDatesSummary: String? {
        if status == .read, let finishedAt {
            return "Leído el \(finishedAt.formatted(date: .abbreviated, time: .omitted))"
        }
        if let startedAt {
            return "Empezado el \(startedAt.formatted(date: .abbreviated, time: .omitted))"
        }
        return nil
    }
}
