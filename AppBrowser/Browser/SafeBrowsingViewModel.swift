import SwiftUI

final class SafeBrowsingViewModel: ObservableObject {
    @Published var alertData: AlertData? = nil
    
    private let baseHost: String
    private let exceptionList: URL?
    
    private var continuation: CheckedContinuation<OpenExternalHostAction, Never>? = nil
    private var exceptions: Set<String> = []
    private var safeHostLeft: Bool = false
    
    init(baseHost: String, exceptionList: URL?) {
        self.baseHost = baseHost
        self.exceptionList = exceptionList
        loadExceptions()
    }
    
    private func isSafeHost(url: URL?) -> Bool {
        let currentHost = url?.host ?? ""
        return currentHost == baseHost
    }
    
    func shouldOpenInExternalBrowser(url: URL?) async -> OpenExternalHostAction {
        guard let url = url else { return .inApp }
        var absoluteString = url.absoluteString
        if absoluteString.hasSuffix("/") {
            absoluteString = String(absoluteString.dropLast())
        }
        print(absoluteString)
        if exceptions.contains(absoluteString) {
            return .inApp
        }
        if isSafeHost(url: url) {
            safeHostLeft = false
            return .inApp
        }
        if safeHostLeft {
            return .inApp
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                if let currentContinuation = self.continuation{
                    currentContinuation.resume(returning: .inApp)
                }
                self.continuation = continuation
                self.alertData = AlertData(
                    title: "Otworzyć link?",
                    message: "Czy chcesz otworzyć link:\n\(url.absoluteString)\nw zewnętrznej przeglądarce?"
                )
            }
        }
    }
    
    func alertConfirmed() {
        continuation?.resume(returning: .externalBrower)
        cleanupAlert()
    }
        
    func alertCancelled() {
        continuation?.resume(returning: .inApp)
        safeHostLeft = true
        cleanupAlert()
    }
    
    private func cleanupAlert() {
        alertData = nil
        continuation = nil
    }
    
}

private extension SafeBrowsingViewModel {
    func loadExceptions() {
        Task {
            await loadExceptionsFromLocalFile()
            await loadExceptionsFromRemote()
        }
    }
    
    func loadExceptionsFromLocalFile() async {
        do {
            if let fileUrl = fileUrl() {
                let data = try Data(contentsOf: fileUrl)
                try await decode(exceptionListData: data)
            }
        } catch {
            print("Błąd podczas ładowania wyjątków: \(error)")
        }
    }
    
    func loadExceptionsFromRemote() async {
        do {
            if let remoteUrl = exceptionList {
                let (data, response) = try await URLSession.shared.data(from: remoteUrl)
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    try await decode(exceptionListData: data)
                }
            }
        } catch {
            print("Błąd podczas ładowania wyjątków: \(error)")
        }
    }
    
    func fileUrl() -> URL? {
        Bundle.main.url(forResource: "url_exceptions", withExtension: "json")
    }
    
    func decode(exceptionListData: Data) async throws {
        let exceptionList = try JSONDecoder().decode([String].self, from: exceptionListData)
        await MainActor.run {
            exceptions = Set(exceptionList)
        }
    }
}

enum OpenExternalHostAction {
    case inApp
    case externalBrower
}
