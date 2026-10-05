import SwiftUI

@main
struct GestorFinanceiroApp: App {
    var body: some Scene {
        WindowGroup {
            // A página já respeita a área segura de baixo (env(safe-area-inset-bottom));
            // em cima, a ilha dinâmica fica de fora, com a cor de fundo do app.
            AppWebView()
                .ignoresSafeArea(.container, edges: .bottom)
                .background(Color(uiColor: .fundoDoApp).ignoresSafeArea())
        }
    }
}

extension UIColor {
    /// Mesma cor de fundo do app web (--ground) nos temas claro e escuro.
    static let fundoDoApp = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x08 / 255, green: 0x10 / 255, blue: 0x0c / 255, alpha: 1)
            : UIColor(red: 0xee / 255, green: 0xf2 / 255, blue: 0xef / 255, alpha: 1)
    }
}
