//
//  FlightManager.swift
//  SpaceRun Watch App
//
//  Created by Patryk Zapiór on 01/06/2026.
//

import Foundation
import Combine
import WatchKit

class FlightManager: ObservableObject {
    // Dane telemetryczne z biegu
    @Published var distance: Double = 0.0 // w kilometrach
    @Published var currentPace: String = "0:00"
    @Published var heartRate: Int = 120
    
    // Surowce i stan statku
    @Published var spaceScrap: Int = 0
    @Published var antimatter: Int = 0
    @Published var shipEnergy: Double = 1.0 // 0.0 do 1.0 (100%)
    
    // Licznik do następnego poziomu (odliczanie do 500m i 1km)
    var nextScrapCheck: Double = 0.5
    var nextHyperdriveCheck: Double = 1.0
    
    // Funkcja testowa do symulacji biegu (do dewelopmentu)
        func simulateMovement() {
            distance += 0.05
            heartRate = Int.random(in: 130...165)
            currentPace = "5:32"
            
            // Logika nagród "w locie"
            if distance >= nextScrapCheck {
                spaceScrap += Int.random(in: 10...25)
                nextScrapCheck += 0.5
                triggerHaptic(.sonarPulse) // Krótkie uderzenie sonaru
            }
            
            if distance >= nextHyperdriveCheck {
                antimatter += 5
                nextHyperdriveCheck += 1.0
                triggerHaptic(.hyperdriveJump) // Potężny skok w nadprzestrzeń
            }
        }
        
        // Nowa, bezpieczna funkcja obsługi haptyki
        private func triggerHaptic(_ effect: ShipHaptic) {
            #if os(watchOS)
            let watchKitType: WKHapticType
            switch effect {
            case .sonarPulse:
                watchKitType = .success
            case .hyperdriveJump:
                watchKitType = .notification // Poprawiony typ w watchOS
            case .shieldWarning:
                watchKitType = .directionUp
            }
            WKInterfaceDevice.current().play(watchKitType)
            #endif
        }
    }

    // Nasz własny kosmiczny system haptyki (działa wszędzie)
    enum ShipHaptic {
        case sonarPulse
        case hyperdriveJump
        case shieldWarning
    }
