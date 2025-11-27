//
//  ContactsView.swift
//  SafeCheck
//
//  Created by User on 11/25/25.
//

// ContactsView.swift
import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var manager: CheckInManager
    
    var body: some View {
        List {
            ForEach(manager.emergencyContacts) { contact in
                HStack {
                    Text(contact.name)
                    Spacer()
                    Text(contact.phone)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete(perform: deleteContact)
            
            if manager.emergencyContacts.count < 3 {
                NavigationLink("Add Contact") {
                    AddContactView()
                }
            }
        }
        .navigationTitle("Emergency Contacts")
    }
    
    func deleteContact(at offsets: IndexSet) {
        manager.emergencyContacts.remove(atOffsets: offsets)
    }
}

// AddContactView.swift
import SwiftUI

struct AddContactView: View {
    @EnvironmentObject var manager: CheckInManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var phone = ""
    
    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Phone (e.g. +15551234567)", text: $phone)
            
            Button("Save Contact") {
                let contact = Contact(name: name, phone: phone)
                manager.emergencyContacts.append(contact)
                presentationMode.wrappedValue.dismiss()
            }
            .disabled(name.isEmpty || phone.isEmpty || manager.emergencyContacts.count >= 3)
        }
        .navigationTitle("Add Contact")
    }
}
