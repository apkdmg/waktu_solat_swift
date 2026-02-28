import Foundation

/// Represents prayer times for a single day.
public struct PrayerTime: Decodable, Equatable, Sendable {
    public let hijri: String
    public let date: String?
    public let day: Int
    public let imsak: Int?
    public let fajr: Int?
    public let syuruk: Int?
    public let dhuhr: Int?
    public let asr: Int?
    public let maghrib: Int?
    public let isha: Int?
    public let isyraq: Int?

    enum CodingKeys: String, CodingKey {
        case hijri
        case date
        case day
        case imsak
        case fajr
        case syuruk
        case dhuhr
        case asr
        case maghrib
        case isha
        case isyraq
    }

    public init(
        hijri: String,
        date: String?,
        day: Int,
        imsak: Int?,
        fajr: Int?,
        syuruk: Int?,
        dhuhr: Int?,
        asr: Int?,
        maghrib: Int?,
        isha: Int?,
        isyraq: Int?
    ) {
        self.hijri = hijri
        self.date = date
        self.day = day
        self.imsak = imsak
        self.fajr = fajr
        self.syuruk = syuruk
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.isyraq = isyraq
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hijri = try container.decode(String.self, forKey: .hijri)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        day = try container.decode(Int.self, forKey: .day)

        let initialImsak = try container.decodeFlexibleIntIfPresent(forKey: .imsak)
        fajr = try container.decodeFlexibleIntIfPresent(forKey: .fajr)
        syuruk = try container.decodeFlexibleIntIfPresent(forKey: .syuruk)
        dhuhr = try container.decodeFlexibleIntIfPresent(forKey: .dhuhr)
        asr = try container.decodeFlexibleIntIfPresent(forKey: .asr)
        maghrib = try container.decodeFlexibleIntIfPresent(forKey: .maghrib)
        isha = try container.decodeFlexibleIntIfPresent(forKey: .isha)

        if let initialImsak {
            imsak = initialImsak
        } else if let fajr {
            imsak = fajr - (10 * 60)
        } else {
            imsak = nil
        }

        if let syuruk {
            isyraq = syuruk + (15 * 60)
        } else {
            isyraq = nil
        }
    }
}

private extension KeyedDecodingContainer where K == PrayerTime.CodingKeys {
    func decodeFlexibleIntIfPresent(forKey key: K) throws -> Int? {
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? decode(String.self, forKey: key) {
            guard let parsedValue = Int(stringValue) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: self,
                    debugDescription: "Expected Int or numeric String for key '\(key.stringValue)'"
                )
            }
            return parsedValue
        }

        if !contains(key) {
            return nil
        }

        if try decodeNil(forKey: key) {
            return nil
        }

        throw DecodingError.typeMismatch(
            Int.self,
            .init(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int or numeric String for key '\(key.stringValue)'"
            )
        )

    }
}
