import Foundation

enum Command: String, Identifiable, Codable, CaseIterable {
    case goBack
    case loadHome
    case reload
    case openInExternalBrowser
    case print
    
    var id: String {
        rawValue
    }
    
    func iconName() -> String {
        switch self {
        case .goBack:
            return "chevron.left"
        case .loadHome:
            return "house"
        case .reload:
            return "arrow.clockwise"
        case .openInExternalBrowser:
            return "arrow.up.right.square"
        case .print:
            return "printer.filled.and.paper"
        }
    }
}
