import SwiftUI
import Combine
import UIKit

final class BrowserViewModel: ObservableObject {
    @Published var curentPath: String
    @Published var isLoading: Bool
    @Published var error: Error?
    @Published var canGoBack: Bool
    
    let baseUrl: URL
    var currentURL: URL?
    
    let stateSubject = PassthroughSubject<State, Never>()
    
    init(baseUrl: URL) {
        self.baseUrl = baseUrl
        currentURL = baseUrl
        curentPath = baseUrl.path
        isLoading = true
        error = nil
        canGoBack = false
    }
    
    @MainActor
    func goBack() {
        if error == nil {
            stateSubject.send(.goBack)
        } else {
            reload()
        }
    }
    
    @MainActor
    func reload() {
        error = nil
        isLoading = true
        stateSubject.send(.reload)
    }
    
    @MainActor
    func loadHome() {
        error = nil
        isLoading = true
        stateSubject.send(.loadHome)
    }
    
    @MainActor
    func print() {
        stateSubject.send(.print)
    }
    
    @MainActor
    func show(error: Error) {
        isLoading = false
        self.error = error
        canGoBack = true
    }
    
    func update(currentUrl: URL?) {
        self.currentURL = currentUrl
        let path = currentUrl?.path ?? "/"
        if isSafeHost(url: currentUrl) {
            curentPath = path
        } else {
            let currentHost = currentUrl?.host ?? ""
            curentPath = "\(currentHost)\(path)"
        }
    }
    
    private func isSafeHost(url: URL?) -> Bool {
        let baseHost = baseUrl.host ?? ""
        let currentHost = url?.host ?? ""
        return currentHost == baseHost
    }
    
    func openInExternalBrowser() {
        guard let currentURL else { return }
        UIApplication.shared.open(currentURL, options: [:], completionHandler: nil)
    }
    
    enum State {
        case goBack
        case reload
        case loadHome
        case print
    }
}
