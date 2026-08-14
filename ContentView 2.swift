//
//  ContentView 2.swift
//  SafeCheck
//
//  Created by Jim Bouldin on 5/20/26.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SafeCheckViewModel()
    
    var body: some View {
        VStack(spacing: 40) {
            Text("SafeCheck")
                .font(.largeTitle)
                .bold()
            
            // Main Start/Stop Button
            Button(action: {
                viewModel.toggleMonitoring()
            }) {
                Text(viewModel.monitoringButtonTitle)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.monitoringButtonColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            if viewModel.isMonitoring {
                Text("Monitoring active...")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $viewModel.showAreYouOK) {
            VStack(spacing: 30) {
                Text("Are You OK?")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text("You have \(viewModel.areYouOKResponseTimeLeft) seconds to respond")
                    .font(.title2)
                    .foregroundColor(viewModel.areYouOKResponseTimeLeft < 30 ? .red : .primary)
                
                Button("Yes I'm OK") {
                    viewModel.respondImOK()
                }
                .font(.title)
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .cornerRadius(12)
                
                Text("If you do not respond, emergency contacts will be notified.")
                    .font(.title2)
                    .bold()
                    //.foregroundColor(.secondary)
                    .foregroundColor(viewModel.areYouOKResponseTimeLeft < 30 ? .red : .primary)               .multilineTextAlignment(.center)
            }
            .padding(40)
            .presentationDetents([.medium])
        }
    }
}
