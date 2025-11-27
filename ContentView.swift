//
//  ContentView.swift
//  SafeCheck
//
//  Created by User on 11/25/25.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: CheckInManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("SafeCheck")
                    .font(.largeTitle).bold()
                
                if manager.isTimerRunning {
                    VStack(spacing: 20) {
                        Text("Check-in timer active")
                            .font(.title2)
                        
                        Text(manager.timeRemainingString)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Button("I'm Safe Now") {
                            manager.cancelTimer()
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 20) {
                        Picker("Timer Duration", selection: $manager.selectedMinutes) {
                            ForEach(manager.availableMinutes, id: \.self) { mins in
                                Text(mins == 2880 ? "48 hours (normal)" : "\(mins) minutes")
                                    .tag(mins)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        
                        Button("Start Check-In Timer") {
                            manager.startTimer()
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                NavigationLink("Emergency Contacts", destination: ContactsView())
                    .padding()
            }
            .padding()
            .navigationTitle("SafeCheck")
            .alert(isPresented: $manager.showSafetyAlert) {
                Alert(
                    title: Text("Are you OK?"),
                    message: Text("Tap I'm Safe if you're okay. Otherwise help will be notified in 90 seconds."),
                    primaryButton: .default(Text("I'm Safe"), action: manager.userIsSafe),
                    secondaryButton: .cancel(Text("Wait"), action: {})
                )
            }
            .sheet(isPresented: $manager.showEmergencyAlert) {
                EmergencySendView()
                    .environmentObject(manager)
            }
        }
    }
}

