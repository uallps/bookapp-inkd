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
| Categorías (F3) | — (solo en `Completo`) | `swift run --traits Categorias inkd` |
| Préstamos | scheme `inkd Prestamos` | `swift run --traits Prestamos inkd` |
| Fechas de lectura | scheme `inkd FechasLectura` | `swift run --traits FechasLectura inkd` |
| Completo | scheme `inkd Completo` | `swift run --traits Notas,Categorias,Prestamos,FechasLectura inkd` |

Cada característica opcional añade su trait en `Package.swift` y un target en Xcode con el
trait en *Active Compilation Conditions*.

## Almacenamiento (desde la sesión 7)

Los libros se guardan detrás del protocolo `StorageProvider`, con dos alternativas (solo una activa):

| Alternativa | Dónde | Cómo se elige |
|---|---|---|
| JSON | `books.json` en la carpeta Documentos | Por defecto, en los tres sistemas |
| SwiftData | `inkd.store` en Application Support | Ajustes → Almacenamiento (solo macOS e iOS) |

SwiftData solo existe en los sistemas de Apple: su código está dentro de `#if canImport(SwiftData)`,
así que en Linux y Windows no se compila y la app guarda siempre en JSON.

## Pruebas

Pruebas unitarias con Swift Testing en `Tests/inkdTests/`. Las del núcleo siempre se
ejecutan; las de cada característica están dentro de su `#if` y solo con su trait:

```sh
swift test                                              # núcleo
swift test --traits Notas,Categorias                    # núcleo + F2 + F3
swift test --traits Notas,Categorias,Prestamos,FechasLectura   # todo
```

La CI las ejecuta en Linux y Windows en cada push. Las pruebas del almacenamiento usan
`MockStorageProvider` (o un fichero temporal con nombre único) y nunca tocan tu `books.json`.

## Flujo de trabajo con Git

El historial de `main` es **lineal**: sin commits de merge. Así, cuando algo falla, se ve
en qué commit exacto empezó (`git bisect`) y la CI marca ese commit en rojo.

1. Una rama corta por tarea (`feature/…`, `fix/…`), creada desde `main` actualizado.
2. Commits pequeños y atómicos, con prefijo `feat:`, `fix:`, `test:` o `ci:`. Cada commit
   compila y pasa los tests (el código y sus pruebas van en el mismo commit).
3. Antes de integrar, se pone la rama al día con `git pull --rebase origin main`
   (no `git merge main`) y se vuelve a pasar `swift test`.
4. En GitHub, los PR se integran con **Rebase and merge** (o *Squash*), nunca con
   *Create a merge commit*. Ajuste recomendado: Settings → Rules → *Require linear history*.
5. Un fallo se arregla con un commit `fix:` que añade primero el test que lo reproduce.
