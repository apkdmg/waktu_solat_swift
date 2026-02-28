# WaktuSolatSwift

`WaktuSolatSwift` is a Swift Package for iOS/macOS to fetch Malaysia prayer times from [api.waktusolat.app](https://api.waktusolat.app/docs).

## Features

- Fetch all states (`/v2/negeri`)
- Fetch all zones with daerah/negeri (`/zones`)
- Fetch monthly prayer times by zone (`/v2/solat/{zone}`)
- Fetch monthly prayer times by GPS (`/v2/solat/gps/{lat}/{long}`)
- Convenience methods for a single date
- API/network/parsing error handling with `WaktuSolatApiException`
- Auto-calculates:
  - `imsak` = `fajr - 10 minutes` if missing
  - `isyraq` = `syuruk + 15 minutes`

## Requirements

- iOS 15+
- macOS 12+
- Swift 6.2+

## Installation (Swift Package Manager)

### Xcode

1. Open your project in Xcode.
2. Go to `File > Add Package Dependencies...`
3. Add your repository URL.
4. Select product `WaktuSolatSwift`.

### Package.swift

```swift
.package(url: "https://github.com/<your-username>/waktu_solat_swift.git", branch: "main")
```

Then add dependency to your target:

```swift
.product(name: "WaktuSolatSwift", package: "waktu_solat_swift")
```

## Quick Start

```swift
import WaktuSolatSwift

let client = WaktuSolatClient()

Task {
    do {
        let result = try await client.getPrayerTimesByZone("SGR01")
        print("Zone: \(result.zone)")
        print("Days returned: \(result.prayerTime.count)")
    } catch let error as WaktuSolatApiException {
        print("API error: \(error.message)")
    } catch {
        print("Unexpected error: \(error)")
    }
}
```

## Guide: How To Use

### 1. Get all states

```swift
let states = try await client.getStates()
for state in states {
    print(state.negeri, state.zones)
}
```

### 2. Get all zones

```swift
let zones = try await client.getZones()
for zone in zones.prefix(5) {
    print("\(zone.jakimCode) - \(zone.daerah) (\(zone.negeri))")
}
```

### 3. Get monthly prayer times by zone

```swift
let data = try await client.getPrayerTimesByZone("SGR01", year: 2026, month: 2)

if let firstDay = data.prayerTime.first {
    print(firstDay.date ?? firstDay.hijri)
    print(firstDay.fajr as Any)
    print(firstDay.maghrib as Any)
}
```

### 4. Get monthly prayer times by GPS

```swift
let latitude = 3.1390
let longitude = 101.6869
let data = try await client.getPrayerTimesByGps(latitude, longitude)
print("Detected zone: \(data.zone)")
```

### 5. Get prayer time for one date

```swift
let date = Date() // today
if let todayPrayer = try await client.getPrayerTimeByDate("SGR01", date: date) {
    print("Today Fajr: \(todayPrayer.fajr as Any)")
}

if let todayFromGps = try await client.getPrayerTimeByDateGps(3.1390, 101.6869, date: date) {
    print("Today Maghrib: \(todayFromGps.maghrib as Any)")
}
```

### 6. Convert API unix timestamps to readable time

API times are unix seconds.

```swift
func formatTime(_ unixSeconds: Int?) -> String {
    guard let unixSeconds else { return "--:--" }
    let date = Date(timeIntervalSince1970: TimeInterval(unixSeconds))
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}
```

## Error Handling

Use `WaktuSolatApiException` for API/network/parsing failures:

```swift
do {
    let _ = try await client.getPrayerTimesByZone("INVALID_ZONE")
} catch let error as WaktuSolatApiException {
    print(error.message)
    print(error.statusCode as Any)
    print(error.apiError as Any)
}
```

## Main Types

- `WaktuSolatClient`
- `WaktuState` (`typealias State = WaktuState`)
- `ZoneInfo`
- `PrayerTime`
- `SolatV2`
- `ApiError`
- `WaktuSolatApiException`

## Example App

A native SwiftUI example app (aligned with the Flutter example flow) is included here:

- `ExampleIOSApp/WaktuSolatSwiftExample.xcodeproj`

Open it in Xcode and run the `WaktuSolatSwiftExample` scheme.
