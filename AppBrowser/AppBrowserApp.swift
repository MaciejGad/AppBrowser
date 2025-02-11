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
                        }.environmentObject(
                            BiometricViewModel(
                                autoAuthentication: configuration.autoAuthentication
                            )
                        )
                    } else {
                        BrowserView()
                    }
                }
                .environmentObject(
                    BrowserViewModel(
                        baseUrl: configuration.url,
                        showPath: configuration.showPath,
                        commands: configuration.toolbarItems
                    )
                )
                .environmentObject(
                    SafeBrowsingViewModel(
                        baseHost: configuration.host,
                        exceptionList: configuration.exceptionList,
                        externalHostHandlingModel: configuration.externalHostHandlingModel
                    )
                )
                .environmentObject(
                    PrintHelper()
                )
            }
            .environmentObject(LoadConfiguration())
        }
    }
}
