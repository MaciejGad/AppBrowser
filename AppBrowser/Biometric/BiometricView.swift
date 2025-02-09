import SwiftUI
import LocalAuthentication

/// Widok biometryczny, który przyjmuje główny widok aplikacji jako parametr (closure)
struct BiometricView<Content: View>: View {
    /// Główny widok, który chcemy pokazać po udanym uwierzytelnieniu
    let mainContent: () -> Content
    
    @EnvironmentObject private var viewModel: BiometricViewModel
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            mainContent()
            if viewModel.showOverlay {
                SecureOverlayView()
            }
        }
        // Przy starcie widoku próbujemy automatycznie przeprowadzić autentykację
        .onAppear(perform: viewModel.authenticate)
        // Monitorujemy zmiany stanu aplikacji (scenePhase), aby przy powrocie sprawdzić, czy minęło 30 sekund
        .onChange(of: scenePhase) { newPhase in
            viewModel.onChange(scenePhase: newPhase)
        }
    }
}
