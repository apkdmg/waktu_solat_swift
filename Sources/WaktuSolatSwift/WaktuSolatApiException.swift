import Foundation

/// Exception type for Waktu Solat API and parsing errors.
public struct WaktuSolatApiException: Error, LocalizedError, CustomStringConvertible, Equatable, Sendable {
    public let message: String
    public let statusCode: Int?
    public let apiError: ApiError?

    public init(
        _ message: String,
        statusCode: Int? = nil,
        apiError: ApiError? = nil
    ) {
        self.message = message
        self.statusCode = statusCode
        self.apiError = apiError
    }

    public var errorDescription: String? {
        message
    }

    public var description: String {
        if let statusCode {
            return "WaktuSolatApiException: \(message) (Status Code: \(statusCode))"
        }
        return "WaktuSolatApiException: \(message)"
    }
}
