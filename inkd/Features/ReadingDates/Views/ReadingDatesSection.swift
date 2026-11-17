#if FechasLectura
import SwiftUI

/// Estado de la sección de fechas. Lo guarda `BookDetailView` en un `@State`
/// (ver `NotesDraft`: en Windows, una vista con `@State` dentro del detalle mide 0).
struct ReadingDatesDraft {
    /// Se ha intentado dejar el fin antes del inicio (el cambio no se guardó).
    var invalidRange = false
}

/// O2: sección «Fechas de lectura» del detalle de un libro. Las fechas se ponen solas al
/// cambiar el estado (lo hace el ViewModel); aquí se pueden ver y corregir.
struct ReadingDatesSection: View {
    @Binding var book: Book
    @Binding var draft: ReadingDatesDraft

    var body: some View {
        Section(header: Text("Fechas de lectura")) {
            if book.startedAt == nil {
                Text("Se apuntan solas al marcar el libro como «Leyendo» o «Leído».")
                    .inkdCaption()
            }
            if book.startedAt != nil {
                DatePicker("Empezado", selection: startedAt, displayedComponents: .date)
            }
            if book.finishedAt != nil {
                DatePicker("Terminado", selection: finishedAt, displayedComponents: .date)
            }
            if draft.invalidRange {
                Text("La fecha de fin no puede ser anterior a la de inicio")
                    .inkdCaption(color: .red)
            }
        }
    }

    private var startedAt: Binding<Date> {
        Binding(
            get: { book.startedAt ?? Date() },
            set: { draft.invalidRange = !book.setStartedAt($0) }
        )
    }

    private var finishedAt: Binding<Date> {
        Binding(
            get: { book.finishedAt ?? Date() },
            set: { draft.invalidRange = !book.setFinishedAt($0) }
        )
    }
}
#endif
