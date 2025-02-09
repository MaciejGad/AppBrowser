import SwiftUI
import LocalAuthentication

final class BiometricViewModel: ObservableObject {
    @Published var isLocked = true
    @Published var showOverlay = true
    @Published var lastAuthenticationDate: Date? = nil
    @Published var errorMessage: String? = nil
    
    let autoAuthentication: Bool
    
    init(autoAuthentication: Bool) {
        self.autoAuthentication = autoAuthentication
    }
    
    /// Funkcja uwierzytelniająca przy użyciu biometrii (Face ID / Touch ID) lub kodu urządzenia
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        let reason: String
        let policy: LAPolicy
        
        // Sprawdzamy, czy urządzenie obsługuje biometrię
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            policy = .deviceOwnerAuthenticationWithBiometrics
            reason = "Potwierdź swoją tożsamość, aby odblokować aplikację."
        } else {
            policy = .deviceOwnerAuthentication
            reason = "Uwierzytelnij się za pomocą kodu, aby odblokować aplikację."
        }
        context.evaluatePolicy(policy, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.isLocked = false
                    self.showOverlay = false
                    self.lastAuthenticationDate = Date()
                    self.errorMessage = nil
                } else {
                    self.errorMessage = authError?.localizedDescription ?? "Błąd uwierzytelniania."
                }
            }
        }
    }
    
    func onChange(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            if let lastAuth = lastAuthenticationDate {
                let elapsedTime = Date().timeIntervalSince(lastAuth)
                if elapsedTime > 30 {
                    // Jeśli od ostatniego uwierzytelnienia minęło więcej niż 30 sekund, wymagamy ponownego logowania
                    isLocked = true
                    showOverlay = true
                    if autoAuthentication {
                        authenticate()
                    }
                } else {
                    if isLocked == false {
                        withAnimation {
                            showOverlay = false
                        }
                    }
                }
            } else {
                isLocked = true
                showOverlay = true
            }
        case .background:
            if !isLocked {
                lastAuthenticationDate = Date()
            }
            showOverlay = true
        case .inactive:
            showOverlay = true
        default:
            break
        }
    }
}
