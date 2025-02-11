import Foundation

class ExceptionList {
    private var exceptions: [Exception] = []

    func load(list: [String]) {
        exceptions = list.map { Exception(rawValue: $0) }
    }
    
    func contains(_ url: URL) -> Bool {
        exceptions.contains { $0.matches(url) }
    }
}

class Exception {
    private let matchPrefix: Bool
    private let matchSuffix: Bool
    private let hostOnly: Bool
    private let value: String
    
   init(rawValue: String) {
        self.matchPrefix = rawValue.hasPrefix("*")
        self.matchSuffix = rawValue.hasSuffix("*")
        var value = rawValue
        if matchPrefix {
            value.removeFirst()
        }
        if matchSuffix {
            value.removeLast()
        }
       self.value = value
       hostOnly = !value.contains("/")
    }

    func matches(_ url: URL) -> Bool {
        let host = url.host ?? ""
        let search: String
        if hostOnly {
            search = host
        } else {
            var path = url.path
            if path.hasSuffix("/") {
                path.removeLast()
            }
            search = "\(host)\(path)"
        }
        if matchPrefix && matchSuffix {
            return search.contains(value)
        } else if matchPrefix {
            return search.hasSuffix(value)
        } else if matchSuffix {
            return search.hasPrefix(value)
        } else {
            return search == value
        }
    }
}
