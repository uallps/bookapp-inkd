import Foundation
import Testing
@testable import inkd

/// Core: persistencia local en JSON. Usa un fichero con nombre único en Documentos
/// y lo borra al terminar, para no tocar el `books.json` real del usuario.
struct JSONStorageProviderTests {
    private func borrar(_ filename: String) {
        let documentos = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? FileManager.default.removeItem(at: documentos.appendingPathComponent(filename))
    }

    @Test func guardarYLeerDevuelveLosMismosLibros() async throws {
        let filename = "inkd-test-\(UUID().uuidString).json"
        defer { borrar(filename) }
        let almacen = JSONStorageProvider(filename: filename)

        var libro = Book(title: "Dune", author: "Frank Herbert", status: .reading)
        libro.loanedTo = "Lucía"
        try await almacen.saveBooks(books: [libro, Book(title: "Emma")])

        let leidos = try await almacen.loadBooks()
        #expect(leidos.count == 2)
        #expect(leidos[0].id == libro.id)
        #expect(leidos[0].title == "Dune")
        #expect(leidos[0].status == .reading)
        #expect(leidos[0].loanedTo == "Lucía")
        #expect(leidos[1].title == "Emma")
    }

    @Test func guardarDosVecesSobrescribe() async throws {
        let filename = "inkd-test-\(UUID().uuidString).json"
        defer { borrar(filename) }
        let almacen = JSONStorageProvider(filename: filename)
        try await almacen.saveBooks(books: [Book(title: "Uno"), Book(title: "Dos")])
        try await almacen.saveBooks(books: [Book(title: "Solo")])
        #expect(try await almacen.loadBooks().map(\.title) == ["Solo"])
    }

    @Test func leerUnFicheroQueNoExisteLanzaError() async {
        let almacen = JSONStorageProvider(filename: "inkd-no-existe-\(UUID().uuidString).json")
        await #expect(throws: (any Error).self) {
            try await almacen.loadBooks()
        }
    }
}
