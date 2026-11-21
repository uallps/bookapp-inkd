#if Progreso
import SwiftUI

/// Lo que se está escribiendo en los campos de la sección de progreso. Lo guarda
/// `BookDetailView` en un `@State` (ver `NotesDraft`: en Windows, una vista con `@State`
/// dentro del detalle mide 0 de alto).
///
/// Mismo criterio que `titleDraft` en el detalle: `nil` = aún no se ha tocado y el campo
/// muestra el valor guardado; si no, muestra lo escrito, aunque no sea válido.
struct ProgressDraft {
    var totalPages: String?
    var currentPage: String?
}

/// F1: sección «Progreso» del detalle de un libro: total de páginas, página actual y
/// porcentaje leído. Recibe el progreso por `@Binding`: cada cambio válido pasa por
/// `ProgressViewModel.update`, que aplica las reglas y lo guarda.
struct ProgressSection: View {
    @Binding var progress: BookProgress
    @Binding var draft: ProgressDraft

    var body: some View {
        Section(header: Text("Progreso")) {
            TextField("Total de páginas (opcional)", text: totalPagesText)
            if totalPagesIsInvalid {
                Text("El total de páginas tiene que ser un número mayor que 0")
                    .inkdCaption(color: .red)
            }
            TextField("Página actual", text: currentPageText)
            if let warning = currentPageWarning {
                Text(warning)
                    .inkdCaption(color: .red)
            }
            if let percentage = progress.percentage {
                Text("Leído: \(percentage) %")
            } else {
                Text("Indica el total de páginas para ver el porcentaje leído.")
                    .inkdCaption()
            }
        }
    }

    // MARK: - Total de páginas

    /// Un total válido se guarda; vaciar el campo quita el total; lo demás no se guarda.
    private var totalPagesText: Binding<String> {
        Binding(
            get: { draft.totalPages ?? progress.totalPages.map(String.init) ?? "" },
            set: { newValue in
                draft.totalPages = newValue
                if Self.isBlank(newValue) {
                    progress.totalPages = nil
                } else if let total = BookProgress.parsePages(newValue), total > 0 {
                    progress.totalPages = total
                } else {
                    return
                }
                // Al cambiar el total la página puede haberse recortado: el campo de la
                // página vuelve a mostrar el valor guardado.
                draft.currentPage = nil
            }
        )
    }

    private var totalPagesIsInvalid: Bool {
        guard let text = draft.totalPages, !Self.isBlank(text) else { return false }
        guard let total = BookProgress.parsePages(text) else { return true }
        return total == 0
    }

    // MARK: - Página actual

    /// La página 0 se muestra como campo vacío; vaciar el campo vuelve a la página 0.
    private var currentPageText: Binding<String> {
        Binding(
            get: { draft.currentPage ?? (progress.currentPage > 0 ? String(progress.currentPage) : "") },
            set: { newValue in
                draft.currentPage = newValue
                if Self.isBlank(newValue) {
                    progress.currentPage = 0
                } else if let page = BookProgress.parsePages(newValue),
                          page <= (progress.totalPages ?? Int.max) {
                    progress.currentPage = page
                }
            }
        )
    }

    /// Por qué no se guarda lo escrito en la página actual, o `nil` si se guarda.
    private var currentPageWarning: String? {
        guard let text = draft.currentPage, !Self.isBlank(text) else { return nil }
        guard let page = BookProgress.parsePages(text) else {
            return "La página actual tiene que ser un número (0 o más)"
        }
        if let total = progress.totalPages, page > total {
            return "La página actual no puede superar el total (\(total))"
        }
        return nil
    }

    private static func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
#endif
