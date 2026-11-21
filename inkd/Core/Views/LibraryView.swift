import SwiftUI

/// La biblioteca: formulario de alta arriba y la lista de libros debajo.
struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    /// El núcleo no la usa; las características la leen dentro de su `#if` (ver `rowView`).
    @Environment(AppConfig.self) private var config
#if Progreso
    /// F1: el progreso de los libros, con su propio ViewModel (lo crea la app).
    @Environment(ProgressViewModel.self) private var progressStore
#endif

    /// Lo que se escribe en el formulario de alta, antes de añadir el libro.
    @State private var newTitle = ""
    @State private var newAuthor = ""
#if Categorias
    /// F3: el filtro de categoría elegido en la lista.
    @State private var categoryFilter: CategoryFilter = .all
#endif

    /// Quien crea la biblioteca decide dónde se guardan los libros.
    init(storageProvider: StorageProvider = JSONStorageProvider()) {
        _viewModel = State(wrappedValue: LibraryViewModel(storageProvider: storageProvider))
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Nuevo libro")) {
                    TextField("Título", text: $newTitle)
                    TextField("Autor (opcional)", text: $newAuthor)
                    Button("Añadir libro") {
                        addBook()
                    }
                    .disabled(Book.cleanTitle(newTitle) == nil)
                }
#if Categorias
                categoryFilterSection
#endif
                Section(header: Text("Mis libros")) {
                    ForEach(visibleBooks) { book in
                        bookRow(book: book)
                    }
#if Categorias
                    if visibleBooks.isEmpty && !viewModel.books.isEmpty {
                        Text("No hay libros en esta categoría.")
                            .inkdCaption()
                    }
#endif
                }
            }
            .navigationTitle("Biblioteca")
        }
    }

    /// Los libros que se muestran: todos, o los que pasan el filtro de categoría (F3).
    private var visibleBooks: [Book] {
#if Categorias
        return Book.filter(viewModel.books, by: activeFilter)
#else
        return viewModel.books
#endif
    }

#if Categorias
    /// Las opciones del filtro: Todas, Sin categoría y cada categoría que hay en la biblioteca.
    private var filterOptions: [CategoryFilter] {
        [.all, .uncategorized] + Book.categories(in: viewModel.books).map { .category($0) }
    }

    /// El filtro elegido, o «Todas» si su categoría ya no existe (por ejemplo, tras borrar el último libro).
    private var activeFilter: CategoryFilter {
        filterOptions.contains(categoryFilter) ? categoryFilter : .all
    }

    private var categoryFilterSection: some View {
        Section(header: Text("Filtrar por categoría")) {
            Picker("Categoría", selection: $categoryFilter) {
                ForEach(filterOptions, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }
        }
    }
#endif

    /// Da de alta el libro del formulario y lo vacía. El ViewModel vuelve a comprobar el título.
    private func addBook() {
        if viewModel.addBook(title: newTitle, author: newAuthor) {
            newTitle = ""
            newAuthor = ""
        }
    }

    /// Una fila: enlace al detalle del libro, con menú contextual para borrarlo.
    private func bookRow(book: Book) -> some View {
#if Progreso
        // F1: el clic no puede leer el entorno (en Windows cierra la app): se captura antes.
        let store = progressStore
#endif
        return NavigationLink(destination: detailView(for: book)) {
            rowView(for: book)
            .contextMenu {
                Button("Eliminar libro") {
                    viewModel.removeBook(id: book.id)
#if Progreso
                    // El progreso del libro se borra con él, aunque el flag esté apagado:
                    // el flag solo oculta la interfaz, los datos siguen ahí.
                    store.removeProgress(for: book.id)
#endif
                }
            }
        }
    }

    /// El detalle del libro. Se rellena paso a paso, como `rowView`, porque `#if` no puede
    /// ir entre los argumentos de una llamada.
    private func detailView(for book: Book) -> BookDetailView {
        var detail = BookDetailView(book: binding(for: book))
#if Progreso
        if config.showProgress {
            detail.progress = progressBinding(for: book)
        }
#endif
        return detail
    }

    /// La fila con los flags de AppConfig. Se rellena paso a paso porque cada flag solo
    /// existe en su producto, y `#if` no puede ir entre los argumentos de una llamada.
    private func rowView(for book: Book) -> BookRowView {
        var row = BookRowView(
            book: book,
            advanceStatus: { viewModel.advanceStatus(id: book.id) }
        )
#if Progreso
        row.showProgress = config.showProgress
        row.progress = progressStore.progress(for: book.id)
#endif
#if Categorias
        row.showCategories = config.showCategories
#endif
#if Notas
        row.showNotes = config.showNotes
#endif
#if Prestamos
        row.showLoans = config.showLoans
#endif
#if FechasLectura
        row.showReadingDates = config.showReadingDates
#endif
        return row
    }

    /// Un enlace (Binding) para que el detalle edite el libro. No toca los datos:
    /// leer y escribir se traducen a métodos del ViewModel (que valida el título).
    private func binding(for book: Book) -> Binding<Book> {
        Binding(
            get: { viewModel.book(id: book.id) ?? book },
            set: { viewModel.updateBook($0) }
        )
    }

#if Progreso
    /// F1: enlace al progreso de un libro para el detalle. Leer y escribir van al ViewModel
    /// del progreso (que aplica las reglas y guarda). Se captura el objeto antes porque el
    /// `set` se ejecuta al escribir, y leer el entorno ahí cierra la app en Windows.
    private func progressBinding(for book: Book) -> Binding<BookProgress> {
        let store = progressStore
        return Binding(
            get: { store.progress(for: book.id) ?? BookProgress(bookID: book.id) },
            set: { store.update($0) }
        )
    }
#endif
}
