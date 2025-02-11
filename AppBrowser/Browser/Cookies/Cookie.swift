import Foundation

struct Cookie: Codable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let expiresDate: TimeInterval?
    let isSecure: Bool
    let isHTTPOnly: Bool

    // Convert HTTPCookie to CodableHTTPCookie
    init(from cookie: HTTPCookie) {
        self.name = cookie.name
        self.value = cookie.value
        self.domain = cookie.domain
        self.path = cookie.path
        self.expiresDate = cookie.expiresDate?.timeIntervalSince1970
        self.isSecure = cookie.isSecure
        self.isHTTPOnly = cookie.isHTTPOnly
    }

    // Convert CodableHTTPCookie back to HTTPCookie
    func toHTTPCookie() -> HTTPCookie? {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
            .secure: isSecure
        ]

        if let expiresDate = expiresDate {
            properties[.expires] = Date(timeIntervalSince1970: expiresDate)
        }

        return HTTPCookie(properties: properties)
    }
}
