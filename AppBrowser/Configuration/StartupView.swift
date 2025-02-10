import SwiftUI

struct StartupView<Content: View>: View {
    @EnvironmentObject private var configViewModel: LoadConfiguration
    @ViewBuilder let mainContent: (Configuration) -> Content
    
    var body: some View {
        if let configuration = configViewModel.configuration {
            mainContent(configuration)
                .environmentObject(configuration)
        } else if let error = configViewModel.error {
           ErrorView(
                title: "App Startup Error",
                message: error.localizedDescription
            )
        } else {
            Color.white
                .edgesIgnoringSafeArea(.all)
        }
    }
}
