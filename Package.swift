// swift-tools-version: 6.2
// Paquete para Linux y Windows. Compila la MISMA carpeta inkd/ que usa Xcode
// (en Mac se abre inkd.xcodeproj y se usa el SwiftUI de Apple).
import PackageDescription

#if os(Linux)
let backend: Target.Dependency = .product(name: "BackendGTK4", package: "SwiftOpenUI")
#elseif os(Windows)
let backend: Target.Dependency = .product(name: "BackendWin32", package: "SwiftOpenUI")
#else
let backend: Target.Dependency? = nil
#endif

// Mismos ajustes de Swift para la app y para los tests (la app es MainActor por defecto).
let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v5),
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "inkd",
    // Productos de la línea: cada trait activo es una variable de compilación (#if Notas).
    // En Xcode, el mismo papel lo cumple un target por producto («inkd Notas»…).
    // Se combinan con comas: swift run --traits Notas,Prestamos,FechasLectura inkd
    traits: [
        .trait(name: "Notas", description: "F2: notas y citas personales de cada libro"),
        .trait(name: "Prestamos", description: "Original: a quién se ha prestado un libro y desde cuándo"),
        .trait(name: "FechasLectura", description: "Original: fechas de inicio y fin de lectura, automáticas"),
    ],
    dependencies: [
        .package(url: "https://github.com/uallps/SwiftOpenUI.git", branch: "uallps"),
    ],
    targets: [
        // Sustituye al SwiftUI de Apple: `import SwiftUI` trae SwiftOpenUI y su backend.
        .target(
            name: "SwiftUI",
            dependencies: [.product(name: "SwiftOpenUI", package: "SwiftOpenUI")] + [backend].compactMap { $0 },
            path: "Compat/SwiftUI"
        ),
        // Mismos ajustes de Swift que el proyecto de Xcode.
        .executableTarget(
            name: "inkd",
            dependencies: ["SwiftUI"],
            path: "inkd",
            exclude: ["Assets.xcassets"],
            swiftSettings: swiftSettings
        ),
        // Pruebas unitarias (Swift Testing). Las de cada característica van dentro de su `#if`:
        //   swift test                                  → núcleo
        //   swift test --traits Notas                   → núcleo + esa característica
        .testTarget(
            name: "inkdTests",
            dependencies: ["inkd"],
            path: "Tests/inkdTests",
            swiftSettings: swiftSettings
        ),
    ]
)
