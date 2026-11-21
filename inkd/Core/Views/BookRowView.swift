import SwiftUI

/// Fila de un libro. No conoce el ViewModel: recibe el libro, los flags y la acción.
struct BookRowView: View {
    let book: Book
    /// Pasa al estado siguiente (Por leer → Leyendo → Leído).
    let advanceStatus: () -> Void

    // Flags de las características (vienen de AppConfig). Cada uno solo existe en su producto.
#if Progreso
    var showProgress = false
    /// F1: el progreso de este libro. La fila recibe el valor, no el ViewModel del progreso.
    var progress: BookProgress?
#endif
#if Categorias
    var showCategories = true
#endif
#if Notas
    var showNotes = true
#endif
#if Prestamos
    var showLoans = true
#endif
#if FechasLectura
    var showReadingDates = true
#endif

    var body: some View {
        HStack {
            Button(action: advanceStatus) {
                Image(systemName: book.status.systemImage)
                    .foregroundColor(book.status.color)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading) {
                Text(book.title)
                if let author = book.author {
                    Text(author)
                        .inkdCaption()
                }
                Text(book.status.rawValue)
                    .inkdCaption(color: book.status.color)
#if Progreso
                if showProgress, let summary = progress?.summary {
                    Text(summary)
                        .inkdCaption()
                }
#endif
#if Categorias
                if showCategories, let category = book.categoryName {
                    Text(category)
                        .inkdCaption()
                }
#endif
#if FechasLectura
                if showReadingDates, let summary = book.readingDatesSummary {
                    Text(summary)
                        .inkdCaption()
                }
#endif
#if Prestamos
                if showLoans, let summary = book.loanSummary {
                    Text(summary)
                        .inkdCaption(color: .inkdLoan)
                }
#endif
#if Notas
                if showNotes, let summary = book.notesSummary {
                    Text(summary)
                        .inkdCaption()
                }
#endif
            }
        }
    }
}
