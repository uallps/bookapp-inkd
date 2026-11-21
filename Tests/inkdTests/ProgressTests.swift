#if Progreso
import Foundation
import Testing
@testable import inkd

/// F1 Progreso: porcentaje, reglas de las páginas, resumen de la fila, lectura de los campos
/// y el ViewModel del progreso con su almacenamiento propio.
/// Solo se compilan con el trait `Progreso` (swift test --traits Progreso).
struct ProgressTests {
    private let libro = UUID()

    // MARK: - Porcentaje

    @Test func porcentajeConTotalValido() {
        let progreso = BookProgress(bookID: libro, totalPages: 300, currentPage: 120)
        #expect(progreso.percentage == 40)
    }

    @Test func porcentajeRedondeaHaciaAbajo() {
        let progreso = BookProgress(bookID: libro, totalPages: 3, currentPage: 2)
        #expect(progreso.percentage == 66)
    }

    @Test func sinTotalNoHayPorcentaje() {
        let progreso = BookProgress(bookID: libro, totalPages: nil, currentPage: 50)
        #expect(progreso.percentage == nil)
    }

    @Test func conTotalCeroNoHayPorcentaje() {
        let progreso = BookProgress(bookID: libro, totalPages: 0, currentPage: 0)
        #expect(progreso.percentage == nil)
    }

    @Test func enLaUltimaPaginaEsElCienPorCien() {
        let progreso = BookProgress(bookID: libro, totalPages: 250, currentPage: 250)
        #expect(progreso.percentage == 100)
    }

    // MARK: - Reglas (normalized)

    @Test func unTotalNegativoOCeroSeQuita() {
        #expect(BookProgress(bookID: libro, totalPages: -5).normalized().totalPages == nil)
        #expect(BookProgress(bookID: libro, totalPages: 0).normalized().totalPages == nil)
    }

    @Test func laPaginaNuncaEsNegativa() {
        let progreso = BookProgress(bookID: libro, totalPages: 100, currentPage: -3).normalized()
        #expect(progreso.currentPage == 0)
    }

    @Test func laPaginaNoSuperaElTotal() {
        let progreso = BookProgress(bookID: libro, totalPages: 100, currentPage: 150).normalized()
        #expect(progreso.currentPage == 100)
    }

    @Test func bajarElTotalRecortaLaPagina() {
        var progreso = BookProgress(bookID: libro, totalPages: 300, currentPage: 200)
        progreso.totalPages = 150
        #expect(progreso.normalized().currentPage == 150)
    }

    @Test func sinTotalLaPaginaNoSeRecorta() {
        let progreso = BookProgress(bookID: libro, totalPages: nil, currentPage: 900).normalized()
        #expect(progreso.currentPage == 900)
    }

    @Test func vacioSoloSinTotalYEnLaPaginaCero() {
        #expect(BookProgress(bookID: libro).isEmpty)
        #expect(BookProgress(bookID: libro, currentPage: 1).isEmpty == false)
        #expect(BookProgress(bookID: libro, totalPages: 10).isEmpty == false)
    }

    // MARK: - Resumen de la fila

    @Test func resumenConTotal() {
        let progreso = BookProgress(bookID: libro, totalPages: 300, currentPage: 120)
        #expect(progreso.summary == "Pág. 120 de 300 · 40 %")
    }

    @Test func resumenSinTotal() {
        let progreso = BookProgress(bookID: libro, totalPages: nil, currentPage: 120)
        #expect(progreso.summary == "Pág. 120")
    }

    @Test func sinNadaQueMostrarNoHayResumen() {
        #expect(BookProgress(bookID: libro).summary == nil)
    }

    // MARK: - Lectura de los campos

    @Test func parsePagesConTextoValido() {
        #expect(BookProgress.parsePages("120") == 120)
        #expect(BookProgress.parsePages("0") == 0)
    }

    @Test func parsePagesQuitaEspacios() {
        #expect(BookProgress.parsePages("  42 ") == 42)
    }

    @Test func parsePagesRechazaVacioNegativoYTexto() {
        #expect(BookProgress.parsePages("") == nil)
        #expect(BookProgress.parsePages("   ") == nil)
        #expect(BookProgress.parsePages("-3") == nil)
        #expect(BookProgress.parsePages("abc") == nil)
        #expect(BookProgress.parsePages("12a") == nil)
    }

    // MARK: - ProgressViewModel

    /// Un ViewModel ya cargado con el almacenamiento en memoria (uno nuevo si no se pasa).
    /// El Mock se crea dentro de la función y no como valor por defecto del parámetro:
    /// un valor por defecto se evalúa fuera del MainActor y Swift avisa.
    private func makeViewModel(_ almacen: MockProgressStorageProvider? = nil) async -> ProgressViewModel {
        let viewModel = ProgressViewModel(storageProvider: almacen ?? MockProgressStorageProvider())
        await viewModel.loadProgress()
        return viewModel
    }

    @Test func alCargarSinDatosNoHayProgreso() async {
        let viewModel = await makeViewModel()
        #expect(viewModel.entries.isEmpty)
        #expect(viewModel.progress(for: libro) == nil)
    }

    @Test func updateAñadeElProgreso() async {
        let viewModel = await makeViewModel()
        viewModel.update(BookProgress(bookID: libro, totalPages: 300, currentPage: 10))
        #expect(viewModel.progress(for: libro)?.currentPage == 10)
        #expect(viewModel.entries.count == 1)
    }

    @Test func updateSustituyeElProgresoDelMismoLibro() async {
        let viewModel = await makeViewModel()
        viewModel.update(BookProgress(bookID: libro, totalPages: 300, currentPage: 10))
        viewModel.update(BookProgress(bookID: libro, totalPages: 300, currentPage: 90))
        #expect(viewModel.entries.count == 1)
        #expect(viewModel.progress(for: libro)?.currentPage == 90)
    }

    @Test func updateAplicaLasReglas() async {
        let viewModel = await makeViewModel()
        viewModel.update(BookProgress(bookID: libro, totalPages: 100, currentPage: 400))
        #expect(viewModel.progress(for: libro)?.currentPage == 100)
    }

    @Test func updateConDatosVaciosBorraLaEntrada() async {
        let viewModel = await makeViewModel()
        viewModel.update(BookProgress(bookID: libro, totalPages: 300, currentPage: 10))
        viewModel.update(BookProgress(bookID: libro, totalPages: nil, currentPage: 0))
        #expect(viewModel.progress(for: libro) == nil)
        #expect(viewModel.entries.isEmpty)
    }

    @Test func elProgresoDeUnLibroNoAfectaAOtro() async {
        let viewModel = await makeViewModel()
        let otro = UUID()
        viewModel.update(BookProgress(bookID: libro, currentPage: 5))
        viewModel.update(BookProgress(bookID: otro, currentPage: 7))
        #expect(viewModel.progress(for: libro)?.currentPage == 5)
        #expect(viewModel.progress(for: otro)?.currentPage == 7)
    }

    @Test func removeProgressQuitaSoloEseLibro() async {
        let viewModel = await makeViewModel()
        let otro = UUID()
        viewModel.update(BookProgress(bookID: libro, currentPage: 5))
        viewModel.update(BookProgress(bookID: otro, currentPage: 7))
        viewModel.removeProgress(for: libro)
        #expect(viewModel.progress(for: libro) == nil)
        #expect(viewModel.progress(for: otro) != nil)
    }

    @Test func loGuardadoSeRecuperaEnOtroViewModel() async throws {
        let almacen = MockProgressStorageProvider()
        let primero = await makeViewModel(almacen)
        primero.update(BookProgress(bookID: libro, totalPages: 300, currentPage: 120))
        // El guardado es asíncrono (una Task): se deja correr antes de comprobar.
        try await Task.sleep(nanoseconds: 200_000_000)
        let segundo = await makeViewModel(almacen)
        #expect(segundo.progress(for: libro) == BookProgress(bookID: libro, totalPages: 300, currentPage: 120))
    }

    @Test func elProgresoSobreviveAGuardarYLeerEnJSON() throws {
        let progreso = BookProgress(bookID: libro, totalPages: 300, currentPage: 120)
        let data = try JSONEncoder().encode([progreso])
        let leido = try JSONDecoder().decode([BookProgress].self, from: data)
        #expect(leido == [progreso])
    }
}
#endif
