//
//  ContentView.swift
//  SpaceRun
//

import SwiftUI

// MARK: - Modele i dane testowe
struct RunSession: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double // km
    let duration: TimeInterval // sekundy
    let scrapEarned: Int
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var pace: String {
        let paceInSeconds = duration / distance
        let paceMinutes = Int(paceInSeconds) / 60
        let paceSeconds = Int(paceInSeconds) % 60
        return String(format: "%d:%02d/km", paceMinutes, paceSeconds)
    }
}

class PlayerManager: ObservableObject {
    @Published var spaceScrap: Int = 1250
    @Published var runHistory: [RunSession] = [
        RunSession(date: Date(), distance: 5.43, duration: 1845, scrapEarned: 128),
        RunSession(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, distance: 3.20, duration: 1120, scrapEarned: 75),
        RunSession(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, distance: 8.15, duration: 2950, scrapEarned: 210)
    ]
}

// MARK: - Główny widok nawigacji
struct ContentView: View {
    @StateObject private var playerManager = PlayerManager()
    
    var body: some View {
        TabView {
            HangarView(playerManager: playerManager)
                .tabItem {
                    Label("Hangar", systemImage: "airplane")
                }
            
            HistoryView(playerManager: playerManager)
                .tabItem {
                    Label("Historia", systemImage: "list.bullet.clipboard")
                }
        }
        .preferredColorScheme(.dark) // Narzucamy ciemny motyw pasujący do kosmosu
        .tint(.cyan)
    }
}

// MARK: - Widok Hangaru (Statek i Ulepszenia)
struct HangarView: View {
    @ObservedObject var playerManager: PlayerManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Tło
                Color.black.ignoresSafeArea()
                RadialGradient(colors: [Color.blue.opacity(0.2), .clear], center: .top, startRadius: 10, endRadius: 400)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Sekcja Statku
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 250, height: 250)
                            .shadow(color: .cyan.opacity(0.3), radius: 20)
                        
                        // Zastąp "player_ship_blue" odpowiednią nazwą assetu w przyszłości
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.cyan)
                            .rotationEffect(.degrees(45))
                    }
                    .padding(.top, 40)
                    
                    Text("STARCRUISER MK-I")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .kerning(2)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 40)
                    
                    // Przestrzeń na przyszłe ulepszenia
                    VStack(alignment: .leading, spacing: 15) {
                        Text("STANOWISKO ULEPSZEŃ")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                UpgradeCardView(title: "Silnik", level: 1, icon: "flame.fill", isLocked: false)
                                UpgradeCardView(title: "Kadłub", level: 1, icon: "shield.fill", isLocked: false)
                                UpgradeCardView(title: "Magnes Złomu", level: 0, icon: "magnet", isLocked: true)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Baza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .foregroundColor(.purple)
                        Text("\(playerManager.spaceScrap)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.heavy)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.3))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Karta Ulepszenia (Placeholder)
struct UpgradeCardView: View {
    let title: String
    let level: Int
    let icon: String
    let isLocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isLocked ? "lock.fill" : icon)
                .font(.system(size: 28))
                .foregroundColor(isLocked ? .gray : .cyan)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                if !isLocked {
                    Text("Poz. \(level)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                }
            }
        }
        .frame(width: 110, height: 120)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isLocked ? Color.gray.opacity(0.3) : Color.cyan.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Widok Historii Biegów
struct HistoryView: View {
    @ObservedObject var playerManager: PlayerManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if playerManager.runHistory.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Brak wpisów w dzienniku")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(playerManager.runHistory) { session in
                                RunSessionCard(session: session)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Dziennik")
        }
    }
}

// MARK: - Karta pojedynczego biegu
struct RunSessionCard: View {
    let session: RunSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.date, style: .date)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .foregroundColor(.purple)
                        .font(.system(size: 12))
                    Text("+\(session.scrapEarned)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DYSTANS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                    Text(String(format: "%.2f km", session.distance))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("CZAS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                    Text(session.formattedDuration)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TEMPO")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                    Text(session.pace)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
