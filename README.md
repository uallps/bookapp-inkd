# inkd

App de gestión de libros desarrollada como línea de productos software en la asignatura
Líneas de Productos Software (UAL), curso 2026-27. Parte de la plantilla TaskApp del profesor.

El mismo código de la carpeta `inkd/` funciona en los tres sistemas:

| Sistema | Cómo se ejecuta | Interfaz |
|---|---|---|
| macOS | Abrir `inkd.xcodeproj` en Xcode y pulsar ▶ | SwiftUI de Apple |
| Linux | `swift run inkd` (necesita `libgtk-4-dev` y `libfontconfig-dev`) | [SwiftOpenUI](https://github.com/uallps/SwiftOpenUI) con GTK 4 |
| Windows | `swift run inkd` | SwiftOpenUI con Win32 |

En Linux y Windows, `Package.swift` añade un módulo llamado `SwiftUI` (carpeta `Compat/`)
que reexporta SwiftOpenUI, así que `import SwiftUI` funciona sin cambiar el código.

## Productos

| Producto | Xcode (Mac) | Linux y Windows |
|---|---|---|
| Base (núcleo) | scheme `inkd` | `swift run inkd` |
| Notas y citas (F2) | scheme `inkd Notas` | `swift run --traits Notas inkd` |
| Préstamos | scheme `inkd Prestamos` | `swift run --traits Prestamos inkd` |
| Fechas de lectura | scheme `inkd FechasLectura` | `swift run --traits FechasLectura inkd` |
| Completo | scheme `inkd Completo` | `swift run --traits Notas,Prestamos,FechasLectura inkd` |

Cada característica opcional añade su trait en `Package.swift` y un target en Xcode con el
trait en *Active Compilation Conditions*.
