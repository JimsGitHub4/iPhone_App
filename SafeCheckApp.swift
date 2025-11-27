//
//  SafeCheckApp.swift
//  SafeCheck
//
//  Created by User on 11/25/25.
//

import SwiftUI

@main
struct SafeCheckApp: App {
    @StateObject var manager = CheckInManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .onAppear {
                    manager.requestPermissions()
                }
        }
    }
}
