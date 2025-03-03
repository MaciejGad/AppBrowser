import SwiftUI
import Combine
import UIKit

final class BrowserViewModel: ObservableObject {
    @Published var curentPath: String
    @Published var showPath: Bool
    @Published var isLoading: Bool
    @Published var error: Error?
    @Published var canGoBack: Bool
    
    @Published var toolbarItems: [Command]

    let baseUrl: URL
    var currentURL: URL?
    
    let stateSubject = PassthroughSubject<Command, Never>()
    
    init(baseUrl: URL, showPath: Bool, commands: String?) {
        self.baseUrl = baseUrl
        currentURL = baseUrl
        curentPath = baseUrl.path
        isLoading = true
        error = nil
        canGoBack = false
        self.showPath = showPath
        toolbarItems = Command.load(from: commands)
    }
    
    @MainActor
    func handle(command: Command) {
        switch command {
        case .goBack:
            goBack()
        case .reload:
            reload()
        case .loadHome:
            loadHome()
        case .openInExternalBrowser:
            openInExternalBrowser()
        case .print:
            print()
        }
    }

    @MainActor
    private
    func goBack() {
        guard canGoBack else {
            return
        }
        isLoading = false
        if error == nil {
            stateSubject.send(.goBack)
        } else {
            reload()
        }
    }
    
    @MainActor
    private
    func reload() {
        error = nil
        isLoading = true
        stateSubject.send(.reload)
    }
    
    @MainActor
    private
    func loadHome() {
        error = nil
        isLoading = true
        stateSubject.send(.loadHome)
    }
    
    @MainActor
    private
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
    
    @MainActor
    private
    func openInExternalBrowser() {
        guard let currentURL else { return }
        UIApplication.shared.open(currentURL, options: [:], completionHandler: nil)
    }
    
    
}
