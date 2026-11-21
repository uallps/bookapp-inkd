import Foundation
import Testing
@testable import inkd

/// Core: gestión de la biblioteca (alta, consulta, edición, cambio de estado, eliminación)
/// y persistencia. Siempre con `MockStorageProvider`: no se toca el disco.
struct LibraryViewModelTests {
    /// Una biblioteca ya cargada con los dos libros de prueba del Mock.
    private func makeViewModel() async -> LibraryViewModel {
        let viewModel = LibraryViewModel(storageProvider: MockStorageProvider())
        await viewModel.loadBooks()
        return viewModel
    }

    // MARK: - Carga

    @Test func cargaLosLibrosDelAlmacenamiento() async {
        let viewModel = await makeViewModel()
        #expect(viewModel.books.map(\.title) == ["Libro de prueba 1", "Libro de prueba 2"])
    }

    @Test func siElAlmacenamientoFallaSeQuedanLosLibrosDeEjemplo() async {
        let viewModel = LibraryViewModel(storageProvider: FailingStorageProvider())
        await viewModel.loadBooks()
        #expect(viewModel.books.contains { $0.title == "Cien años de soledad" })
    }

    // MARK: - Alta

    @Test func añadirUnLibroConTituloLoAgrega() async {
        let viewModel = await makeViewModel()
        #expect(viewModel.addBook(title: "Dune", author: "Frank Herbert"))
        #expect(viewModel.books.last?.title == "Dune")
        #expect(viewModel.books.last?.author == "Frank Herbert")
        #expect(viewModel.books.last?.status == .toRead)
    }

    @Test func añadirSinTituloNoAgregaNada() async {
        let viewModel = await makeViewModel()
        let antes = viewModel.books.count
        #expect(viewModel.addBook(title: "   ") == false)
        #expect(viewModel.books.count == antes)
    }

    @Test func añadirLimpiaElTituloYElAutorVacio() async {
        let viewModel = await makeViewModel()
        viewModel.addBook(title: "  Dune ", author: "   ")
        #expect(viewModel.books.last?.title == "Dune")
        #expect(viewModel.books.last?.author == nil)
    }

    // MARK: - Consulta

    @Test func buscaUnLibroPorId() async {
        let viewModel = await makeViewModel()
        let primero = viewModel.books[0]
        #expect(viewModel.book(id: primero.id)?.title == primero.title)
        #expect(viewModel.book(id: UUID()) == nil)
    }

    // MARK: - Edición

    @Test func editarCambiaTituloYAutor() async {
        let viewModel = await makeViewModel()
        var libro = viewModel.books[0]
        libro.title = "Nuevo título"
        libro.author = "Nueva autora"
        viewModel.updateBook(libro)
        #expect(viewModel.books[0].title == "Nuevo título")
        #expect(viewModel.books[0].author == "Nueva autora")
    }

    @Test func editarConTituloVacioConservaElAnterior() async {
        let viewModel = await makeViewModel()
        var libro = viewModel.books[0]
        let tituloOriginal = libro.title
        libro.title = "   "
        viewModel.updateBook(libro)
        #expect(viewModel.books[0].title == tituloOriginal)
    }

    @Test func editarConAutorVacioLoQuita() async {
        let viewModel = await makeViewModel()
        var libro = viewModel.books[1]   // el segundo tiene autor
        libro.author = ""
        viewModel.updateBook(libro)
        #expect(viewModel.books[1].author == nil)
    }

    @Test func editarUnLibroQueNoExisteNoHaceNada() async {
        let viewModel = await makeViewModel()
        let antes = viewModel.books.map(\.title)
        viewModel.updateBook(Book(title: "Fantasma"))
        #expect(viewModel.books.map(\.title) == antes)
    }

    // MARK: - Cambio de estado

    @Test func setStatusCambiaElEstado() async {
        let viewModel = await makeViewModel()
        let id = viewModel.books[0].id
        viewModel.setStatus(id: id, .read)
        #expect(viewModel.book(id: id)?.status == .read)
    }

    @Test func advanceStatusRecorreLosTresEstados() async {
        let viewModel = await makeViewModel()
        let id = viewModel.books[0].id   // empieza «Por leer»
        viewModel.advanceStatus(id: id)
        #expect(viewModel.book(id: id)?.status == .reading)
        viewModel.advanceStatus(id: id)
        #expect(viewModel.book(id: id)?.status == .read)
        viewModel.advanceStatus(id: id)
        #expect(viewModel.book(id: id)?.status == .toRead)
    }

    // MARK: - Eliminación

    @Test func eliminarQuitaSoloEseLibro() async {
        let viewModel = await makeViewModel()
        let borrado = viewModel.books[0].id
        let restante = viewModel.books[1].id
        viewModel.removeBook(id: borrado)
        #expect(viewModel.books.count == 1)
        #expect(viewModel.book(id: borrado) == nil)
        #expect(viewModel.book(id: restante) != nil)
    }

    // MARK: - Persistencia

    @Test func cadaCambioSeGuardaEnElAlmacenamiento() async throws {
        let almacen = MockStorageProvider()
        let viewModel = LibraryViewModel(storageProvider: almacen)
        await viewModel.loadBooks()
        viewModel.addBook(title: "Dune")
        // El guardado es asíncrono (una Task): se deja correr antes de comprobar.
        try await Task.sleep(nanoseconds: 200_000_000)
        let guardados = try await almacen.loadBooks()
        #expect(guardados.contains { $0.title == "Dune" })
    }
}

/// Un almacenamiento que siempre falla, para probar que la app no se rompe.
private struct FailingStorageProvider: StorageProvider {
    struct Failure: Error {}
    func loadBooks() async throws -> [Book] { throw Failure() }
    func saveBooks(books: [Book]) async throws { throw Failure() }
}
