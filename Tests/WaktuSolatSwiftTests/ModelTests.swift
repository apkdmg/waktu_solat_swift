import XCTest
@testable import WaktuSolatSwift

final class ModelTests: XCTestCase {
    func testPrayerTimeFromJsonParsesValidPayload() throws {
        let json = """
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
        """

        let prayerTime = try JSONDecoder().decode(PrayerTime.self, from: Data(json.utf8))

        XCTAssertEqual(prayerTime.hijri, "1446-09-01")
        XCTAssertEqual(prayerTime.date, "2025-03-01")
        XCTAssertEqual(prayerTime.day, 6)
        XCTAssertEqual(prayerTime.imsak, 1425480000)
        XCTAssertEqual(prayerTime.fajr, 1425480480)
        XCTAssertEqual(prayerTime.syuruk, 1425485460)
        XCTAssertEqual(prayerTime.dhuhr, 1425507480)
        XCTAssertEqual(prayerTime.asr, 1425518340)
        XCTAssertEqual(prayerTime.maghrib, 1425529800)
        XCTAssertEqual(prayerTime.isha, 1425533940)
        XCTAssertEqual(prayerTime.isyraq, 1425486360)
    }

    func testPrayerTimeCalculatesImsakWhenMissing() throws {
        let json = """
        {
          "hijri": "1446-09-01",
          "date": "2025-03-01",
          "day": 6,
          "fajr": 1425480480,
          "syuruk": 1425485460,
          "dhuhr": 1425507480,
          "asr": 1425518340,
          "maghrib": 1425529800,
          "isha": 1425533940
        }
        """

        let prayerTime = try JSONDecoder().decode(PrayerTime.self, from: Data(json.utf8))
        XCTAssertEqual(prayerTime.imsak, 1425479880)
    }

    func testPrayerTimeSupportsNumericStringsForTimestamps() throws {
        let json = """
        {
          "hijri": "1446-09-01",
          "date": "2025-03-01",
          "day": 6,
          "imsak": "1425480000",
          "fajr": "1425480480",
          "syuruk": "1425485460",
          "dhuhr": "1425507480",
          "asr": "1425518340",
          "maghrib": "1425529800",
          "isha": "1425533940"
        }
        """

        let prayerTime = try JSONDecoder().decode(PrayerTime.self, from: Data(json.utf8))

        XCTAssertEqual(prayerTime.imsak, 1425480000)
        XCTAssertEqual(prayerTime.fajr, 1425480480)
        XCTAssertEqual(prayerTime.isyraq, 1425486360)
    }

    func testSolatV2FromJsonParsesValidPayload() throws {
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

        let solat = try JSONDecoder().decode(SolatV2.self, from: Data(json.utf8))

        XCTAssertEqual(solat.zone, "sgr01")
        XCTAssertEqual(solat.origin, "JAKIM")
        XCTAssertEqual(solat.prayerTime.count, 2)
        XCTAssertEqual(solat.prayerTime[0].date, "2025-03-01")
        XCTAssertEqual(solat.prayerTime[1].day, 0)
        XCTAssertEqual(solat.prayerTime[0].isyraq, 1425486360)
        XCTAssertEqual(solat.prayerTime[1].isyraq, 1425572760)
    }

    func testWaktuStateFromJsonParsesValidPayload() throws {
        let json = """
        {
          "negeri": "SELANGOR",
          "zones": ["sgr01", "sgr02", "sgr03"]
        }
        """

        let state = try JSONDecoder().decode(WaktuState.self, from: Data(json.utf8))

        XCTAssertEqual(state.negeri, "SELANGOR")
        XCTAssertEqual(state.zones.count, 3)
        XCTAssertTrue(state.zones.contains("sgr01"))
        XCTAssertTrue(state.zones.contains("sgr03"))
    }

    func testApiErrorFromJsonParsesValidPayload() throws {
        let json = """
        {
          "status": "error",
          "message": "Error, Zone not found, Please use /zones"
        }
        """

        let apiError = try JSONDecoder().decode(ApiError.self, from: Data(json.utf8))

        XCTAssertEqual(apiError.status, "error")
        XCTAssertEqual(apiError.message, "Error, Zone not found, Please use /zones")
    }
}
