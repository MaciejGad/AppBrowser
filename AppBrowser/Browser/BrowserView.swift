import SwiftUI

struct BrowserView: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @EnvironmentObject private var safeBrowsing: SafeBrowsingViewModel
    
    var body: some View {
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
            BrowserToolbar()
        }
        .gesture(DragGesture().onEnded { value in
            if value.startLocation.x < 20 && value.translation.width > 60 {
                viewModel.handle(command: .goBack)
            }
        })
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

