import Foundation

class Configuration {
    let url: URL
    let host: String
    
    init(url: URL, host: String) {
        self.url = url
        self.host = host
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
        return Configuration(url: url, host: host)
    }
    
    private enum Key: String {
        case path = "BASE_PATH"
        case host = "BASE_HOST"
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
