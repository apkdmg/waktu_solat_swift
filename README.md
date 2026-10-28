# WaktuSolatSwift

`WaktuSolatSwift` is a Swift Package for iOS/macOS to fetch Malaysia prayer times from [api.waktusolat.app](https://api.waktusolat.app/docs).

## Features

- Fetch all states with their zone codes (built from `/zones`)
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
3. Enter `https://github.com/apkdmg/waktu_solat_swift.git` and set **Dependency Rule** to **Up to Next Major Version** from `1.0.1`.
4. Select product `WaktuSolatSwift`.

### Package.swift

```swift
.package(url: "https://github.com/apkdmg/waktu_solat_swift.git", from: "1.0.1")
```

Then add dependency to your target:

```swift
.product(name: "WaktuSolatSwift", package: "waktu_solat_swift")
```

## Installation (CocoaPods)

Add this in your `Podfile`:

```ruby
platform :ios, '15.0'
use_frameworks!

target 'YourAppTarget' do
  pod 'WaktuSolatSwift', :git => 'https://github.com/apkdmg/waktu_solat_swift.git', :tag => '1.0.1'
end
```

Then run:

```bash
pod install
```

If you publish this pod to CocoaPods trunk, consumers can use:

```ruby
pod 'WaktuSolatSwift'
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

## Credits

This library uses the [Malaysia Prayer Time API](https://api.waktusolat.app/docs) created by [Muhammad Fareez Iqmal](https://iqfareez.com/about), a Software Engineer specializing in Flutter, Laravel, and .NET technologies. The API provides accurate prayer times data for all locations in Malaysia.

The data is collected from [e-solat JAKIM](https://www.e-solat.gov.my/) and stored in a database to maintain stability and availability. For more technical information, visit the API repository at [https://github.com/mptwaktusolat/api-waktusolat](https://github.com/mptwaktusolat/api-waktusolat).

## Other platforms

The same API client is also available for:

- **Flutter / Dart:** [waktu_solat_lib](https://pub.dev/packages/waktu_solat_lib) on pub.dev ([GitHub](https://github.com/apkdmg/waktu_solat_lib))
- **Android / Kotlin:** [waktu_solat_android](https://github.com/apkdmg/waktu_solat_android), via JitPack (`com.github.apkdmg:waktu_solat_android`)

## CocoaPods Files

This repo includes:

- `WaktuSolatSwift.podspec`

For trunk publishing (maintainer only), typical flow:

```bash
pod spec lint WaktuSolatSwift.podspec --allow-warnings
pod trunk push WaktuSolatSwift.podspec --allow-warnings
```
