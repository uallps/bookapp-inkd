#if Progreso
import Foundation
import Observation

/// F1: ViewModel del progreso de lectura. Es independiente de `LibraryViewModel`:
/// guarda el progreso de cada libro (unido por id) en su propio almacenamiento.
/// Lo crea la app y llega a las vistas por el entorno, como `AppConfig`.
@Observable
final class ProgressViewModel {
    /// El progreso guardado, una entrada por libro que tenga algo apuntado. Cada cambio se guarda.
    private(set) var entries: [BookProgress] = [] {
        didSet { save() }
    }

    @ObservationIgnored private let storageProvider: ProgressStorageProvider
    @ObservationIgnored private var loaded = false

    /// Por defecto guarda en `progress.json`; en pruebas se le pasa un `MockProgressStorageProvider`.
    init(storageProvider: ProgressStorageProvider = JSONProgressStorageProvider()) {
        self.storageProvider = storageProvider
        _Concurrency.Task { await loadProgress() }
    }

    /// Carga el progreso guardado, solo la primera vez que se llama.
    /// Si aún no hay fichero, no hay progreso: la lista se queda vacía.
    func loadProgress() async {
        guard !loaded else { return }
        loaded = true
        do {
            entries = try await storageProvider.loadProgress()
        } catch {
            print("No se ha cargado el progreso: \(error)")
        }
    }

    /// El progreso de un libro, si tiene algo apuntado.
    func progress(for bookID: UUID) -> BookProgress? {
        entries.first { $0.bookID == bookID }
    }

    /// Guarda el progreso de un libro con las reglas de `BookProgress.normalized()`.
    /// Si queda vacío (sin total y en la página 0) se quita su entrada.
    /// Se prepara la lista entera y se asigna una vez: un solo cambio, un solo guardado.
    func update(_ progress: BookProgress) {
        let progress = progress.normalized()
        var updated = entries
        if let index = updated.firstIndex(where: { $0.bookID == progress.bookID }) {
            if progress.isEmpty {
                updated.remove(at: index)
            } else {
                updated[index] = progress
            }
        } else if !progress.isEmpty {
            updated.append(progress)
        }
        guard updated != entries else { return }
        entries = updated
    }

    /// Quita el progreso de un libro (al borrar el libro de la biblioteca).
    func removeProgress(for bookID: UUID) {
        guard progress(for: bookID) != nil else { return }
        entries.removeAll { $0.bookID == bookID }
    }

    private func save() {
        let entries = entries
        _Concurrency.Task {
            do {
                try await storageProvider.saveProgress(entries)
            } catch {
                print("No se ha guardado el progreso: \(error)")
            }
        }
    }
}
#endif
