#if Notas
import SwiftUI

/// Lo que se está escribiendo en la sección de notas de un libro: el formulario de alta
/// y los textos que se están editando. Lo guarda `BookDetailView` en un `@State`.
///
/// ¿Por qué no un `@State` en `NotesSection`? En Windows, SwiftOpenUI construye más tarde
/// las vistas con estado (`@State` o un objeto `@Observable` guardado) que están dentro de
/// otra con estado (el detalle) y las deja con 0 píxeles de alto. Con un `struct` que llega
/// por `@Binding`, la sección no tiene estado propio y se dibuja bien en todas partes.
struct NotesDraft {
    var newText = ""
    var newKind: NoteKind = .note
    var newPage = ""
    /// Texto en edición de cada nota, por id. Sin entrada = aún no se ha tocado.
    var editing: [UUID: String] = [:]
}

/// F2: sección «Notas y citas» del detalle de un libro: lista editable y alta de notas.
/// Recibe el libro por `@Binding` (el mismo que el detalle), así que cada cambio
/// pasa por el ViewModel y se guarda.
struct NotesSection: View {
    @Binding var book: Book
    @Binding var draft: NotesDraft

    var body: some View {
        Section(header: Text("Notas y citas")) {
            if book.notes.isEmpty {
                Text("Aún no hay notas para este libro.")
                    .inkdCaption()
            }
            ForEach(book.notes) { note in
                noteRow(note)
            }
            TextField("Nueva nota o cita", text: $draft.newText)
            Picker("Tipo", selection: $draft.newKind) {
                ForEach(NoteKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            TextField("Página (opcional)", text: $draft.newPage)
            Button("Añadir nota") {
                addNote()
            }
            .disabled(Note.cleanText(draft.newText) == nil)
        }
    }

    /// Una nota editable: tipo, página y fecha; su texto; y un botón para borrarla.
    private func noteRow(_ note: Note) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(header(for: note))
                    .inkdCaption(color: note.kind.color)
                Button("Eliminar nota") {
                    draft.editing[note.id] = nil
                    book.removeNote(id: note.id)
                }
            }
            TextField("Texto de la nota", text: textBinding(for: note))
            if let text = draft.editing[note.id], Note.cleanText(text) == nil {
                Text("La nota no puede estar vacía")
                    .inkdCaption(color: .red)
            }
        }
    }

    /// «Cita · pág. 12 · 17 nov 2026».
    private func header(for note: Note) -> String {
        var parts = [note.kind.rawValue]
        if let page = note.page { parts.append("pág. \(page)") }
        parts.append(note.createdAt.formatted(date: .abbreviated, time: .omitted))
        return parts.joined(separator: " · ")
    }

    /// Igual que el título del libro: el campo muestra lo escrito, pero a la nota solo pasa
    /// un texto no vacío (`Book.updateNote` lo vuelve a comprobar).
    private func textBinding(for note: Note) -> Binding<String> {
        Binding(
            get: { draft.editing[note.id] ?? note.text },
            set: { newValue in
                draft.editing[note.id] = newValue
                var edited = note
                edited.text = newValue
                book.updateNote(edited)
            }
        )
    }

    /// Añade la nota del formulario y lo vacía. `Book.addNote` vuelve a comprobar el texto.
    private func addNote() {
        if book.addNote(text: draft.newText, kind: draft.newKind, page: Note.parsePage(draft.newPage)) {
            draft.newText = ""
            draft.newPage = ""
        }
    }
}
#endif
