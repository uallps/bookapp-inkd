import SwiftUI

/// Detalle de un libro. Recibe un enlace (@Binding) al libro de la biblioteca:
/// lo que se edita aquí cambia el libro del ViewModel, sin copias.
struct BookDetailView: View {
    @Binding var book: Book

    /// Lo que hay escrito en el campo del título. Mientras sea válido se copia al libro;
    /// si se deja vacío, el libro conserva su título y se muestra un aviso.
    /// `nil` = aún no se ha tocado, el campo muestra el título del libro.
    @State private var titleDraft: String?

    // Lo que se está escribiendo en las secciones de las características. Vive aquí y no en
    // cada sección porque, en Windows, una vista con @State dentro de otra con @State se
    // queda con 0 de alto (ver `NotesDraft`).
#if FechasLectura
    @State private var readingDatesDraft = ReadingDatesDraft()
#endif
#if Prestamos
    @State private var loanDraft = LoanDraft()
#endif
#if Notas
    @State private var notesDraft = NotesDraft()
#endif

    var body: some View {
        Form {
            Section(header: Text("Libro")) {
                TextField("Título", text: titleText)
                if titleIsEmpty {
                    Text("El título no puede estar vacío")
                        .inkdCaption(color: .red)
                }
                TextField("Autor (opcional)", text: authorText)
                Picker("Estado", selection: $book.status) {
                    ForEach(ReadingStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }
            // Secciones de las características: reciben el mismo enlace al libro.
#if FechasLectura
            ReadingDatesSection(book: $book, draft: $readingDatesDraft)
#endif
#if Prestamos
            LoanSection(book: $book, draft: $loanDraft)
#endif
#if Notas
            NotesSection(book: $book, draft: $notesDraft)
#endif
        }
        .navigationTitle(book.title)
    }

    private var titleIsEmpty: Bool {
        guard let titleDraft else { return false }
        return Book.cleanTitle(titleDraft) == nil
    }

    private var titleText: Binding<String> {
        Binding(
            get: { titleDraft ?? book.title },
            set: { newValue in
                titleDraft = newValue
                if Book.cleanTitle(newValue) != nil {
                    book.title = newValue
                }
            }
        )
    }

    /// El autor es opcional (`String?`) y el campo de texto necesita un `String`.
    private var authorText: Binding<String> {
        Binding(
            get: { book.author ?? "" },
            set: { book.author = $0 }
        )
    }
}
