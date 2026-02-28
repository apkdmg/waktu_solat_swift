import Foundation

/// A client for interacting with the Waktu Solat API.
public final class WaktuSolatClient {
    public static let baseURL = URL(string: "https://api.waktusolat.app")!

    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    /// Fetches all Malaysian states and their corresponding zone codes.
    public func getStates() async throws -> [WaktuState] {
        let response = try await getRequest(endpoint: "/v2/negeri")

        guard let list = response as? [Any] else {
            throw WaktuSolatApiException(
                "Unexpected response format received for /v2/negeri. Expected a List."
            )
        }

        do {
            return try list.map { item in
                guard let object = item as? [String: Any] else {
                    throw DecodingError.dataCorrupted(
                        .init(codingPath: [], debugDescription: "Expected object inside state list")
                    )
                }
                return try decode(WaktuState.self, from: object)
            }
        } catch {
            throw WaktuSolatApiException("Failed to parse states list: \(error)")
        }
    }

    /// Fetches all prayer zones with state and district details.
    public func getZones() async throws -> [ZoneInfo] {
        let response = try await getRequest(endpoint: "/zones")

        guard let list = response as? [Any] else {
            throw WaktuSolatApiException(
                "Unexpected response format received for /zones. Expected a List of zone objects."
            )
        }

        do {
            return try list.map { item in
                guard let object = item as? [String: Any] else {
                    throw DecodingError.dataCorrupted(
                        .init(codingPath: [], debugDescription: "Expected object inside zone list")
                    )
                }
                return try decode(ZoneInfo.self, from: object)
            }
        } catch {
            throw WaktuSolatApiException("Failed to parse zone info list response: \(error)")
        }
    }

    /// Fetches prayer times for a specific zone.
    public func getPrayerTimesByZone(
        _ zone: String,
        year: Int? = nil,
        month: Int? = nil
    ) async throws -> SolatV2 {
        var queryItems: [URLQueryItem] = []
        if let year {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        }
        if let month {
            queryItems.append(URLQueryItem(name: "month", value: String(month)))
        }

        do {
            let response = try await getRequest(
                endpoint: "/v2/solat/\(zone)",
                queryItems: queryItems.isEmpty ? nil : queryItems
            )
            guard let object = response as? [String: Any] else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "Expected object for SolatV2 payload")
                )
            }
            return try decode(SolatV2.self, from: object)
        } catch let error as WaktuSolatApiException {
            throw error
        } catch {
            throw WaktuSolatApiException("Failed to parse SolatV2 response: \(error)")
        }
    }

    /// Fetches prayer times by GPS coordinates.
    public func getPrayerTimesByGps(
        _ latitude: Double,
        _ longitude: Double,
        year: Int? = nil,
        month: Int? = nil
    ) async throws -> SolatV2 {
        var queryItems: [URLQueryItem] = []
        if let year {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        }
        if let month {
            queryItems.append(URLQueryItem(name: "month", value: String(month)))
        }

        let endpoint = "/v2/solat/gps/\(latitude)/\(longitude)"

        do {
            let response = try await getRequest(
                endpoint: endpoint,
                queryItems: queryItems.isEmpty ? nil : queryItems
            )
            guard let object = response as? [String: Any] else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "Expected object for SolatV2 payload")
                )
            }
            return try decode(SolatV2.self, from: object)
        } catch let error as WaktuSolatApiException {
            throw error
        } catch {
            throw WaktuSolatApiException("Failed to parse SolatV2 response: \(error)")
        }
    }

    /// Fetches prayer times for a specific date by zone.
    public func getPrayerTimeByDate(_ zone: String, date: Date) async throws -> PrayerTime? {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let monthlyData = try await getPrayerTimesByZone(zone, year: year, month: month)
        let dateString = formatDate(date, calendar: calendar)

        if let byDate = monthlyData.prayerTime.first(where: { $0.date == dateString }) {
            return byDate
        }

        return monthlyData.prayerTime.first(where: { $0.day == day })
    }

    /// Fetches prayer times for a specific date by GPS coordinates.
    public func getPrayerTimeByDateGps(
        _ latitude: Double,
        _ longitude: Double,
        date: Date
    ) async throws -> PrayerTime? {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let monthlyData = try await getPrayerTimesByGps(latitude, longitude, year: year, month: month)
        let dateString = formatDate(date, calendar: calendar)

        if let byDate = monthlyData.prayerTime.first(where: { $0.date == dateString }) {
            return byDate
        }

        return monthlyData.prayerTime.first(where: { $0.day == day })
    }

    private func getRequest(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Any {
        let url = try makeURL(endpoint: endpoint, queryItems: queryItems)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw WaktuSolatApiException("Network error: \(error)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WaktuSolatApiException("Unexpected response type from API")
        }

        if httpResponse.statusCode >= 400 {
            if let apiError = try? decoder.decode(ApiError.self, from: data) {
                throw WaktuSolatApiException(
                    "API Error: \(apiError.message)",
                    statusCode: httpResponse.statusCode,
                    apiError: apiError
                )
            }

            let responseBody = String(data: data, encoding: .utf8) ?? "<non-UTF8 response body>"
            throw WaktuSolatApiException(
                "API Request failed with status \(httpResponse.statusCode). Response: \(responseBody)",
                statusCode: httpResponse.statusCode
            )
        }

        let jsonResponse: Any

        do {
            jsonResponse = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw WaktuSolatApiException("Failed to parse API response: \(error)")
        }

        if
            let object = jsonResponse as? [String: Any],
            let status = object["status"] as? String,
            status == "error"
        {
            do {
                let objectData = try JSONSerialization.data(withJSONObject: object)
                let apiError = try decoder.decode(ApiError.self, from: objectData)
                throw WaktuSolatApiException(
                    apiError.message,
                    statusCode: httpResponse.statusCode,
                    apiError: apiError
                )
            } catch let error as WaktuSolatApiException {
                throw error
            } catch {
                throw WaktuSolatApiException("An unexpected error occurred: \(error)")
            }
        }

        return jsonResponse
    }

    private func makeURL(endpoint: String, queryItems: [URLQueryItem]?) throws -> URL {
        guard var components = URLComponents(string: Self.baseURL.absoluteString + endpoint) else {
            throw WaktuSolatApiException("Failed to construct request URL")
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw WaktuSolatApiException("Failed to construct request URL")
        }

        return url
    }

    private func decode<T: Decodable>(_ type: T.Type, from jsonObject: Any) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        return try decoder.decode(T.self, from: data)
    }

    private func formatDate(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
