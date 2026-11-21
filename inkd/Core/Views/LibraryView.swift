import SwiftUI

/// La biblioteca: formulario de alta arriba y la lista de libros debajo.
struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    /// El núcleo no la usa; las características la leen dentro de su `#if` (ver `rowView`).
    @Environment(AppConfig.self) private var config

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
        NavigationLink(destination: BookDetailView(book: binding(for: book))) {
            rowView(for: book)
            .contextMenu {
                Button("Eliminar libro") {
                    viewModel.removeBook(id: book.id)
                }
            }
        }
    }

    /// La fila con los flags de AppConfig. Se rellena paso a paso porque cada flag solo
    /// existe en su producto, y `#if` no puede ir entre los argumentos de una llamada.
    private func rowView(for book: Book) -> BookRowView {
        var row = BookRowView(
            book: book,
            advanceStatus: { viewModel.advanceStatus(id: book.id) }
        )
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
}
