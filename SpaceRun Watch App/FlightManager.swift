//
//  FlightManager.swift
//  SpaceRun Watch App
//

import Foundation
import Combine
import WatchKit
import HealthKit

// MARK: - Model pojedynczego biegu
struct RunRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let distance: Double   // km
    let duration: TimeInterval // sekundy
    let avgPace: String    // "mm:ss"
    let avgHeartRate: Int

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }

    var formattedDuration: String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Stan sesji
enum RunState {
    case idle, running, paused
}

class FlightManager: NSObject, ObservableObject {

    // MARK: - Telemetria bieżąca
    @Published var distance: Double = 0.0
    @Published var currentPace: String = "0:00"
    @Published var heartRate: Int = 0
    @Published var elapsedTime: TimeInterval = 0

    // MARK: - Stan
    @Published var runState: RunState = .idle

    // MARK: - Surowce
    @Published var spaceScrap: Int = 0
    @Published var antimatter: Int = 0

    // MARK: - Historia biegów
    @Published var runHistory: [RunRecord] = []

    // MARK: - Prywatne
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var sessionStartDate: Date?
    private var pausedTime: TimeInterval = 0
    private var clockTimer: Timer?
    private var heartRateSamples: [Double] = []
    private var nextScrapCheck: Double = 0.5
    private var nextHyperdriveCheck: Double = 1.0

    // UserDefaults key
    private let historyKey = "spacerun.runHistory"

    // MARK: - Init
    override init() {
        super.init()
        loadHistory()
        requestPermissions()
    }

    // MARK: - HealthKit uprawnienia
    private func requestPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .runningSpeed)!
        ]
        healthStore.requestAuthorization(toShare: share, read: read) { _, _ in }
    }

    // MARK: - START
    func startRun() {
        guard runState == .idle else { return }
        resetMetrics()

        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config
            )
            let now = Date()
            sessionStartDate = now
            workoutSession?.startActivity(with: now)
            workoutBuilder?.beginCollection(withStart: now) { _, _ in }
        } catch {
            print("SpaceRun: startRun error – \(error)")
        }

        runState = .running
        startClock()
        triggerHaptic(.sonarPulse)
    }

    // MARK: - PAUZA
    func pauseRun() {
        guard runState == .running else { return }
        workoutSession?.pause()
        runState = .paused
        clockTimer?.invalidate()
        pausedTime = elapsedTime
        triggerHaptic(.shieldWarning)
    }

    // MARK: - WZNÓW
    func resumeRun() {
        guard runState == .paused else { return }
        workoutSession?.resume()
        runState = .running
        startClock()
        triggerHaptic(.sonarPulse)
    }

    // MARK: - STOP
    func stopRun() {
        guard runState != .idle else { return }
        clockTimer?.invalidate()

        let avgHR = heartRateSamples.isEmpty ? 0 : Int(heartRateSamples.reduce(0, +) / Double(heartRateSamples.count))
        let record = RunRecord(
            id: UUID(),
            date: sessionStartDate ?? Date(),
            distance: distance,
            duration: elapsedTime,
            avgPace: currentPace,
            avgHeartRate: avgHR
        )
        saveRecord(record)

        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.workoutBuilder?.finishWorkout { _, _ in }
        }

        runState = .idle
        triggerHaptic(.hyperdriveJump)
    }

    // MARK: - Zegar czasu sesji
    private func startClock() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.runState == .running else { return }
            self.elapsedTime += 1
        }
    }

    // MARK: - Reset
    private func resetMetrics() {
        distance = 0
        currentPace = "0:00"
        heartRate = 0
        elapsedTime = 0
        pausedTime = 0
        spaceScrap = 0
        antimatter = 0
        heartRateSamples = []
        nextScrapCheck = 0.5
        nextHyperdriveCheck = 1.0
    }

    // MARK: - Nagrody
    private func checkMilestones() {
        if distance >= nextScrapCheck {
            spaceScrap += Int.random(in: 10...25)
            nextScrapCheck += 0.5
            triggerHaptic(.sonarPulse)
        }
        if distance >= nextHyperdriveCheck {
            antimatter += 5
            nextHyperdriveCheck += 1.0
            triggerHaptic(.hyperdriveJump)
        }
    }

    // MARK: - Tempo
    func formatPace(metersPerSecond mps: Double) -> String {
        guard mps > 0.1 else { return "0:00" }
        let secondsPerKm = 1000.0 / mps
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Czas sesji (MM:SS lub H:MM:SS)
    var formattedElapsed: String {
        let h = Int(elapsedTime) / 3600
        let m = Int(elapsedTime) / 60 % 60
        let s = Int(elapsedTime) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Haptyka
    private func triggerHaptic(_ effect: ShipHaptic) {
        #if os(watchOS)
        let type: WKHapticType
        switch effect {
        case .sonarPulse:     type = .success
        case .hyperdriveJump: type = .notification
        case .shieldWarning:  type = .directionUp
        }
        WKInterfaceDevice.current().play(type)
        #endif
    }

    // MARK: - Symulacja (Simulator)
    func simulateMovement() {
        guard runState == .running else { return }
        distance += 0.05
        heartRate = Int.random(in: 130...165)
        heartRateSamples.append(Double(heartRate))
        currentPace = "5:32"
        checkMilestones()
    }

    // MARK: - Persystencja historii
    private func saveRecord(_ record: RunRecord) {
        runHistory.insert(record, at: 0)
        if let data = try? JSONEncoder().encode(runHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([RunRecord].self, from: data) else { return }
        runHistory = decoded
    }

    func deleteRecord(at offsets: IndexSet) {
        runHistory.remove(atOffsets: offsets)
        if let data = try? JSONEncoder().encode(runHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension FlightManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        print("SpaceRun: session error – \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension FlightManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let qt = type as? HKQuantityType else { continue }
            let stats = workoutBuilder.statistics(for: qt)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch qt.identifier {
                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    let m = stats?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                    self.distance = m / 1000.0
                    self.checkMilestones()
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    let bpm = stats?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                    if bpm > 0 {
                        self.heartRate = Int(bpm)
                        self.heartRateSamples.append(bpm)
                    }
                case HKQuantityTypeIdentifier.runningSpeed.rawValue:
                    let mps = stats?.mostRecentQuantity()?.doubleValue(for: .meter().unitDivided(by: .second())) ?? 0
                    self.currentPace = self.formatPace(metersPerSecond: mps)
                default: break
                }
            }
        }
    }
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

// MARK: - ShipHaptic
enum ShipHaptic {
    case sonarPulse, hyperdriveJump, shieldWarning
}
