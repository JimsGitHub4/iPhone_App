//
//  SafeCheckViewModel.swift
//  SafeCheck
//
//  Created by Jim Bouldin on 5/20/26.
//


import SwiftUI
import Combine

class SafeCheckViewModel: ObservableObject {
    @Published var isMonitoring = false
    @Published var monitoringButtonTitle = "Start SafeCheck"
    @Published var monitoringButtonColor: Color = .green
    
    @Published var showAreYouOK = false
    @Published var areYouOKResponseTimeLeft: Int = 90
    
    private var monitoringTimer: Timer?
    private var responseTimer: Timer?
    private var wakeScreenTimer: Timer?
    
    func toggleMonitoring() {
        if isMonitoring {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }
    
    private func startMonitoring() {
        isMonitoring = true
        monitoringButtonTitle = "Stop SafeCheck"
        monitoringButtonColor = .red
        
        // Change 45 to whatever interval you want before first check
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: false) { [weak self] _ in
            self?.prepareAreYouOKQuery()
        }
    }
    
    private func stopMonitoring() {
        isMonitoring = false
        monitoringButtonTitle = "Start SafeCheck"
        monitoringButtonColor = .green
        
        monitoringTimer?.invalidate()
        responseTimer?.invalidate()
        wakeScreenTimer?.invalidate()
        showAreYouOK = false
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func prepareAreYouOKQuery() {
        // Wake screen 10 seconds before showing the alert
        wakeScreenTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.wakeScreenAndShowQuery()
        }
    }
    
    private func wakeScreenAndShowQuery() {
        UIApplication.shared.isIdleTimerDisabled = true
        
        DispatchQueue.main.async {
            self.showAreYouOK = true
            self.startResponseTimer()
        }
    }
    
    private func startResponseTimer() {
        areYouOKResponseTimeLeft = 90
        responseTimer?.invalidate()
        
        responseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.areYouOKResponseTimeLeft -= 1
            
            if self.areYouOKResponseTimeLeft <= 0 {
                timer.invalidate()
                self.handleNoResponse()
            }
        }
    }
    
    func respondImOK() {
        responseTimer?.invalidate()
        showAreYouOK = false
        UIApplication.shared.isIdleTimerDisabled = false
        // Optionally schedule next check here
    }
    
    private func handleNoResponse() {
        showAreYouOK = false
        //UIApplication.shared.isIdleTimerDisabled = false
        UIApplication.shared.isIdleTimerDisabled = true
        // TODO: Trigger emergency actions
        Text("You did not respond, emergency contacts are being notified.")
            .font(.title2)
            .bold()
            //.foregroundColor(.secondary)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
        print("No response - EMERGENCY PROTOCOL ACTIVATED")
    }
}
