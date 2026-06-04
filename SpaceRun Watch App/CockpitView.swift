import SwiftUI

// MARK: - Starfield Particle
struct StarParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let animationDelay: Double
}

// MARK: - Spaceship: główny kadłub (centralny, wąski)
struct ShipHullShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Dziób (góra, wąski)
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        // Prawa krawędź kadłuba — stopniowo się rozszerza
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.55))
        // Wcięcie między kadłubem a dyszą prawą
        path.addLine(to: CGPoint(x: w * 0.64, y: h * 0.65))
        path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.72))
        // Prawa dysza silnika
        path.addLine(to: CGPoint(x: w * 0.63, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.57, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.72))
        // Środkowa dysza
        path.addLine(to: CGPoint(x: w * 0.56, y: h * 0.68))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.84))
        path.addLine(to: CGPoint(x: w * 0.5,  y: h * 0.86))
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.84))
        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.68))
        // Lewa dysza silnika
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.43, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.37, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.65))
        // Lewa krawędź kadłuba
        path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.18))
        path.closeSubpath()

        return path
    }
}

// MARK: - Spaceship: lewe skrzydło
struct ShipLeftWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Skrzydło startuje od kadłuba ~38% szerokości
        path.move(to: CGPoint(x: w * 0.38, y: h * 0.28))
        // Cofnięte skrzydło — krawędź natarcia skośna w lewo/dół
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.52))
        // Krawędź spływu skrzydła (cofnięta)
        path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.30, y: h * 0.72))
        // Wycięcie — krawędź łącząca ze skrzydłem tylnym
        path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.65))
        path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.55))
        path.closeSubpath()
        return path
    }
}

// MARK: - Spaceship: prawe skrzydło (lustrzane)
struct ShipRightWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.62, y: h * 0.28))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.64, y: h * 0.65))
        path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.55))
        path.closeSubpath()
        return path
    }
}

// MARK: - Engine Flame Shape
struct EngineFlamePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.15, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: 0),
            control: CGPoint(x: w * 0.5, y: h * 0.15)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 1.0, y: h * 0.55)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.15, y: 0),
            control: CGPoint(x: w * 0.0, y: h * 0.55)
        )
        return path
    }
}

// MARK: - CockpitView
struct CockpitView: View {
    @StateObject private var flightManager = FlightManager()
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    // Animacje
    @State private var flameScale: CGFloat = 1.0
    @State private var flameOpacity: Double = 0.8
    @State private var glowPulse: Bool = false
    @State private var orbitProgress: Double = 0.0
    @State private var stars: [StarParticle] = CockpitView.generateStars()

    // Obliczone wartości
    private var progressAngle: Double {
        let progress = min(flightManager.distance / 10.0, 1.0)
        return progress * 270.0 - 135.0
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ── TŁO KOSMICZNE ──────────────────────────────────────
                spaceBackground(w: w, h: h)

                // ── ORBITY / ŁUKI (dekoracja) ──────────────────────────
                orbitArcs(w: w, h: h)

                // ── STATEK KOSMICZNY ────────────────────────────────────
                shipGraphic(w: w, h: h)

                // ── HUD OVERLAY ─────────────────────────────────────────
                hudOverlay(w: w, h: h)
            }
        }
        .onReceive(timer) { _ in
            flightManager.simulateMovement()
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Space Background
    @ViewBuilder
    func spaceBackground(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Głęboki granat
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.02, green: 0.05, blue: 0.18), location: 0.0),
                    .init(color: Color(red: 0.01, green: 0.02, blue: 0.08), location: 0.5),
                    .init(color: .black, location: 1.0)
                ]),
                center: .center,
                startRadius: 10,
                endRadius: max(w, h) * 0.8
            )
            .ignoresSafeArea()

            // Mgławica – cyan/niebieski blask w centrum (planet glow)
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.1, green: 0.4, blue: 0.9).opacity(0.35), location: 0.0),
                    .init(color: Color(red: 0.05, green: 0.2, blue: 0.5).opacity(0.15), location: 0.4),
                    .init(color: .clear, location: 1.0)
                ]),
                center: UnitPoint(x: 0.5, y: 0.72),
                startRadius: 5,
                endRadius: w * 0.7
            )
            .ignoresSafeArea()

            // Gwiazdy
            ForEach(stars) { star in
                Circle()
                    .fill(.white)
                    .frame(width: star.size, height: star.size)
                    .opacity(star.opacity * (glowPulse ? 1.0 : 0.5))
                    .position(x: star.x * w, y: star.y * h)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(star.animationDelay),
                        value: glowPulse
                    )
            }

            // Planeta w tle (duże rozmyte koło)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.3, blue: 0.7).opacity(0.6),
                            Color(red: 0.05, green: 0.1, blue: 0.3).opacity(0.3),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 1,
                        endRadius: 50
                    )
                )
                .frame(width: w * 0.65, height: w * 0.65)
                .blur(radius: 8)
                .offset(x: w * 0.1, y: h * 0.28)
        }
    }

    // MARK: - Orbit Arcs
    @ViewBuilder
    func orbitArcs(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Lewy łuk postępu (pomarańczowy/cyan)
            ProgressArc(
                startAngle: .degrees(210),
                endAngle: .degrees(270),
                progress: min(flightManager.distance / 5.0, 1.0),
                color: Color(red: 1.0, green: 0.55, blue: 0.1)
            )
            .frame(width: w * 0.88, height: w * 0.88)
            .position(x: w * 0.5, y: h * 0.52)

            // Prawy łuk postępu (cyan)
            ProgressArc(
                startAngle: .degrees(270),
                endAngle: .degrees(330),
                progress: min(flightManager.distance / 10.0, 1.0),
                color: Color(red: 0.1, green: 0.85, blue: 0.9)
            )
            .frame(width: w * 0.88, height: w * 0.88)
            .position(x: w * 0.5, y: h * 0.52)
        }
    }

    // MARK: - Ship Graphic
    @ViewBuilder
    func shipGraphic(w: CGFloat, h: CGFloat) -> some View {
        // Statek proporcjonalnie do ekranu — szerszy niż wcześniej
        let shipW = w * 0.72
        let shipH = shipW * 1.05
        let shipY = h * 0.56

        // Pozycje dysz (względem środka statku):
        // Środkowa: x=0, boczne: ±shipW*0.13
        let nozzleY   = shipH * 0.41  // offset od centrum statku w dół do wylotu dyszy
        let nozzleOffX = shipW * 0.13 // odstęp bocznych dysz od osi

        ZStack {
            // ── PŁOMIENIE SILNIKÓW (pod kadłubem) ─────────────────

            // Lewy płomień
            engineFlame(width: shipW * 0.17, height: shipH * 0.30)
                .scaleEffect(y: flameScale)
                .opacity(flameOpacity)
                .offset(x: -nozzleOffX, y: nozzleY)

            // Środkowy płomień (największy)
            engineFlame(width: shipW * 0.20, height: shipH * 0.34)
                .scaleEffect(y: flameScale * 1.05)
                .opacity(flameOpacity)
                .offset(x: 0, y: nozzleY + shipH * 0.015)

            // Prawy płomień
            engineFlame(width: shipW * 0.17, height: shipH * 0.30)
                .scaleEffect(y: flameScale)
                .opacity(flameOpacity)
                .offset(x: nozzleOffX, y: nozzleY)

            // ── SKRZYDŁA (za kadłubem wizualnie, rysowane pierwsze) ──

            // Lewe skrzydło — ciemniejszy odcień
            ShipLeftWingShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.28, green: 0.35, blue: 0.50),
                            Color(red: 0.15, green: 0.20, blue: 0.33)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: shipW, height: shipH)

            // Cyan accent — krawędź natarcia lewego skrzydła
            ShipLeftWingShape()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.0),
                            Color.cyan.opacity(0.7),
                            Color.cyan.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomLeading
                    ),
                    lineWidth: 1.2
                )
                .frame(width: shipW, height: shipH)

            // Prawe skrzydło
            ShipRightWingShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.28, green: 0.35, blue: 0.50),
                            Color(red: 0.15, green: 0.20, blue: 0.33)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: shipW, height: shipH)

            // Cyan accent — krawędź natarcia prawego skrzydła
            ShipRightWingShape()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.0),
                            Color.cyan.opacity(0.7),
                            Color.cyan.opacity(0.3)
                        ]),
                        startPoint: .topTrailing,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .frame(width: shipW, height: shipH)

            // ── KADŁUB GŁÓWNY ────────────────────────────────────────

            ShipHullShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(red: 0.60, green: 0.68, blue: 0.80), location: 0.0),   // dziób – jasny
                            .init(color: Color(red: 0.38, green: 0.46, blue: 0.62), location: 0.35),
                            .init(color: Color(red: 0.22, green: 0.28, blue: 0.44), location: 0.65),
                            .init(color: Color(red: 0.15, green: 0.20, blue: 0.35), location: 1.0)    // dysze – ciemne
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: shipW, height: shipH)
                .shadow(color: Color.cyan.opacity(glowPulse ? 0.55 : 0.30), radius: glowPulse ? 14 : 8)

            // Highlight krawędzi kadłuba (lewa i prawa linia)
            ShipHullShape()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.55),
                            Color(red: 0.4, green: 0.75, blue: 1.0).opacity(0.25),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
                .frame(width: shipW, height: shipH)

            // Panel centralne wzmocnienie (ciemny pasek na środku kadłuba)
            Rectangle()
                .fill(Color(red: 0.18, green: 0.22, blue: 0.36).opacity(0.7))
                .frame(width: shipW * 0.14, height: shipH * 0.42)
                .offset(y: -shipH * 0.08)

            // ── COCKPIT ──────────────────────────────────────────────

            // Zewnętrzna ramka
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.20, green: 0.30, blue: 0.55))
                .frame(width: shipW * 0.19, height: shipH * 0.13)
                .offset(y: -shipH * 0.25)

            // Szyba cockpitu — cyan gradient
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.5, green: 0.9, blue: 1.0).opacity(0.95),
                            Color(red: 0.2, green: 0.55, blue: 0.9).opacity(0.7)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: shipW * 0.14, height: shipH * 0.09)
                .offset(y: -shipH * 0.255)
                .shadow(color: Color.cyan.opacity(glowPulse ? 1.0 : 0.6), radius: glowPulse ? 9 : 5)

            // ── BLASK ENGINE GLOW (atmosfera pod statkiem) ───────────

            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.25, green: 0.6, blue: 1.0).opacity(0.55),
                            Color(red: 0.1, green: 0.3, blue: 0.8).opacity(0.20),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 2,
                        endRadius: 35
                    )
                )
                .frame(width: shipW * 0.55, height: shipH * 0.14)
                .blur(radius: 7)
                .scaleEffect(flameScale)
                .offset(y: nozzleY + shipH * 0.05)
        }
        .position(x: w * 0.5, y: shipY)
    }

    @ViewBuilder
    func engineFlame(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Zewnętrzny płomień (niebieski)
            EngineFlamePath()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.9),
                            Color(red: 0.1, green: 0.3, blue: 0.9).opacity(0.6),
                            .clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)
                .blur(radius: 2)

            // Wewnętrzny rdzeń (biały/jasnoniebieski)
            EngineFlamePath()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.95),
                            Color(red: 0.6, green: 0.85, blue: 1.0).opacity(0.7),
                            .clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width * 0.5, height: height * 0.7)
        }
    }

    // MARK: - HUD Overlay
    @ViewBuilder
    func hudOverlay(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            // GÓRNY PASEK
            HStack(alignment: .center) {
                Image(systemName: "figure.run.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Text("10:09")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.purple)
                    Text("\(flightManager.spaceScrap)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple.opacity(0.5), lineWidth: 0.5)
                        )
                )
            }
            .padding(.horizontal, 8)
            .padding(.top, 2)

            // TELEMETRIA – DYSTANS
            VStack(spacing: -2) {
                Text("DYSTANS")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(.cyan)
                    .kerning(2)

                Text(String(format: "%.2f", flightManager.distance))
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .cyan.opacity(0.5), radius: 6)

                Text("KM")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
                    .kerning(2)
            }
            .padding(.top, 2)

            Spacer()

            // DOLNY PASEK – TEMPO
            VStack(spacing: 1) {
                Text("TEMPO")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
                    .kerning(2)
                Text("\(flightManager.currentPace) /KM")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.95, blue: 0.45))
                    .shadow(color: .green.opacity(0.5), radius: 4)
            }
            .padding(.bottom, 6)
        }
    }

    // MARK: - Animacje
    func startAnimations() {
        // Pulsowanie silników
        withAnimation(
            .easeInOut(duration: 0.4)
            .repeatForever(autoreverses: true)
        ) {
            flameScale = 1.18
            flameOpacity = 1.0
        }

        // Pulsowanie blasku
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = true
        }
    }

    // MARK: - Helper: generuj gwiazdy
    static func generateStars() -> [StarParticle] {
        (0..<55).map { _ in
            StarParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...0.85),
                size: CGFloat.random(in: 0.8...2.2),
                opacity: Double.random(in: 0.4...1.0),
                animationDelay: Double.random(in: 0...4)
            )
        }
    }
}

// MARK: - Progress Arc Helper
struct ProgressArc: View {
    var startAngle: Angle
    var endAngle: Angle
    var progress: Double
    var color: Color

    var body: some View {
        ZStack {
            // Track
            Arc(startAngle: startAngle, endAngle: endAngle, clockwise: false)
                .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: 3, lineCap: .round))

            // Progress
            Arc(startAngle: startAngle, endAngle: Angle(degrees: startAngle.degrees + (endAngle.degrees - startAngle.degrees) * progress), clockwise: false)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .shadow(color: color.opacity(0.7), radius: 4)
        }
    }
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

#Preview {
    CockpitView()
}
