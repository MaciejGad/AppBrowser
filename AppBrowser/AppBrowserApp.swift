import SwiftUI

@main
struct AppBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            StartupView { configuration in
                Group {
                    if configuration.useBiometric {
                        BiometricView {
                            BrowserView()
                        }.environmentObject(BiometricViewModel())
                    } else {
                        BrowserView()
                    }
                }
                .environmentObject(
                    BrowserViewModel(baseUrl: configuration.url)
                )
                .environmentObject(
                    SafeBrowsingViewModel(baseHost: configuration.host)
                )
                .environmentObject(
                    PrintHelper()
                )
            }
            .environmentObject(LoadConfiguration())
        }
    }
}
