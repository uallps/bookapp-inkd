import SwiftUI

// El tema de la app: colores, iconos y estilos en un solo sitio, añadidos con extensiones.
// Para cambiar el aspecto se toca este fichero, no las vistas.

extension Color {
    /// Color principal de inkd.
    static let inkdAccent = Color(red: 0.19, green: 0.38, blue: 0.58)
}

/// Estilo del texto secundario de las filas (autor, estado).
struct CaptionStyle: ViewModifier {
    var color: Color = .secondary

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(color)
    }
}

extension View {
    /// Aplica el estilo de texto secundario: `Text("…").inkdCaption()`,
    /// o con otro color: `.inkdCaption(color: .red)`.
    func inkdCaption(color: Color = .secondary) -> some View {
        modifier(CaptionStyle(color: color))
    }
}

extension ReadingStatus {
    /// Icono de cada estado (nombres de SF Symbols; SwiftOpenUI los traduce en Windows y Linux).
    var systemImage: String {
        switch self {
        case .toRead: return "circle"
        case .reading: return "bookmark"
        case .read: return "checkmark.circle.fill"
        }
    }

    /// Color de cada estado.
    var color: Color {
        switch self {
        case .toRead: return .secondary
        case .reading: return .orange
        case .read: return .inkdAccent
        }
    }
}

#if Notas
extension NoteKind {
    /// Color del tipo de anotación. Solo existe en los productos con notas.
    var color: Color {
        switch self {
        case .note: return .secondary
        case .quote: return .inkdAccent
        }
    }
}
#endif

#if Prestamos
extension Color {
    /// Color del aviso «Prestado a…». Solo existe en los productos con préstamos.
    static let inkdLoan = Color.purple
}
#endif
