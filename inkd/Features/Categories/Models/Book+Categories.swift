import Foundation

/// F3: filtro de la biblioteca por categoría. `.all` no filtra; `.uncategorized` deja los
/// libros sin categoría; `.category` deja los de esa categoría (sin distinguir mayúsculas).
enum CategoryFilter: Hashable {
    case all
    case uncategorized
    case category(String)

    /// El texto que se ve en el selector del filtro.
    var title: String {
        switch self {
        case .all: return "Todas"
        case .uncategorized: return "Sin categoría"
        case .category(let name): return name
        }
    }

    /// ¿Pasa este libro el filtro?
    func matches(_ book: Book) -> Bool {
        switch self {
        case .all:
            return true
        case .uncategorized:
            return book.categoryName == nil
        case .category(let name):
            guard let own = book.categoryName else { return false }
            return own.caseInsensitiveCompare(name) == .orderedSame
        }
    }
}

/// F3: clasificación de los libros en categorías y filtrado de la biblioteca.
/// La categoría (`Book.category`) está siempre en el modelo, como el resto de datos de las
/// características; aquí está la lógica, que usan el detalle y la lista.
extension Book {
    /// La categoría sin espacios al principio ni al final, o `nil` si no tiene (o queda vacía).
    /// Se usa para mostrar, comparar y filtrar. El texto guardado en `category` no se recorta
    /// para no comerse los espacios mientras se escribe en el detalle (como el autor).
    var categoryName: String? {
        guard let category else { return nil }
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Las categorías que hay en una lista de libros, sin repetir (sin distinguir mayúsculas;
    /// se conserva la primera escritura) y ordenadas alfabéticamente.
    static func categories(in books: [Book]) -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for name in books.compactMap(\.categoryName) where seen.insert(name.lowercased()).inserted {
            names.append(name)
        }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Los libros que pasan el filtro, en su orden original.
    static func filter(_ books: [Book], by filter: CategoryFilter) -> [Book] {
        books.filter { filter.matches($0) }
    }

    /// Cuántos libros hay en cada categoría (clave en minúsculas), para el selector.
    static func categoryCounts(in books: [Book]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for name in books.compactMap(\.categoryName) {
            counts[name.lowercased(), default: 0] += 1
        }
        return counts
    }
}
