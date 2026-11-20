#if Prestamos
import SwiftUI

/// Lo que se está escribiendo en la sección de préstamo. Lo guarda `BookDetailView` en un
/// `@State` (ver `NotesDraft`: en Windows, una vista con `@State` dentro del detalle mide 0).
struct LoanDraft {
    /// Nombre escrito en «Prestar a», antes de pulsar «Prestar».
    var borrower = ""
}

/// O1: sección «Préstamo» del detalle de un libro. Si está prestado muestra a quién y
/// desde cuándo, con un botón para marcarlo como devuelto; si no, permite prestarlo.
struct LoanSection: View {
    @Binding var book: Book
    @Binding var draft: LoanDraft

    var body: some View {
        Section(header: Text("Préstamo")) {
            if let person = book.loanedTo {
                Text("Prestado a \(person)")
                DatePicker("Desde", selection: loanDate, displayedComponents: .date)
                Button("Marcar como devuelto") {
                    book.markReturned()
                }
            } else {
                Text("En casa")
                    .inkdCaption()
                TextField("Prestar a", text: $draft.borrower)
                Button("Prestar") {
                    if book.lend(to: draft.borrower) {
                        draft.borrower = ""
                    }
                }
                .disabled(draft.borrower.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    /// La fecha del préstamo. `Book.setLoanDate` no admite fechas futuras.
    private var loanDate: Binding<Date> {
        Binding(
            get: { book.loanDate ?? Date() },
            set: { book.setLoanDate($0) }
        )
    }
}
#endif
