import SwiftUI
import WaktuSolatSwift

@MainActor
final class PrayerTimesViewModel: ObservableObject {
    @Published var zones: [ZoneInfo]?
    @Published var prayerTimesZone: SolatV2?
    @Published var prayerTimesGps: SolatV2?
    @Published var lastGpsLat: Double?
    @Published var lastGpsLon: Double?
    @Published var isLoading = false
    @Published var error: String?

    private let client = WaktuSolatClient()

    func fetchZones() async {
        isLoading = true
        error = nil
        zones = nil

        do {
            zones = try await client.getZones()
        } catch let error as WaktuSolatApiException {
            self.error = "Error fetching zones: \(error.message)"
        } catch {
            self.error = "Unexpected error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func fetchPrayerTimesByZone(_ zone: String = "SGR01") async {
        isLoading = true
        error = nil
        prayerTimesZone = nil

        do {
            prayerTimesZone = try await client.getPrayerTimesByZone(zone)
        } catch let error as WaktuSolatApiException {
            self.error = "Error fetching prayer times for zone \(zone): \(error.message)"
        } catch {
            self.error = "Unexpected error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func fetchPrayerTimesByGps() async {
        isLoading = true
        error = nil
        prayerTimesGps = nil

        do {
            let latitude = 3.1390
            let longitude = 101.6869
            prayerTimesGps = try await client.getPrayerTimesByGps(latitude, longitude)
            lastGpsLat = latitude
            lastGpsLon = longitude
        } catch let error as WaktuSolatApiException {
            self.error = "Error fetching prayer times for GPS: \(error.message)"
        } catch {
            self.error = "Unexpected error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func formatTimestamp(_ timestamp: Int?) -> String {
        guard let timestamp else { return "--:--" }

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"

        return formatter.string(from: date)
    }
}

struct ContentView: View {
    @StateObject var viewModel: PrayerTimesViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tap buttons to fetch data:")
                        .font(.headline)

                    HStack(spacing: 10) {
                        Button("Fetch Zones") {
                            Task { await viewModel.fetchZones() }
                        }
                        .disabled(viewModel.isLoading)

                        Button("Fetch Times (SGR01)") {
                            Task { await viewModel.fetchPrayerTimesByZone("SGR01") }
                        }
                        .disabled(viewModel.isLoading)

                        Button("Fetch Times (GPS)") {
                            Task { await viewModel.fetchPrayerTimesByGps() }
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .buttonStyle(.borderedProminent)

                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }

                    if
                        let error = viewModel.error,
                        viewModel.zones == nil,
                        viewModel.prayerTimesZone == nil,
                        viewModel.prayerTimesGps == nil
                    {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.system(size: 15, weight: .semibold))
                    }

                    if let zones = viewModel.zones {
                        zoneSection(zones: zones)
                    } else if let error = viewModel.error, viewModel.zones == nil {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.system(size: 15, weight: .semibold))
                    }

                    if let zoneData = viewModel.prayerTimesZone {
                        prayerSection(
                            title: "Prayer Times (Zone: \(zoneData.zone.uppercased()))",
                            data: zoneData
                        )
                    }

                    if let gpsData = viewModel.prayerTimesGps {
                        let lat = viewModel.lastGpsLat?.formatted(.number.precision(.fractionLength(1))) ?? "?"
                        let lon = viewModel.lastGpsLon?.formatted(.number.precision(.fractionLength(1))) ?? "?"
                        prayerSection(
                            title: "Prayer Times (GPS: Lat \(lat), Lon \(lon))",
                            data: gpsData
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Waktu Solat")
        }
    }

    @ViewBuilder
    private func zoneSection(zones: [ZoneInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zones")
                .font(.title3)
                .fontWeight(.bold)

            ForEach(zones, id: \.jakimCode) { zone in
                VStack(alignment: .leading, spacing: 2) {
                    Text("(\(zone.jakimCode.uppercased())) \(zone.daerah)")
                    Text(zone.negeri)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
    }

    @ViewBuilder
    private func prayerSection(title: String, data: SolatV2) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Text("Origin: \(data.origin ?? "N/A")")
            Text("Zone: \(data.zone)")
            Text("First Day Times:")
                .fontWeight(.semibold)

            if let first = data.prayerTime.first {
                prayerTimeRow(first)
            } else {
                Text("No prayer times data available.")
            }

            if data.prayerTime.count > 1 {
                Text("...")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func prayerTimeRow(_ prayer: PrayerTime) -> some View {
        let dateLabel = prayer.date ?? prayer.hijri
        Text(
            "\(dateLabel) (\(prayer.day)): "
            + "Imsak \(viewModel.formatTimestamp(prayer.imsak)), "
            + "Fajr \(viewModel.formatTimestamp(prayer.fajr)), "
            + "Syuruk \(viewModel.formatTimestamp(prayer.syuruk)), "
            + "Isyraq \(viewModel.formatTimestamp(prayer.isyraq)), "
            + "Dhuhr \(viewModel.formatTimestamp(prayer.dhuhr)), "
            + "Asr \(viewModel.formatTimestamp(prayer.asr)), "
            + "Maghrib \(viewModel.formatTimestamp(prayer.maghrib)), "
            + "Isha \(viewModel.formatTimestamp(prayer.isha))"
        )
        .font(.caption)
        .textSelection(.enabled)
    }
}

#Preview {
    ContentView(viewModel: PrayerTimesViewModel())
}
