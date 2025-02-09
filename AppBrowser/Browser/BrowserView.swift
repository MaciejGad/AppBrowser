import SwiftUI

struct BrowserView: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @EnvironmentObject private var safeBrowsing: SafeBrowsingViewModel
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if let error = viewModel.error {
                    ConfigurationErrorView(
                        title: "Browser Error",
                        message: error.localizedDescription
                    )
                    Spacer()
                } else {
                    WebView()
                        .edgesIgnoringSafeArea(.all)
                }
                BrowserToolbar()
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert(item: $safeBrowsing.alertData) { alertData in
            Alert(
                title: Text(alertData.title),
                message: Text(alertData.message),
                primaryButton: .default(Text("Safari"), action: {
                    safeBrowsing.alertConfirmed()
                }),
                secondaryButton: .cancel(Text("InApp"), action: {
                    safeBrowsing.alertCancelled()
                })
            )
        }
    }
}

