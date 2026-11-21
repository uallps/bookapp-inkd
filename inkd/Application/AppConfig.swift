import Foundation
import Observation

/// Feature flags en ejecución: qué características muestra la app.
/// Es configuración de la aplicación, no datos de los libros. Cada flag se guarda en
/// UserDefaults al cambiar, así que se conserva al cerrar y volver a abrir la app.
///
/// Como en la plantilla, los flags existen en todos los productos; solo el producto
/// que tiene la característica los usa y muestra su interruptor en Ajustes.
@Observable
final class AppConfig {
    /// F1: mostrar el progreso de lectura en la lista y la sección «Progreso» en el detalle.
    var showProgress: Bool {
        didSet { store(showProgress, forKey: "showProgress") }
    }
    /// F2: mostrar el resumen de notas y citas en la lista.
    var showNotes: Bool {
        didSet { store(showNotes, forKey: "showNotes") }
    }
    /// F3: mostrar la categoría en la lista.
    var showCategories: Bool {
        didSet { store(showCategories, forKey: "showCategories") }
    }
    /// O1: mostrar «Prestado a…» en la lista.
    var showLoans: Bool {
        didSet { store(showLoans, forKey: "showLoans") }
    }
    /// O2: mostrar las fechas de lectura en la lista.
    var showReadingDates: Bool {
        didSet { store(showReadingDates, forKey: "showReadingDates") }
    }

    /// Dónde se guardan los libros. En UserDefaults se guarda su nombre ("JSON", "SwiftData").
    var storageType: StorageType {
        didSet { store(storageType.rawValue, forKey: "storageType") }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // F1 empieza desactivada: la sesión 4 pide declarar los flags comunes apagados.
        // Se enciende en Ajustes y la elección se conserva en UserDefaults.
        showProgress = defaults.object(forKey: "showProgress") as? Bool ?? false
        showNotes = defaults.object(forKey: "showNotes") as? Bool ?? true
        showCategories = defaults.object(forKey: "showCategories") as? Bool ?? true
        showLoans = defaults.object(forKey: "showLoans") as? Bool ?? true
        showReadingDates = defaults.object(forKey: "showReadingDates") as? Bool ?? true
        storageType = StorageType(rawValue: defaults.string(forKey: "storageType") ?? "") ?? .json
    }

    private func store(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
        // En Linux y Windows, UserDefaults escribe en disco más tarde: lo forzamos ya.
        defaults.synchronize()
    }
}
