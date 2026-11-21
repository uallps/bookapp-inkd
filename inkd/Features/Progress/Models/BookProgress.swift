#if Progreso
import Foundation

/// F1: el progreso de lectura de un libro. Es un dato de la característica, no de `Book`:
/// se une al libro por su id y se guarda en su propio fichero (`progress.json`), como la
/// fecha de vencimiento de la plantilla. Así el núcleo no sabe nada del progreso y, sin el
/// trait `Progreso`, este tipo ni siquiera existe.
struct BookProgress: Codable, Equatable {
    let bookID: UUID
    /// Total de páginas del libro. `nil` = aún no se ha indicado (nunca 0 ni negativo).
    var totalPages: Int?
    /// Página por la que va la lectura. 0 = sin empezar.
    var currentPage: Int = 0
}

extension BookProgress {
    /// Porcentaje leído, redondeado hacia abajo. Solo existe con un total válido:
    /// sin total no se puede saber qué parte del libro es una página.
    /// Se calcula cada vez, no se guarda, así nunca se desincroniza de las páginas.
    var percentage: Int? {
        guard let totalPages, totalPages > 0 else { return nil }
        return currentPage * 100 / totalPages
    }

    /// Texto de la fila: «Pág. 120 de 300 · 40 %», «Pág. 120» sin total,
    /// o `nil` si no hay nada que mostrar.
    var summary: String? {
        if let totalPages, let percentage {
            return "Pág. \(currentPage) de \(totalPages) · \(percentage) %"
        }
        return currentPage > 0 ? "Pág. \(currentPage)" : nil
    }

    /// Sin total y en la página 0: no hay nada que guardar.
    var isEmpty: Bool {
        totalPages == nil && currentPage == 0
    }

    /// El mismo progreso con las reglas aplicadas, en un solo sitio:
    /// un total de 0 o menos se quita; la página nunca es negativa y, si hay total,
    /// nunca lo supera (al bajar el total, la página se recorta).
    func normalized() -> BookProgress {
        var result = self
        if let total = result.totalPages, total <= 0 {
            result.totalPages = nil
        }
        result.currentPage = max(0, result.currentPage)
        if let total = result.totalPages {
            result.currentPage = min(result.currentPage, total)
        }
        return result
    }

    /// Un número de páginas escrito en un campo de texto: un entero de 0 en adelante,
    /// o `nil` si está vacío o no es un número válido (como `Note.parsePage`).
    static func parsePages(_ text: String) -> Int? {
        guard let pages = Int(text.trimmingCharacters(in: .whitespaces)), pages >= 0 else { return nil }
        return pages
    }
}
#endif
