#if Categorias
import SwiftUI

/// F3: sección «Categoría» del detalle de un libro. Un solo campo de texto: la categoría
/// se guarda en el libro (`Book.category`) a través del mismo `@Binding` que usa el detalle,
/// así que cada cambio pasa por el ViewModel y se guarda. Vaciar el campo quita la categoría.
/// No tiene estado propio (ver `NotesDraft`: en Windows una vista con `@State` dentro del
/// detalle mide 0 de alto).
struct CategorySection: View {
    @Binding var book: Book

    var body: some View {
        Section(header: Text("Categoría")) {
            TextField("Categoría (opcional)", text: categoryText)
            Text("Los libros con la misma categoría se pueden filtrar desde la biblioteca.")
                .inkdCaption()
        }
    }

    /// La categoría es opcional (`String?`) y el campo de texto necesita un `String`.
    private var categoryText: Binding<String> {
        Binding(
            get: { book.category ?? "" },
            set: { book.category = $0 }
        )
    }
}
#endif
