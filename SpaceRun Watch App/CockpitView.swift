//
//  CockpitView.swift
//  SpaceRun Watch App
//

import SwiftUI

// MARK: - Główny kontener podczas biegu (TabView: HUD | Kontrolki)
struct CockpitView: View {
    @EnvironmentObject var flightManager: FlightManager
    @Binding var currentScreen: AppScreen
    
    // Stan do śledzenia aktywnej karty (0: HUD, 1: Kontrolki)
    @State private var selectedTab = 0

    let simTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // ── WSPÓLNE TŁO DLA OBU KART ───────────────────────────────
            Image("space_bg_blue")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                // Rozmazanie aktywuje się tylko na drugiej karcie (ControlsView)
                .blur(radius: selectedTab == 1 ? 8 : 0)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            Color.black.opacity(0.18)
                .ignoresSafeArea()
            
            // ── NAWIGACJA STRONAMI ─────────────────────────────────────
            TabView(selection: $selectedTab) {
                // Karta 1: HUD
                HUDView(currentScreen: $currentScreen)
                    .environmentObject(flightManager)
                    .tag(0)

                // Karta 2: Kontrolki
                ControlsView(currentScreen: $currentScreen)
                    .environmentObject(flightManager)
                    .tag(1)
            }
            .tabViewStyle(.page)
            .ignoresSafeArea() // <-- TUTAJ: To przywraca pełny wymiar ekranu dla kart
        }
        .onReceive(simTimer) { _ in
            #if DEBUG
            flightManager.simulateMovement()
            #endif
        }
    }
}

// MARK: - Karta 1: HUD z danymi biegu
struct HUDView: View {
    @EnvironmentObject var flightManager: FlightManager
    @Binding var currentScreen: AppScreen

    @State private var scrapFlash = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Pasek postępu
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(flightManager.distance / 10.0, 1.0) * 0.88))
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90 - 0.88 * 180))
                    .frame(width: min(w, h) - 6, height: min(w, h) - 6)
                    .animation(.linear(duration: 1), value: flightManager.distance)

                VStack(spacing: 0) {

                    // ── GÓRNY PASEK ──────────────────────────────────
                    HStack(alignment: .center, spacing: 0) {

                        // HR
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.35))
                            Text(flightManager.heartRate > 0 ? "\(flightManager.heartRate)" : "--")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .animation(.easeOut(duration: 0.4), value: flightManager.heartRate)
                        }
                        .frame(minWidth: 52, alignment: .leading)

                        Spacer()

                        // Zegar
                        Text(Date(), style: .time)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        // Surowce
                        HStack(spacing: 3) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.purple)
                            Text("\(flightManager.spaceScrap)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .animation(.easeOut(duration: 0.3), value: flightManager.spaceScrap)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(scrapFlash
                            ? Color.purple.opacity(0.55)
                            : Color.black.opacity(0.50))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.purple.opacity(0.55), lineWidth: 1))
                        .frame(minWidth: 52, alignment: .trailing)
                        .onChange(of: flightManager.spaceScrap) { _ in
                            withAnimation(.easeOut(duration: 0.15)) { scrapFlash = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeOut(duration: 0.4)) { scrapFlash = false }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 5)

                    // ── DYSTANS ──────────────────────────────────────
                    VStack(spacing: 0) {
                        Text("DYSTANS")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.0, green: 0.85, blue: 1.0))
                            .kerning(2)
                            .padding(.top, 6)

                        Text(String(format: "%.3f", flightManager.distance))
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .shadow(color: .cyan.opacity(0.5), radius: 8)
                            .contentTransition(.numericText())
                            .animation(.easeOut(duration: 0.4), value: flightManager.distance)

                        Text("KM")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .kerning(3)
                    }

                    Spacer(minLength: 0)

                    // ── STATEK ───────────────────────────────────────
                    Image("player_ship_blue")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: w * 0.28, height: w * 0.28)
                        .shadow(color: .blue.opacity(0.7), radius: 10, x: 0, y: 4)
                        .opacity(flightManager.runState == .paused ? 0.45 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: flightManager.runState == .paused)

                    Spacer(minLength: 0)

                    // ── DOLNY PASEK: czas | tempo ────────────────────
                    HStack(spacing: 0) {
                        // Czas sesji
                        VStack(spacing: 1) {
                            Text("CZAS")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundColor(.white.opacity(0.45))
                                .kerning(1.5)
                            Text(flightManager.formattedElapsed)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)

                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 1, height: 28)

                        // Tempo
                        VStack(spacing: 1) {
                            Text("TEMPO")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(red: 0.0, green: 0.85, blue: 1.0))
                                .kerning(1.5)
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text(flightManager.currentPace)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("/km")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .padding(.top, 4)
                    .background(Color.black.opacity(0.25))
                }
                .frame(width: w, height: h)

                // Pauza badge
                if flightManager.runState == .paused {
                    Text("⏸ PAUZA")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.orange.opacity(0.5), lineWidth: 1))
                }
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Karta 2: Kontrolki (przesuń w prawo)
struct ControlsView: View {
    @EnvironmentObject var flightManager: FlightManager
    @Binding var currentScreen: AppScreen

    @State private var showStopConfirm = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Subtelna siatka/tekstura nałożona na rozmazane tło globalne
                RadialGradient(
                    colors: [Color.blue.opacity(0.12), .clear],
                    center: .center,
                    startRadius: 5,
                    endRadius: w * 0.7
                )

                VStack(spacing: 12) {

                    // Nagłówek
                    Text("STEROWANIE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(2)
                        .padding(.top, 8)

                    Spacer(minLength: 0)

                    // Przycisk PAUZA / WZNÓW
                    Button {
                        if flightManager.runState == .running {
                            flightManager.pauseRun()
                        } else {
                            flightManager.resumeRun()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: flightManager.runState == .running
                                  ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .heavy))
                            Text(flightManager.runState == .running ? "PAUZA" : "WZNÓW")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .kerning(0.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            flightManager.runState == .running
                            ? LinearGradient(colors: [Color(red: 1.0, green: 0.75, blue: 0.0),
                                                      Color(red: 1.0, green: 0.55, blue: 0.0)],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(red: 0.0, green: 0.95, blue: 0.75),
                                                      Color(red: 0.0, green: 0.75, blue: 0.95)],
                                             startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    // Przycisk ZAKOŃCZ
                    Button {
                        showStopConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 16, weight: .heavy))
                            Text("ZAKOŃCZ")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .kerning(0.5)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(colors: [Color(red: 0.85, green: 0.15, blue: 0.2),
                                                    Color(red: 0.65, green: 0.08, blue: 0.12)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    // Podpowiedź nawigacji
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9))
                        Text("przesuń po dane")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.bottom, 6)
                }
                .padding(.horizontal, 12)
                .frame(width: w, height: h)
            }
        }
        .ignoresSafeArea()
        .confirmationDialog("Zakończyć bieg?", isPresented: $showStopConfirm) {
            Button("Zakończ i zapisz", role: .destructive) {
                flightManager.stopRun()
                currentScreen = .launch
            }
            Button("Anuluj", role: .cancel) {}
        }
    }
}

// MARK: - Preview
#Preview {
    let mockManager = FlightManager()
    mockManager.distance = 5.43
    mockManager.heartRate = 138
    mockManager.spaceScrap = 128
    mockManager.currentPace = "5:32"
    mockManager.runState = .running
    
    return CockpitView(currentScreen: .constant(.cockpit))
        .environmentObject(mockManager)
}
