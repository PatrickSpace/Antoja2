import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.965, green: 0.957, blue: 0.925)
    static let surface = Color.white.opacity(0.92)
    static let ink = Color(red: 0.12, green: 0.13, blue: 0.11)
    static let mutedInk = Color(red: 0.39, green: 0.40, blue: 0.34)
    static let accent = Color(red: 0.91, green: 0.34, blue: 0.20)
    static let accentSoft = Color(red: 1.00, green: 0.86, blue: 0.72)
    static let green = Color(red: 0.20, green: 0.56, blue: 0.38)
    static let border = Color.black.opacity(0.08)
}

extension View {
    func antojaCard() -> some View {
        self
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 18, y: 8)
    }
}
