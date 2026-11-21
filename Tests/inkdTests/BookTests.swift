import Foundation
import Testing
@testable import inkd

/// Core: reglas del modelo (título no vacío, autor opcional, estados) y compatibilidad del JSON.
struct BookTests {
    @Test func cleanTitleQuitaEspaciosSobrantes() {
        #expect(Book.cleanTitle("  Dune  ") == "Dune")
    }

    @Test func cleanTitleRechazaVacioYSoloEspacios() {
        #expect(Book.cleanTitle("") == nil)
        #expect(Book.cleanTitle("   \n ") == nil)
    }

    @Test func cleanAuthorConvierteVacioEnSinAutor() {
        #expect(Book.cleanAuthor(nil) == nil)
        #expect(Book.cleanAuthor("") == nil)
        #expect(Book.cleanAuthor("   ") == nil)
        #expect(Book.cleanAuthor("Frank Herbert") == "Frank Herbert")
    }

    @Test func unLibroNuevoEmpiezaPorLeerYSinDatosOpcionales() {
        let book = Book(title: "Dune")
        #expect(book.status == .toRead)
        #expect(book.author == nil)
        #expect(book.notes.isEmpty)
    }

    @Test func cadaLibroTieneSuPropioIdentificador() {
        #expect(Book(title: "A").id != Book(title: "A").id)
    }

    @Test func elEstadoSiguienteDaLaVueltaCompleta() {
        #expect(ReadingStatus.toRead.next == .reading)
        #expect(ReadingStatus.reading.next == .read)
        #expect(ReadingStatus.read.next == .toRead)
    }

    @Test func codableDevuelveElMismoLibro() throws {
        var book = Book(title: "Dune", author: "Frank Herbert", status: .reading)
        book.loanedTo = "Lucía"
        let data = try JSONEncoder().encode(book)
        let decoded = try JSONDecoder().decode(Book.self, from: data)
        #expect(decoded.id == book.id)
        #expect(decoded.title == "Dune")
        #expect(decoded.author == "Frank Herbert")
        #expect(decoded.status == .reading)
        #expect(decoded.loanedTo == "Lucía")
    }

    @Test func unJsonAntiguoSoloConTituloSeLeeConValoresPorDefecto() throws {
        let json = Data(#"{"title": "Antiguo"}"#.utf8)
        let book = try JSONDecoder().decode(Book.self, from: json)
        #expect(book.title == "Antiguo")
        #expect(book.status == .toRead)
        #expect(book.notes.isEmpty)
        #expect(book.author == nil)
    }

    @Test func unJsonSinTituloNoSeLee() {
        let json = Data(#"{"author": "Nadie"}"#.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Book.self, from: json)
        }
    }
}
