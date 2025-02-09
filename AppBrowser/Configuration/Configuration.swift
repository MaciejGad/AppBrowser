import Foundation

final class Configuration: ObservableObject {
    let url: URL
    let host: String
    let useBiometric: Bool
    let exceptionList: URL?
    let toolbarItems: String?
    let showPath: Bool
    
    init(url: URL, host: String, useBiometric: Bool, exceptionList: URL?, toolbarItems: String?, showPath: Bool) {
        self.url = url
        self.host = host
        self.useBiometric = useBiometric
        self.exceptionList = exceptionList
        self.toolbarItems = toolbarItems
        self.showPath = showPath
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
            throw Error.cantCreateURL
        }
        let useBiometric = dictionary[Key.useBiometric.rawValue] as? String ?? "NO"
        var exceptionList: URL? = nil
        if let exceptionListRaw = dictionary[Key.excpetionList.rawValue] as? String {
            exceptionList = URL(string: exceptionListRaw.replacingOccurrences(of: "\\()", with: ""))
        }
        let toolbarItems = dictionary[Key.toolbarItems.rawValue] as? String
        let showPath = dictionary[Key.showPath.rawValue] as? String ?? "NO"
        
        return Configuration(
            url: url,
            host: host,
            useBiometric: useBiometric.toBool(),
            exceptionList: exceptionList,
            toolbarItems: toolbarItems,
            showPath: showPath.toBool()
        )
    }
    
    private enum Key: String {
        case path = "BASE_PATH"
        case host = "BASE_HOST"
        case useBiometric = "BIOMETRIC_AUTHENTICATION"
        case excpetionList = "EXCEPTIONS_LIST"
        case toolbarItems = "TOOLBAR_ITEMS"
        case showPath = "SHOW_PATH"
    }
    
    enum Error: Swift.Error, LocalizedError {
        case noInfoDictionary
        case noHost
        case cantCreateURL
        
        var errorDescription: String? {
            switch self {
            case .noInfoDictionary:
                return "Lack of Info Dictionary"
            case .noHost:
                return "No host in configuration file"
            case .cantCreateURL:
                return "Can't create URL from provied host and path"
            }
        }
    }
}

extension String {
    func toBool() -> Bool {
        if self == "YES" {
            return true
        } else {
            return false
        }
    }
}
