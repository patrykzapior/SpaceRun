import SwiftUI

struct CockpitView: View {
    @StateObject private var flightManager = FlightManager()
    
    // Timer do symulacji biegu na symulatorze (co 2 sekundy przesuwamy się)
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Tło kosmiczne (na razie gradient, docelowo Asset)
                RadialGradient(gradient: Gradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.15), .black]),
                               center: .center, startRadius: 5, endRadius: 200)
                    .ignoresSafeArea()
                
                // 2. Kosmiczny Pył / Efekt prędkości (proste linie w tle dla dynamiki)
                Circle()
                    .stroke(Color.blue.opacity(0.15), lineWidth: 2)
                    .scaleEffect(flightManager.shipEnergy)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: flightManager.shipEnergy)

                // 3. Główny Interfejs HUD
                VStack(spacing: 2) {
                    
                    // GÓRNY PASEK: Status i Surowce
                    HStack {
                        Image(systemName: "figure.run.circle.fill")
                            .foregroundColor(.cyan)
                            .font(.title3)
                        
                        Spacer()
                        
                        Text("10:09") // Czas systemowy watchOS doda automatycznie, to jest mockup
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("\(flightManager.spaceScrap)")
                                .font(.system(.footnote, design: .rounded))
                                .bold()
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 5)
                    
                    // ŚRODEK: Telemetria (Dystans)
                    VStack(spacing: -4) {
                        Text("DYSTANS")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                        
                        Text(String(format: "%.2f", flightManager.distance))
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .minimumScaleFactor(0.8)
                        
                        Text("KM")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    // GRAFIKA: Twój Statek Kosmiczny
                    // Zastąp "paperplane.fill" własnym zasobem ze szkicu po wrzuceniu do Assets
                    Image(systemName: "paperplane.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                        .foregroundColor(.blue)
                        .shadow(color: .cyan, radius: 10)
                        .rotationEffect(.init(degrees: -45)) // Wyprostowanie strzałki jako statku
                        .padding(.vertical, 4)
                    
                    // DOLNY PASEK: Tempo / Reaktor tętna
                    VStack(spacing: 0) {
                        Text("TEMPO")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray)
                        Text("\(flightManager.currentPace) /KM")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 15) // Miejsce na systemowy wskaźnik czasu
            }
        }
        .onReceive(timer) { _ in
            // Odpalanie symulacji ruchu w Xcode Simulator
            flightManager.simulateMovement()
        }
    }
}

#Preview {
    CockpitView()
}
