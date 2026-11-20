import SwiftUI

/// Pantalla de Ajustes: activa o desactiva las características en ejecución.
/// Cada característica añade aquí su `Toggle` dentro de su `#if`.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config

    var body: some View {
        // El entorno solo se puede leer mientras se dibuja la vista: nos quedamos aquí con el
        // objeto para que los interruptores lo usen al pulsarlos (como `@Bindable var config`
        // en la plantilla; leer `self.config` dentro del clic cierra la app en Windows).
        let config = config
        Form {
            Section(header: Text("Características")) {
                Text("Elige qué información se ve en la lista de libros.")
                    .inkdCaption()
#if FechasLectura
                Toggle("Mostrar fechas de lectura", isOn: Self.flag(config, \.showReadingDates))
#endif
#if Prestamos
                Toggle("Mostrar préstamos", isOn: Self.flag(config, \.showLoans))
#endif
#if Notas
                Toggle("Mostrar notas y citas", isOn: Self.flag(config, \.showNotes))
#endif
            }
        }
        .navigationTitle("Ajustes")
    }

    /// Enlace a un flag de AppConfig: leer y escribir van directamente a la configuración.
    private static func flag(_ config: AppConfig,
                             _ keyPath: ReferenceWritableKeyPath<AppConfig, Bool>) -> Binding<Bool> {
        Binding(
            get: { config[keyPath: keyPath] },
            set: { config[keyPath: keyPath] = $0 }
        )
    }
}
