#if Notas
import Foundation
import Testing
@testable import inkd

/// F2 Notas y citas: alta, edición, borrado, resumen y vínculo con el libro.
/// Solo se compilan con el trait `Notas` (swift test --traits Notas).
struct NotesTests {
    // MARK: - Reglas de Note

    @Test func cleanTextQuitaEspaciosYRechazaVacio() {
        #expect(Note.cleanText("  hola ") == "hola")
        #expect(Note.cleanText("") == nil)
        #expect(Note.cleanText("  \n ") == nil)
    }

    @Test func parsePageSoloAceptaNumerosPositivos() {
        #expect(Note.parsePage("12") == 12)
        #expect(Note.parsePage(" 7 ") == 7)
        #expect(Note.parsePage("0") == nil)
        #expect(Note.parsePage("-3") == nil)
        #expect(Note.parsePage("abc") == nil)
        #expect(Note.parsePage("") == nil)
    }

    // MARK: - Alta

    @Test func unLibroNuevoNoTieneNotas() {
        #expect(Book(title: "Dune").notes.isEmpty)
    }

    @Test func añadirUnaNotaLaVinculaAlLibro() {
        var libro = Book(title: "Dune")
        let añadida = libro.addNote(text: "Muy buena", page: 42)
        #expect(añadida)
        #expect(libro.notes.count == 1)
        #expect(libro.notes[0].text == "Muy buena")
        #expect(libro.notes[0].kind == .note)
        #expect(libro.notes[0].page == 42)
    }

    @Test func añadirUnaCita() {
        var libro = Book(title: "Dune")
        libro.addNote(text: "El miedo es el asesino de la mente", kind: .quote)
        #expect(libro.notes[0].kind == .quote)
    }

    @Test func añadirNotaVaciaNoAgregaNada() {
        var libro = Book(title: "Dune")
        let añadida = libro.addNote(text: "   ")
        #expect(añadida == false)
        #expect(libro.notes.isEmpty)
    }

    @Test func lasNotasDeUnLibroNoAparecenEnOtro() {
        var a = Book(title: "A")
        let b = Book(title: "B")
        a.addNote(text: "Solo de A")
        #expect(a.notes.count == 1)
        #expect(b.notes.isEmpty)
    }

    // MARK: - Edición

    @Test func editarUnaNotaCambiaSuTexto() {
        var libro = Book(title: "Dune")
        libro.addNote(text: "Antes")
        var nota = libro.notes[0]
        nota.text = "Después"
        libro.updateNote(nota)
        #expect(libro.notes[0].text == "Después")
    }

    @Test func editarConTextoVacioConservaElAnterior() {
        var libro = Book(title: "Dune")
        libro.addNote(text: "Antes")
        var nota = libro.notes[0]
        nota.text = "  "
        libro.updateNote(nota)
        #expect(libro.notes[0].text == "Antes")
    }

    @Test func editarUnaNotaQueNoExisteNoHaceNada() {
        var libro = Book(title: "Dune")
        libro.updateNote(Note(text: "Fantasma"))
        #expect(libro.notes.isEmpty)
    }

    // MARK: - Borrado

    @Test func borrarQuitaSoloEsaNota() {
        var libro = Book(title: "Dune")
        libro.addNote(text: "Una")
        libro.addNote(text: "Dos")
        let borrada = libro.notes[0].id
        libro.removeNote(id: borrada)
        #expect(libro.notes.map(\.text) == ["Dos"])
    }

    // MARK: - Resumen de la fila

    @Test func sinNotasNoHayResumen() {
        #expect(Book(title: "Dune").notesSummary == nil)
    }

    @Test func resumenEnSingularYPlural() {
        var libro = Book(title: "Dune")
        libro.addNote(text: "a")
        #expect(libro.notesSummary == "1 nota")
        libro.addNote(text: "b")
        #expect(libro.notesSummary == "2 notas")
        libro.addNote(text: "c", kind: .quote)
        #expect(libro.notesSummary == "2 notas · 1 cita")
        libro.addNote(text: "d", kind: .quote)
        #expect(libro.notesSummary == "2 notas · 2 citas")
    }

    @Test func resumenSoloDeCitas() {
        var libro = Book(title: "Dune")
        libro.addNote(text: "a", kind: .quote)
        #expect(libro.notesSummary == "1 cita")
    }

    // MARK: - Persistencia

    @Test func lasNotasSobrevivenAGuardarYLeer() throws {
        var libro = Book(title: "Dune")
        libro.addNote(text: "Cita", kind: .quote, page: 5)
        let data = try JSONEncoder().encode(libro)
        let leido = try JSONDecoder().decode(Book.self, from: data)
        #expect(leido.notes.count == 1)
        #expect(leido.notes[0].text == "Cita")
        #expect(leido.notes[0].kind == .quote)
        #expect(leido.notes[0].page == 5)
    }

    @Test func editarNotasDesdeElViewModelSeConserva() async {
        let viewModel = LibraryViewModel(storageProvider: MockStorageProvider())
        await viewModel.loadBooks()
        var libro = viewModel.books[0]
        libro.addNote(text: "Desde el detalle")
        viewModel.updateBook(libro)
        #expect(viewModel.books[0].notes.map(\.text) == ["Desde el detalle"])
    }
}
#endif
