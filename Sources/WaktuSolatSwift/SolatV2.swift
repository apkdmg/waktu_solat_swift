import Foundation

/// Represents the prayer-time response structure from the API.
public struct SolatV2: Decodable, Equatable, Sendable {
    public let zone: String
    public let origin: String?
    public let prayerTime: [PrayerTime]

    enum CodingKeys: String, CodingKey {
        case zone
        case origin
        case prayers
    }

    public init(zone: String, origin: String?, prayerTime: [PrayerTime]) {
        self.zone = zone
        self.origin = origin
        self.prayerTime = prayerTime
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        zone = try container.decode(String.self, forKey: .zone)
        origin = try container.decodeIfPresent(String.self, forKey: .origin)
        prayerTime = try container.decode([PrayerTime].self, forKey: .prayers)
    }
}
