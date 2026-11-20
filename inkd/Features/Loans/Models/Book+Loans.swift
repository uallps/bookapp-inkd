import Foundation

/// O1 Préstamos: a quién se ha dejado un libro y desde cuándo.
/// Los datos (`loanedTo`, `loanDate`) están en `Book`; aquí, las reglas.
extension Book {
    var isLoaned: Bool { loanedTo != nil }

    /// Presta el libro. Si el nombre está vacío no hace nada y devuelve `false`.
    @discardableResult
    mutating func lend(to person: String, on date: Date = Date()) -> Bool {
        let name = person.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        loanedTo = name
        loanDate = date
        return true
    }

    /// El libro ha vuelto: deja de estar prestado.
    mutating func markReturned() {
        loanedTo = nil
        loanDate = nil
    }

    /// Cambia la fecha del préstamo. No admite fechas futuras: devuelve `false` y no cambia nada.
    @discardableResult
    mutating func setLoanDate(_ date: Date, now: Date = Date()) -> Bool {
        guard isLoaned, date <= now else { return false }
        loanDate = date
        return true
    }

    /// Resumen para la fila de la biblioteca («Prestado a Lucía»), o `nil` si no está prestado.
    var loanSummary: String? {
        guard let loanedTo else { return nil }
        return "Prestado a \(loanedTo)"
    }
}
