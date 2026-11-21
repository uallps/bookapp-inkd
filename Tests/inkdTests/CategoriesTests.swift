#if Categorias
import Foundation
import Testing
@testable import inkd

/// F3 Categorías: clasificación de los libros y filtrado de la biblioteca.
/// Solo se compilan con el trait `Categorias` (swift test --traits Categorias).
struct CategoriesTests {
    /// Una biblioteca de ejemplo: dos de «Novela» (una escrita distinto), una de «Ensayo» y una sin categoría.
    private func biblioteca() -> [Book] {
        var a = Book(title: "A"); a.category = "Novela"
        var b = Book(title: "B"); b.category = "ensayo"
        var c = Book(title: "C"); c.category = "  novela "
        let d = Book(title: "D")
        return [a, b, c, d]
    }

    // MARK: - Categoría de un libro

    @Test func unLibroNuevoNoTieneCategoria() {
        let libro = Book(title: "Dune")
        #expect(libro.category == nil)
        #expect(libro.categoryName == nil)
    }

    @Test func categoryNameQuitaEspaciosSobrantes() {
        var libro = Book(title: "Dune")
        libro.category = "  Ciencia ficción  "
        #expect(libro.categoryName == "Ciencia ficción")
    }

    @Test func unaCategoriaVaciaOSoloEspaciosEsSinCategoria() {
        var libro = Book(title: "Dune")
        libro.category = ""
        #expect(libro.categoryName == nil)
        libro.category = "   "
        #expect(libro.categoryName == nil)
    }

    // MARK: - Lista de categorías

    @Test func lasCategoriasSeListanSinRepetirYOrdenadas() {
        #expect(Book.categories(in: biblioteca()) == ["ensayo", "Novela"])
    }

    @Test func sinLibrosNiCategoriasLaListaEstaVacia() {
        #expect(Book.categories(in: []).isEmpty)
        #expect(Book.categories(in: [Book(title: "Sin")]).isEmpty)
    }

    @Test func seConservaLaPrimeraEscrituraDeUnaCategoriaRepetida() {
        var a = Book(title: "A"); a.category = "Novela"
        var b = Book(title: "B"); b.category = "NOVELA"
        #expect(Book.categories(in: [a, b]) == ["Novela"])
    }

    @Test func cuentaLosLibrosDeCadaCategoria() {
        let cuentas = Book.categoryCounts(in: biblioteca())
        #expect(cuentas["novela"] == 2)
        #expect(cuentas["ensayo"] == 1)
        #expect(cuentas.count == 2)
    }

    // MARK: - Filtro

    @Test func todasNoFiltraNada() {
        let libros = biblioteca()
        #expect(Book.filter(libros, by: .all).map(\.title) == ["A", "B", "C", "D"])
    }

    @Test func filtrarPorCategoriaNoDistingueMayusculasNiEspacios() {
        let libros = biblioteca()
        #expect(Book.filter(libros, by: .category("Novela")).map(\.title) == ["A", "C"])
        #expect(Book.filter(libros, by: .category("ENSAYO")).map(\.title) == ["B"])
    }

    @Test func filtrarSinCategoriaDejaSoloLosQueNoTienen() {
        #expect(Book.filter(biblioteca(), by: .uncategorized).map(\.title) == ["D"])
    }

    @Test func filtrarPorUnaCategoriaQueNoExisteDejaLaListaVacia() {
        #expect(Book.filter(biblioteca(), by: .category("Poesía")).isEmpty)
    }

    @Test func filtrarConservaElOrdenOriginal() {
        let libros = biblioteca()
        #expect(Book.filter(libros, by: .category("novela")).map(\.title) == ["A", "C"])
    }

    @Test func losTitulosDelSelectorSonLegibles() {
        #expect(CategoryFilter.all.title == "Todas")
        #expect(CategoryFilter.uncategorized.title == "Sin categoría")
        #expect(CategoryFilter.category("Novela").title == "Novela")
    }

    // MARK: - Persistencia

    @Test func laCategoriaSobreviveAGuardarYLeer() throws {
        var libro = Book(title: "Dune")
        libro.category = "Ciencia ficción"
        let data = try JSONEncoder().encode(libro)
        let leido = try JSONDecoder().decode(Book.self, from: data)
        #expect(leido.category == "Ciencia ficción")
    }

    @Test func unJsonSinCategoriaSeLeeSinCategoria() throws {
        let json = Data(#"{"title": "Antiguo"}"#.utf8)
        #expect(try JSONDecoder().decode(Book.self, from: json).category == nil)
    }

    @Test func clasificarUnLibroDesdeElViewModelSeConserva() async {
        let viewModel = LibraryViewModel(storageProvider: MockStorageProvider())
        await viewModel.loadBooks()
        var libro = viewModel.books[0]
        libro.category = "Novela"
        viewModel.updateBook(libro)
        #expect(viewModel.books[0].categoryName == "Novela")
        #expect(Book.filter(viewModel.books, by: .category("novela")).count == 1)
    }
}
#endif
