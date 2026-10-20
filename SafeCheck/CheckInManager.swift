//
//  CheckInManager.swift
//  SafeCheck
//
//  Created by Jim Bouldin on 12/24/25.
//

import Foundation
import SwiftUI
import Combine

class CheckInManager: ObservableObject {
    @Published var isTimerActive = false
    @Published var remainingTime = 0
    @Published var showAlert = false
    
    private var timer: Timer?
    
    func startTimer(duration: Int) {
        remainingTime = duration
        isTimerActive = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.remainingTime -= 1
            if self.remainingTime <= 0 {
                self.timer?.invalidate()
                self.isTimerActive = false
                self.showAlert = true
            }
        }
    }
    
    func resetTimer() {
        timer?.invalidate()
        isTimerActive = false
        remainingTime = 0
        showAlert = false
    }
}
