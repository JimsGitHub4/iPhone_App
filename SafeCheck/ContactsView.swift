//
//  ContactsView.swift
//  SafeCheck
//
//  Created by Jim Bouldin on 12/24/25.
//

import SwiftUI

struct ContactsView: View {
    @Binding var selectedContacts: [String]
    
    var body: some View {
        List {
            // Placeholder contacts; integrate Contacts framework later
            ForEach(["Contact 1", "Contact 2", "Contact 3"], id: \.self) { contact in
                Button(contact) {
                    if !selectedContacts.contains(contact) {
                        selectedContacts.append(contact)
                    }
                }
            }
        }
        .navigationTitle("Select Contacts")
    }
}

#Preview {
    ContactsView(selectedContacts: .constant([]))
}
