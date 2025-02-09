import SwiftUI

struct ConfigView: View {
    @EnvironmentObject private var configuration: Configuration
    
    var body: some View {
        VStack {
            Text("\(configuration.url)")
            Text("\(configuration.host)")
            Text(configuration.useBiometric ? "Use biometric" : "Do not use biometric")
        }
    }
}
