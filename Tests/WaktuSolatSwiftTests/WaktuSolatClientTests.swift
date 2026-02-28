import Foundation
import XCTest
@testable import WaktuSolatSwift

private enum MockFailure: Error {
    case unexpectedURL(String)
}

private final class URLProtocolMock: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            fatalError("requestHandler not set")
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op
    }
}

final class WaktuSolatClientTests: XCTestCase {
    private var client: WaktuSolatClient!

    override func setUp() {
        super.setUp()

        URLProtocolMock.requestHandler = nil

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: configuration)

        client = WaktuSolatClient(session: session)
    }

    override func tearDown() {
        URLProtocolMock.requestHandler = nil
        client = nil
        super.tearDown()
    }

    func testGetStatesReturnsListOnSuccess() async throws {
        let url = "https://api.waktusolat.app/v2/negeri"
        let json = """
        [
          {"negeri":"JOHOR","zones":["jhr01","jhr02","jhr03","jhr04"]},
          {"negeri":"KEDAH","zones":["kdh01","kdh02","kdh03","kdh04","kdh05","kdh06","kdh07"]}
        ]
        """

        setMockResponse(expectedURL: url, statusCode: 200, body: json)

        let states = try await client.getStates()

        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(states[0].negeri, "JOHOR")
        XCTAssertTrue(states[0].zones.contains("jhr01"))
        XCTAssertEqual(states[1].negeri, "KEDAH")
        XCTAssertTrue(states[1].zones.contains("kdh01"))
    }

    func testGetStatesThrowsOnServerError() async {
        let url = "https://api.waktusolat.app/v2/negeri"
        setMockResponse(expectedURL: url, statusCode: 500, body: "{\"message\":\"Server Error\"}")

        do {
            _ = try await client.getStates()
            XCTFail("Expected WaktuSolatApiException")
        } catch let error as WaktuSolatApiException {
            XCTAssertEqual(error.statusCode, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetStatesThrowsOnNetworkError() async {
        let url = "https://api.waktusolat.app/v2/negeri"
        setMockError(expectedURL: url, error: URLError(.notConnectedToInternet))

        do {
            _ = try await client.getStates()
            XCTFail("Expected WaktuSolatApiException")
        } catch let error as WaktuSolatApiException {
            XCTAssertTrue(error.message.contains("Network error"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetZonesReturnsListOnSuccess() async throws {
        let url = "https://api.waktusolat.app/zones"
        let json = """
        [
          {"jakimCode":"jhr01","negeri":"JOHOR","daerah":"Pulau Aur dan Pulau Pemanggil"},
          {"jakimCode":"jhr02","negeri":"JOHOR","daerah":"Kota Tinggi, Mersing, Johor Bahru"},
          {"jakimCode":"kdh01","negeri":"KEDAH","daerah":"Kota Setar, Kubang Pasu, Pokok Sena"},
          {"jakimCode":"sgr01","negeri":"SELANGOR","daerah":"Gombak, Petaling, Sepang, Hulu Langat, Hulu Selangor, S.Alam"}
        ]
        """

        setMockResponse(expectedURL: url, statusCode: 200, body: json)

        let zones = try await client.getZones()

        XCTAssertEqual(zones.count, 4)
        XCTAssertEqual(zones[0].jakimCode, "jhr01")
        XCTAssertEqual(zones[0].negeri, "JOHOR")
        XCTAssertEqual(zones[3].jakimCode, "sgr01")
    }

    func testGetPrayerTimesByZoneReturnsSolatV2OnSuccess() async throws {
        let zone = "sgr01"
        let url = "https://api.waktusolat.app/v2/solat/\(zone)"
        let json = successPrayerResponse(zone: zone)

        setMockResponse(expectedURL: url, statusCode: 200, body: json)

        let result = try await client.getPrayerTimesByZone(zone)

        XCTAssertEqual(result.zone, zone)
        XCTAssertEqual(result.origin, "JAKIM")
        XCTAssertEqual(result.prayerTime.count, 1)
        XCTAssertEqual(result.prayerTime[0].date, "2025-03-01")
    }

    func testGetPrayerTimesByZoneBuildsQueryParameters() async throws {
        let zone = "sgr01"
        let url = "https://api.waktusolat.app/v2/solat/\(zone)?year=2025&month=3"
        let json = successPrayerResponse(zone: zone)

        setMockResponse(expectedURL: url, statusCode: 200, body: json)

        let result = try await client.getPrayerTimesByZone(zone, year: 2025, month: 3)

        XCTAssertEqual(result.zone, zone)
    }

    func testGetPrayerTimesByZoneThrowsApiErrorOn200ErrorPayload() async {
        let zone = "sgr01"
        let url = "https://api.waktusolat.app/v2/solat/\(zone)"
        let json = """
        {
          "status": "error",
          "message": "Error, Zone not found, Please use /zones"
        }
        """

        setMockResponse(expectedURL: url, statusCode: 200, body: json)

        do {
            _ = try await client.getPrayerTimesByZone(zone)
            XCTFail("Expected WaktuSolatApiException")
        } catch let error as WaktuSolatApiException {
            XCTAssertTrue(error.message.contains("Zone not found"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetPrayerTimesByGpsReturnsSolatV2OnSuccess() async throws {
        let latitude = 3.0738
        let longitude = 101.5183
        let url = "https://api.waktusolat.app/v2/solat/gps/\(latitude)/\(longitude)"

        setMockResponse(expectedURL: url, statusCode: 200, body: successPrayerResponse(zone: "WLP01"))

        let result = try await client.getPrayerTimesByGps(latitude, longitude)

        XCTAssertEqual(result.zone, "WLP01")
        XCTAssertEqual(result.prayerTime.count, 1)
    }

    func testGetPrayerTimeByDateReturnsSingleDayFromMonthlyPayload() async throws {
        let zone = "sgr01"
        let url = "https://api.waktusolat.app/v2/solat/\(zone)?year=2025&month=3"
        let json = """
        {
          "zone": "sgr01",
          "origin": "JAKIM",
          "prayers": [
            {
              "hijri": "1446-09-01",
              "date": "2025-03-01",
              "day": 6,
              "imsak": 1425480000,
              "fajr": 1425480480,
              "syuruk": 1425485460,
              "dhuhr": 1425507480,
              "asr": 1425518340,
              "maghrib": 1425529800,
              "isha": 1425533940
            },
            {
              "hijri": "1446-09-02",
              "date": "2025-03-02",
              "day": 0,
              "imsak": 1425566400,
              "fajr": 1425566880,
              "syuruk": 1425571860,
              "dhuhr": 1425593880,
              "asr": 1425604740,
              "maghrib": 1425616200,
              "isha": 1425620340
            }
          ]
        }
        """

        setMockResponse(expectedURL: url, statusCode: 200, body: json)

        let date = dateFromString("2025-03-02")
        let prayerTime = try await client.getPrayerTimeByDate(zone, date: date)

        XCTAssertNotNil(prayerTime)
        XCTAssertEqual(prayerTime?.date, "2025-03-02")
        XCTAssertEqual(prayerTime?.fajr, 1425566880)
    }

    private func setMockResponse(expectedURL: String, statusCode: Int, body: String) {
        URLProtocolMock.requestHandler = { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            guard url.absoluteString == expectedURL else {
                throw MockFailure.unexpectedURL(url.absoluteString)
            }

            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: [
                "Content-Type": "application/json"
            ])!

            return (response, Data(body.utf8))
        }
    }

    private func setMockError(expectedURL: String, error: Error) {
        URLProtocolMock.requestHandler = { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            guard url.absoluteString == expectedURL else {
                throw MockFailure.unexpectedURL(url.absoluteString)
            }

            throw error
        }
    }

    private func successPrayerResponse(zone: String) -> String {
        """
        {
          "zone": "\(zone)",
          "origin": "JAKIM",
          "prayers": [
            {
              "hijri": "1446-09-01",
              "date": "2025-03-01",
              "day": 6,
              "imsak": 1425480000,
              "fajr": 1425480480,
              "syuruk": 1425485460,
              "dhuhr": 1425507480,
              "asr": 1425518340,
              "maghrib": 1425529800,
              "isha": 1425533940
            }
          ]
        }
        """
    }

    private func dateFromString(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: value) else {
            fatalError("Invalid date value in test")
        }

        return date
    }
}
