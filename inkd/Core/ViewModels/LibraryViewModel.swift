import Foundation
import Observation

@Observable
final class LibraryViewModel {
    /// Cada cambio en la biblioteca (añadir, borrar, cambiar estado o editar en el detalle) se guarda.
    /// Los libros de ejemplo traen también datos de las características (notas, préstamo,
    /// fechas); cada producto muestra solo los suyos.
    var books: [Book] = [
        Book(
            title: "Cien años de soledad", author: "Gabriel García Márquez", status: .read,
            notes: [Note(
                text: "Muchos años después, frente al pelotón de fusilamiento…",
                kind: .quote, page: 1, createdAt: Date(timeIntervalSince1970: 1_760_000_000))],
            startedAt: Date(timeIntervalSince1970: 1_756_684_800),   // 1 sep 2025
            finishedAt: Date(timeIntervalSince1970: 1_760_486_400)   // 15 oct 2025
        ),
        Book(
            title: "El nombre del viento", author: "Patrick Rothfuss", status: .reading,
            startedAt: Date(timeIntervalSince1970: 1_761_955_200)    // 1 nov 2025
        ),
        Book(
            title: "El principito", author: "Antoine de Saint-Exupéry",
            loanedTo: "Lucía", loanDate: Date(timeIntervalSince1970: 1_762_732_800)  // 10 nov 2025
        )
    ] {
        didSet { save() }
    }

    @ObservationIgnored private let storageProvider: StorageProvider
    @ObservationIgnored private var loaded = false

    /// Por defecto guarda en JSON; en pruebas se le pasa un MockStorageProvider.
    init(storageProvider: StorageProvider = JSONStorageProvider()) {
        self.storageProvider = storageProvider
        _Concurrency.Task { await loadBooks() }
    }

    /// Carga los libros guardados, solo la primera vez que se llama.
    /// Si aún no hay fichero, se quedan los libros de ejemplo.
    func loadBooks() async {
        guard !loaded else { return }
        loaded = true
        do {
            books = try await storageProvider.loadBooks()
        } catch {
            print("No se han cargado libros: \(error)")
        }
    }

    /// Alta de un libro. Si el título está vacío no se añade nada y devuelve `false`.
    @discardableResult
    func addBook(title: String, author: String? = nil) -> Bool {
        guard let title = Book.cleanTitle(title) else { return false }
        books.append(Book(title: title, author: Book.cleanAuthor(author)))
        return true
    }

    func removeBook(id: UUID) {
        books.removeAll { $0.id == id }
    }

    /// El libro con ese id, si sigue en la biblioteca.
    func book(id: UUID) -> Book? {
        books.first { $0.id == id }
    }

    /// Sustituye el libro que tiene el mismo id (la usa el detalle al editar).
    /// Un título vacío no se guarda: el libro conserva el que tenía.
    /// Todos los cambios de estado pasan por aquí (también `setStatus`).
    func updateBook(_ book: Book) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        var book = book
        if Book.cleanTitle(book.title) == nil {
            book.title = books[index].title
        }
        book.author = Book.cleanAuthor(book.author)
#if FechasLectura
        // O2: al cambiar de estado se apuntan (o se borran) las fechas de lectura.
        book.updateReadingDates(from: books[index].status)
#endif
        books[index] = book
    }

    func setStatus(id: UUID, _ status: ReadingStatus) {
        guard var book = book(id: id) else { return }
        book.status = status
        updateBook(book)
    }

    /// Pasa el libro al estado siguiente (lo usa el botón de la fila).
    func advanceStatus(id: UUID) {
        guard let book = book(id: id) else { return }
        setStatus(id: id, book.status.next)
    }

    /// Guarda la biblioteca completa. `_Concurrency.Task` es la tarea asíncrona de Swift
    /// (se escribe con el módulo delante por costumbre de la plantilla, donde había un modelo `Task`).
    private func save() {
        let books = books
        _Concurrency.Task {
            do {
                try await storageProvider.saveBooks(books: books)
            } catch {
                print("No se han guardado los libros: \(error)")
            }
        }
    }
}
