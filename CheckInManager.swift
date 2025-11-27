//
//  CheckInManager.swift
//  SafeCheck
//
//  Created by User on 11/25/25.
//

// CheckInManager.swift
import Foundation
import Combine
import CoreLocation
import UIKit

class CheckInManager: NSObject, ObservableObject {
    @Published var isTimerRunning = false
    @Published var timeRemainingString = "00:00"
    @Published var selectedMinutes = 2880 // default 48 hours = 2880 minutes
    @Published var showSafetyAlert = false
    @Published var showEmergencyAlert = false
    
    let availableMinutes = [6, 15, 30, 60, 120, 2880] // testing + 48h
    
    private var timer: Timer?
    private var endDate: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Load/Save contacts (up to 3)
    @Published var emergencyContacts: [Contact] = {
        if let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
           let decoded = try? JSONDecoder().decode([Contact].self, from: data) {
            return decoded
        }
        return []
    }()
    
    override init() {
        super.init()
        startObserving()
    }
    
    func requestPermissions() {
        CLLocationManager().requestWhenInUseAuthorization()
    }
    
    func startTimer() {
        guard !emergencyContacts.isEmpty else {
            return // will show warning in UI later
        }
        
        let interval = TimeInterval(selectedMinutes * 60)
        endDate = Date().addingTimeInterval(interval)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        isTimerRunning = true
        updateTimer()
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        timeRemainingString = "00:00"
        showSafetyAlert = false
        showEmergencyAlert = false
    }
    
    private func updateTimer() {
        guard let end = endDate else { return }
        
        let remaining = end.timeIntervalSince(Date())
        
        if remaining <= 0 {
            timer?.invalidate()
            timeRemainingString = "00:00"
            triggerSafetyCheck()
        } else if remaining <= 90 {
            // Final 90-second warning
            let mins = Int(remaining) / 60
            let secs = Int(remaining) % 60
            timeRemainingString = String(format: "%02d:%02d", mins, secs)
            if !showSafetyAlert {
                showSafetyAlert = true
            }
        } else {
            let hours = Int(remaining) / 3600
            let mins = (Int(remaining) % 3600) / 60
            let secs = Int(remaining) % 60
            if hours > 0 {
                timeRemainingString = String(format: "%dh %02dm", hours, mins)
            } else {
                timeRemainingString = String(format: "%02d:%02d", mins, secs)
            }
        }
    }
    
    private func triggerSafetyCheck() {
        isTimerRunning = false
        showSafetyAlert = true
        
        // Auto-trigger emergency after 90 seconds if no response
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) { [weak self] in
            if self?.showSafetyAlert == true {
                self?.showSafetyAlert = false
                self?.showEmergencyAlert = true
            }
        }
    }
    
    func userIsSafe() {
        cancelTimer()
    }
    
    private func startObserving() {
        $emergencyContacts
            .sink { [weak self] contacts in
                if let data = try? JSONEncoder().encode(contacts) {
                    UserDefaults.standard.set(data, forKey: "emergencyContacts")
                }
            }
            .store(in: &cancellables)
    }
}

struct Contact: Codable, Identifiable {
    let id = UUID()
    var name: String
    var phone: String
}
