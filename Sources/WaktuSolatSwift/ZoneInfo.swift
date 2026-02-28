import Foundation

/// Represents zone information returned by the API.
public struct ZoneInfo: Decodable, Equatable, Sendable {
    public let jakimCode: String
    public let negeri: String
    public let daerah: String

    public init(jakimCode: String, negeri: String, daerah: String) {
        self.jakimCode = jakimCode
        self.negeri = negeri
        self.daerah = daerah
    }
}
