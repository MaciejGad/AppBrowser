import SwiftUI
import WebKit
import Combine

struct WebView: UIViewRepresentable {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @EnvironmentObject private var safeBrowsing: SafeBrowsingViewModel
    @EnvironmentObject private var printingHelper: PrintHelper
    
    private let cookieJar = CookieJar()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView  {
        let webView = WKWebView()
        let coordinator = context.coordinator
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        let refreshControl = UIRefreshControl()
        // good old days ;)
        refreshControl.addTarget(coordinator, action: #selector(coordinator.refresh), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        coordinator.webView = webView
        coordinator.setupSubscriptions()
        Task {
            await cookieJar.loadCookiesFromFile()
            loadBaseURL(webView: webView)
        }
        return webView
    }
    
    @MainActor
    func loadBaseURL(webView: WKWebView) {
        webView.load(URLRequest(url: viewModel.baseUrl))
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebView
        var webView: WKWebView?
        var cancellables = Set<AnyCancellable>()
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func setupSubscriptions() {
            guard let webView else { return }
            let baseUrl = parent.viewModel.baseUrl
            weak var printingHelper = parent.printingHelper
            
            parent.viewModel.stateSubject.sink { [weak webView] state in
                guard let webView else { return }
                switch state {
                case .goBack where webView.canGoBack:
                    webView.goBack()
                case .reload:
                    webView.reload()
                case .loadHome:
                    DispatchQueue.main.async {
                        webView.load(URLRequest(url: baseUrl))
                    }
                case .print:
                    DispatchQueue.main.async {
                        let webviewPrint = webView.viewPrintFormatter()
                        let currentPath = webView.url?.path ?? "/page"
                        let pageName = String(currentPath.replacingOccurrences(of: "/", with: "_").dropFirst())
                        printingHelper?.print(formatter: webviewPrint, pageName: pageName)
                    }
                default:
                    return
                }
            }.store(in: &cancellables)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.viewModel.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                // Aktualizujemy aktualny URL oraz możliwość cofania
                let viewModel = self.parent.viewModel
                viewModel.update(currentUrl: webView.url)
                viewModel.canGoBack = webView.canGoBack
                viewModel.isLoading = false
                webView.scrollView.refreshControl?.endRefreshing()
            }
            parent.cookieJar.saveCookiesToFile()
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("loading error: \(error)")
            DispatchQueue.main.async {
                self.parent.viewModel.show(error: error)
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else {
                return .cancel
            }
            if url.absoluteString == "about:blank" {
                return .allow
            }
            if url.absoluteString == "about:srcdoc" {
                return .allow
            }
            let action = await parent.safeBrowsing.shouldOpenInExternalBrowser(url: navigationAction.request.url)
            switch action {
            case .inApp:
                return .allow
            case .externalBrower:
                await MainActor.run {
                    parent.viewModel.currentURL = url
                    parent.viewModel.handle(command: .openInExternalBrowser)
                }
                return .cancel
            case .reject:
                return .cancel
            }
        }
        
        @MainActor
        @objc func refresh() {
            parent.viewModel.handle(command: .reload)
        }
    }
}

