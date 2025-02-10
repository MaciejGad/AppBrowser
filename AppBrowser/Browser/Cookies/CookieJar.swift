import Foundation
import WebKit

class CookieJar {
    private let storage = SecureStorage()
    
    func saveCookiesToFile() {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookieStore.getAllCookies { cookies in
            let codableCookies = cookies.map { Cookie(from: $0) }
            Task {
                do {
                    let jsonData = try JSONEncoder().encode(codableCookies)
                    let encryptedData = try self.storage.encrypt(data: jsonData)
                    let fileURL = try self.getCookiesFileURL()
                    try encryptedData.write(to: fileURL, options: .atomic)
                    print("Cookies saved to file: \(fileURL.path)")
                } catch {
                    print("Failed to save cookies: \(error)")
                }
            }
        }
    }
    
    func loadCookiesFromFile() async {
        do {
            let cookies = try await loadData()
            await store(cookies: cookies)
            print("Cookies loaded from file.")
        } catch {
            print("\(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func store(cookies: [Cookie]) async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        for cookie in cookies {
            guard let httpCookie = cookie.toHTTPCookie() else { continue }
            await cookieStore.setCookie(httpCookie)
        }
    }
    
    private func loadData() async throws  -> [Cookie] {
        let fileURL = try getCookiesFileURL()
        let encryptedData = try Data(contentsOf: fileURL)
        let data = try storage.decryp(data: encryptedData)
        return try JSONDecoder().decode([Cookie].self, from: data)
    }
    
    func getCookiesFileURL() throws  -> URL {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw Error.noDocumentDirectory
        }
        return documentDirectory.appendingPathComponent("cookies.dat")
    }
    
    
    enum Error: Swift.Error, LocalizedError {
        case noDocumentDirectory
        
        var errorDescription: String? {
            switch self {
            case .noDocumentDirectory:
                return "Can't get URL to document directory"
            }
        }
    }
}
