import Foundation
import WebKit

class CookieJar {
    func saveCookiesToFile() {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookieStore.getAllCookies { cookies in
            let codableCookies = cookies.map { Cookie(from: $0) }
            Task {
                do {
                    let jsonData = try JSONEncoder().encode(codableCookies)
                    let fileURL = try self.getCookiesFileURL()
                    try jsonData.write(to: fileURL, options: .atomic)
                    print("Cookies saved to file: \(fileURL.path)")
                } catch {
                    print("Failed to save cookies: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func loadCookiesFromFile() async {
        guard let fileURL = try? getCookiesFileURL() else {
            return
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            return
        }
        guard let cookies = try? JSONDecoder().decode([Cookie].self, from: data) else {
            return
        }
        
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        for cookie in cookies {
            guard let httpCookie = cookie.toHTTPCookie() else { continue }
            await cookieStore.setCookie(httpCookie)
        }
        print("Cookies loaded from file.")
    }
    
    func getCookiesFileURL() throws  -> URL {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw Error.noDocumentDirectory
        }
        return documentDirectory.appendingPathComponent("cookies.json")
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
