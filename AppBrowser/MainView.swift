import SwiftUI

struct MainView: View {
    @EnvironmentObject private var configViewModel: ConfigurationViewModel

    var body: some View {
        Group {
            if let configuration = configViewModel.configuration {
                VStack {
                    Text("Host: \(configuration.host)")
                    Text("URL: \(configuration.url.absoluteString)")
                }
            } else if let error = configViewModel.error {
                ErrorView(message: error.localizedDescription)
            } else {
                Color.white
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}
