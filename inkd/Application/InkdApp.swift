import SwiftUI

@main
struct InkdApp: App {
    /// Una sola configuración para toda la app: la comparten Biblioteca y Ajustes.
    @State private var config = AppConfig()
    @State private var selection: String? = "biblioteca"

    var body: some Scene {
        WindowGroup {
#if os(iOS)
            TabView {
                LibraryView(storageProvider: config.storageType.makeProvider())
                    // Las pestañas conservan su estado: al cambiar de almacenamiento se rehace la lista.
                    .id(config.storageType)
                    .tabItem { Label("Biblioteca", systemImage: "books.vertical") }
                SettingsView()
                    .tabItem { Label("Ajustes", systemImage: "gearshape") }
            }
            .environment(config)
#else
            NavigationSplitView {
                List(selection: $selection) {
                    NavigationLink(value: "biblioteca") {
                        Label("Biblioteca", systemImage: "books.vertical")
                    }
                    NavigationLink(value: "ajustes") {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                }
            } detail: {
                switch selection {
                case "biblioteca":
                    // La biblioteca se crea al elegirla, con el almacenamiento elegido en Ajustes.
                    LibraryView(storageProvider: config.storageType.makeProvider())
                case "ajustes":
                    SettingsView()
                default:
                    Text("Elige una opción")
                }
            }
            .environment(config)
#endif
        }
    }
}
