//
//  CockpitView.swift
//  SpaceRun Watch App
//

import SwiftUI

struct CockpitView: View {
    @EnvironmentObject var flightManager: FlightManager
    @Binding var currentScreen: AppScreen

    @State private var showStopConfirm = false
    @State private var pulse = false
    
    // Symulator
    let simTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ── TŁO ─────────────────────────────────────────────
                Image("space_bg_blue")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: w, height: h)
                    .clipped()
                Color.black.opacity(0.15)

                // ── PASEK POSTĘPU ────────────────────────────────────
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(flightManager.distance / 10.0, 1.0) * 0.88))
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90 - 0.88 * 180))
                    .frame(width: min(w, h) - 8, height: min(w, h) - 8)
                    .animation(.linear(duration: 1), value: flightManager.distance)

                // ── HUD ──────────────────────────────────────────────
                VStack(spacing: 0) {

                    // Górny pasek: HR | czas | surowce
                    HStack(alignment: .center, spacing: 0) {
                        // Tętno
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.35))
                            Text(flightManager.heartRate > 0 ? "\(flightManager.heartRate)" : "--")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .animation(.easeOut(duration: 0.4), value: flightManager.heartRate)
                        }
                        .frame(minWidth: 44, alignment: .leading)

                        Spacer()

                        // Zegar systemowy
                        Text(Date(), style: .time)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))

                        Spacer()

                        // Surowce
                        HStack(spacing: 3) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.purple)
                            Text("\(flightManager.spaceScrap)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.purple.opacity(0.5), lineWidth: 1))
                        .frame(minWidth: 44, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)

                    // Dystans
                    VStack(spacing: 0) {
                        Text("DYSTANS")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.0, green: 0.85, blue: 1.0))
                            .kerning(1.5)
                            .padding(.top, 4)

                        Text(String(format: "%.2f", flightManager.distance))
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .shadow(color: .cyan.opacity(0.4), radius: 6)
                            .contentTransition(.numericText())
                            .animation(.easeOut(duration: 0.4), value: flightManager.distance)

                        Text("KM")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .kerning(2)
                    }

                    // Czas sesji
                    Text(flightManager.formattedElapsed)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 2)

                    // Statek
                    Image("player_ship_blue")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: w * 0.36, height: w * 0.36)
                        .shadow(color: .cyan.opacity(pulse ? 1 : 0.6), radius: pulse ?20 : 10)
                        .padding(.top, 2)
                        .opacity(flightManager.runState == .paused ? 0.8 : 1.3)
                        .scaleEffect(pulse ? 1.04 : 1.0)
                        //.animation(.easeInOut(duration: 0.4), value: flightManager.runState == .paused)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

                    // PAUZA badge
                    if flightManager.runState == .paused {
                        Text("⏸ PAUZA")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                            .kerning(1)
                    }

                    // Tempo
                    VStack(spacing: 1) {
                        Text("TEMPO")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.0, green: 0.85, blue: 1.0))
                            .kerning(1.5)
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(flightManager.currentPace)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("/KM")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .padding(.top, 2)

                    // ── KONTROLKI ────────────────────────────────────
                    HStack(spacing: 8) {
                        // Pauza / Wznów
                        Button {
                            if flightManager.runState == .running {
                                flightManager.pauseRun()
                            } else {
                                flightManager.resumeRun()
                            }
                        } label: {
                            Image(systemName: flightManager.runState == .running ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 30)
                                .background(Color.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        // Stop
                        Button {
                            showStopConfirm = true
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 30)
                                .background(Color.red.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                }
                .frame(width: w, height: h)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        // Potwierdzenie zakończenia biegu
        .confirmationDialog("Zakończyć bieg?", isPresented: $showStopConfirm) {
            Button("Zakończ i zapisz", role: .destructive) {
                flightManager.stopRun()
                currentScreen = .launch
            }
            Button("Anuluj", role: .cancel) {}
        }
        .onReceive(simTimer) { _ in
            #if DEBUG
            flightManager.simulateMovement()
            #endif
        }
    }
}
