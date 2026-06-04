//
//  SpaceRunApp.swift
//  SpaceRun Watch App
//

import SwiftUI

// MARK: - Ekrany aplikacji
enum AppScreen {
    case launch
    case cockpit
    case history
}

@main
struct SpaceRun_Watch_AppApp: App {
    @StateObject private var flightManager = FlightManager()
    @State private var currentScreen: AppScreen = .launch

    var body: some Scene {
        WindowGroup {
            Group {
                switch currentScreen {
                case .launch:
                    LaunchView(currentScreen: $currentScreen)
                case .cockpit:
                    CockpitView(currentScreen: $currentScreen)
                case .history:
                    HistoryView(currentScreen: $currentScreen)
                }
            }
            .environmentObject(flightManager)
        }
    }
}
