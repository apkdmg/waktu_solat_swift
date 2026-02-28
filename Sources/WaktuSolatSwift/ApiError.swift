import Foundation

/// Represents an error payload returned by the Waktu Solat API.
public struct ApiError: Decodable, Equatable, Sendable {
    public let status: String
    public let message: String

    public init(status: String, message: String) {
        self.status = status
        self.message = message
    }
}
