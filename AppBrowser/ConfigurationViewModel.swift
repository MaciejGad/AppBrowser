import SwiftUI

class ConfigurationViewModel: ObservableObject {
    @Published var configuration: Configuration?
    @Published var error: Error?
    
    init() {
        do {
            configuration = try Configuration.loadConfiguration()
        } catch {
            self.error = error
        }
    }
}
