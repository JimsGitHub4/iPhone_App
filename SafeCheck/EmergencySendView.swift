//
//  EmergencySendView.swift
//  SafeCheck
//
//  Created by Jim Bouldin on 12/24/25.
//

import SwiftUI

struct EmergencySendView: View {
    var selectedContacts: [String]
    
    var body: some View {
        VStack {
            Text("Emergency Alert")
                .font(.title)
            if selectedContacts.isEmpty {
                Text("No contacts selected.")
            } else {
                List(selectedContacts, id: \.self) { contact in
                    Text("Alert to: \(contact)")
                }
                Button("Send Now") {
                    // Simulate send
                    print("Emergency sent to: \(selectedContacts)")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Send Alert")
    }
}

#Preview {
    EmergencySendView(selectedContacts: [])
}
