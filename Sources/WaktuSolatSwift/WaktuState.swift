import Foundation

/// Represents a Malaysian state and its prayer zones.
public struct WaktuState: Decodable, Equatable, Sendable {
    public let negeri: String
    public let zones: [String]

    public init(negeri: String, zones: [String]) {
        self.negeri = negeri
        self.zones = zones
    }
}

public typealias State = WaktuState
