import SwiftUI

struct BrowserView: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @EnvironmentObject private var safeBrowsing: SafeBrowsingViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    WebView()
                        .edgesIgnoringSafeArea(.all)
                    if let error = viewModel.error {
                        ErrorView(
                            title: "Browser Error",
                            message: error.localizedDescription
                        )
                        Spacer()
                    }
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle(viewModel.curentPath)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(!viewModel.showPath)
        }
        .toolbar {
            BrowserToolbar()
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

