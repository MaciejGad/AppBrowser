import Foundation

final class Configuration: ObservableObject {
    let url: URL
    let host: String
    let useBiometric: Bool
    
    init(url: URL, host: String, useBiometric: Bool) {
        self.url = url
        self.host = host
        self.useBiometric = useBiometric
    }
    
    static func loadConfiguration() throws -> Configuration {
        guard let dictionary = Bundle.main.infoDictionary else {
            throw Error.noInfoDictionary
        }
        guard let host = dictionary[Key.host.rawValue] as? String else {
            throw Error.noHost
        }
        if host.isEmpty {
            throw Error.noHost
        }
        let path = dictionary[Key.path.rawValue] as? String ?? ""
        guard let url = URL(string: "https://\(host)\(path)") else {
            throw Error.canCreateURL
        }
        let useBiometricRaw = dictionary[Key.useBiometric.rawValue] as? String ?? "NO"
        let useBiometric: Bool
        if useBiometricRaw == "YES" {
            useBiometric = true
        } else {
            useBiometric = false
        }
        return Configuration(url: url, host: host, useBiometric: useBiometric)
    }
    
    private enum Key: String {
        case path = "BASE_PATH"
        case host = "BASE_HOST"
        case useBiometric = "BIOMETRIC_AUTHENTICATION"
    }
    
    enum Error: Swift.Error, LocalizedError {
        case noInfoDictionary
        case noHost
        case canCreateURL
        
        var errorDescription: String? {
            switch self {
            case .noInfoDictionary:
                return "Lack of Info Dictionary"
            case .noHost:
                return "No host in configuration file"
            case .canCreateURL:
                return "Can't create URL from provied host and path"
            }
        }
    }
    
}
