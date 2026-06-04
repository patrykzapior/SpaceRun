//
//  HistoryView.swift
//  SpaceRun Watch App
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var flightManager: FlightManager
    @Binding var currentScreen: AppScreen

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if flightManager.runHistory.isEmpty {
                // Pusty stan
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Brak biegów")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Wystartuj swój pierwszy bieg!")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.white.opacity(0.25))
                        .multilineTextAlignment(.center)

                    Button {
                        currentScreen = .launch
                    } label: {
                        Text("Wróć")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
                .padding(.horizontal, 16)
            } else {
                NavigationStack {
                    List {
                        ForEach(flightManager.runHistory) { record in
                            RunRowView(record: record)
                                .listRowBackground(Color.white.opacity(0.05))
                        }
                        .onDelete(perform: flightManager.deleteRecord)
                    }
                    .listStyle(.plain)
                    .navigationTitle("Historia")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                currentScreen = .launch
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Wiersz pojedynczego biegu
struct RunRowView: View {
    let record: RunRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Data
            Text(record.formattedDate)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            // Dystans (główna liczba)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(String(format: "%.2f", record.distance))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("km")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan.opacity(0.8))
            }

            // Tempo | Czas | HR
            HStack(spacing: 10) {
                Label(record.avgPace + "/km", systemImage: "figure.run")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))

                Label(record.formattedDuration, systemImage: "timer")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))

                if record.avgHeartRate > 0 {
                    Label("\(record.avgHeartRate)", systemImage: "heart.fill")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.4).opacity(0.85))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
