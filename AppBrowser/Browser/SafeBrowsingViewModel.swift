import SwiftUI

final class SafeBrowsingViewModel: ObservableObject {
    @Published var alertData: AlertData? = nil
    
    private let baseHost: String
    private let exceptionList: URL?
    
    private var continuation: CheckedContinuation<OpenExternalHostAction, Never>? = nil
    private let exceptions = ExceptionList()

    private var safeHostLeft: Bool = false
    private var externalHostHandlingModel: ExternalHostHandlingModel
    
    init(baseHost: String,
        exceptionList: URL?,
        externalHostHandlingModel: ExternalHostHandlingModel
    ) {
        self.baseHost = baseHost
        self.exceptionList = exceptionList
        self.externalHostHandlingModel = externalHostHandlingModel
        loadExceptions()
    }
    
    private func isSafeHost(url: URL?) -> Bool {
        let currentHost = url?.host ?? ""
        return currentHost == baseHost
    }
    
    func shouldOpenInExternalBrowser(url: URL?) async -> OpenExternalHostAction {
        if externalHostHandlingModel == .allow {
            return .inApp
        }
        if externalHostHandlingModel == .reject {
            return .reject
        }
        guard let url else {
            return .inApp
        }
        print("checking: \(url.absoluteString)")
        if isSafeHost(url: url) {
            safeHostLeft = false
            return .inApp
        }
        if safeHostLeft {
            return .inApp
        }
        if exceptions.contains(url) {
            return .inApp
        }
        if let currentContinuation = self.continuation{
            currentContinuation.resume(returning: .inApp)
        }
        await MainActor.run {
            alertData = AlertData(
                title: "Otworzyć link?",
                message: "Czy chcesz otworzyć link:\n\(url.absoluteString)\nw zewnętrznej przeglądarce?"
            )
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
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
            exceptions.load(list: exceptionList)
        }
    }
}

enum OpenExternalHostAction {
    case inApp
    case externalBrower
    case reject
}
