// ContentView.swift
// This is the main view file. It handles the setup, timers, contact selection, and display.

import SwiftUI
import Contacts
import ContactsUI
import MessageUI  // For future texting; not used yet but imported for later development
import UIKit
internal import Combine


struct Contact {
    let name: String
    let phone: String
}

struct ContactPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let completion: ([CNContact]) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        // Allow only contacts with phone numbers
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        picker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count > 0")
        // Display phone numbers
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.completion(contacts)
            parent.isPresented = false
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }
    }
}

struct ContentView: View {
    @State private var showSetup = true
    @State private var selectedContacts: [Contact] = []
    @State private var showContactPicker = false
    @State private var manualName: String = ""
    @State private var manualPhone: String = ""
    @State private var showAreYouOK = false
    @State private var setupCountdown = 120  // 2 minutes
    @State private var inactivityCountdown = 240  // 4 minutes for testing
    @State private var showInactivityAlert = false
    @State private var inactivityTimer: Timer? = nil
    @State private var hasContactsPermission = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if showSetup {
            setupView
        } else {
            mainView
        }
    }
    
    var setupView: some View {
        VStack(spacing: 20) {
            ShieldView()
                .frame(width: 100, height: 100)
            
            Text("SafeCheck Setup")
                .font(.title)
            
            Text("Setup Countdown: \(setupCountdown) seconds")
            
            if selectedContacts.count < 3 {
                Button("Select from Contacts") {
                    requestContactsPermission {
                        showContactPicker = true
                    }
                }
                
                HStack {
                    TextField("Name", text: $manualName)
                    TextField("Phone", text: $manualPhone)
                    Button("Add Manual") {
                        if !manualName.isEmpty && !manualPhone.isEmpty && selectedContacts.count < 3 {
                            selectedContacts.append(Contact(name: manualName, phone: manualPhone))
                            manualName = ""
                            manualPhone = ""
                        }
                    }
                }
                .padding()
            }
            
            List {
                ForEach(selectedContacts, id: \.phone) { contact in
                    Text("\(contact.name): \(contact.phone)")
                }
            }
            
            if selectedContacts.count >= 1 {
                Button("Complete Setup") {
                    showSetup = false
                }
            }
            
            Text("Select 1-3 emergency contacts.")
                .font(.subheadline)
        }
        .padding()
        .onAppear {
            // Start setup timer
            setupCountdown = 120
        }
        .onReceive(timer) { _ in
            if showSetup && setupCountdown > 0 {
                setupCountdown -= 1
                if setupCountdown <= 0 {
                    showAreYouOK = true
                }
            }
        }
        .alert("Are you OK?", isPresented: $showAreYouOK) {
            Button("Yes") {
                // For now, just dismiss. In future, could reset or proceed.
            }
        } message: {
            Text("Please respond to continue setup.")
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPicker(isPresented: $showContactPicker) { cnContacts in
                let newContacts = cnContacts.map { cnContact -> Contact in
                    let name = "\(cnContact.givenName) \(cnContact.familyName)"
                    let phone = cnContact.phoneNumbers.first?.value.stringValue ?? ""
                    return Contact(name: name, phone: phone)
                }
                selectedContacts.append(contentsOf: newContacts)
                if selectedContacts.count > 3 {
                    selectedContacts = Array(selectedContacts.prefix(3))
                }
            }
        }
    }
    
    var mainView: some View {
        VStack(spacing: 20) {
            ShieldView()
                .frame(width: 100, height: 100)
            
            Text("SafeCheck Active")
                .font(.title)
            
            Text("Inactivity Countdown (for testing): \(inactivityCountdown) seconds")
            
            Text("Touch anywhere to reset inactivity timer.")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())  // Make the whole view tappable
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in resetInactivityTimer() }
                .onEnded { _ in resetInactivityTimer() }
        )
        .onAppear {
            startInactivityTimer()
        }
        .alert("Alert", isPresented: $showInactivityAlert) {
            Button("OK") {
                // For now, just dismiss. Later, could reset.
                resetInactivityTimer()
            }
        } message: {
            Text("Contact the iPhone's Owner because they have not interacted with their phone for 4 minutes.")  // Emulate for testing; later change to hours and text
        }
    }
    
    func requestContactsPermission(completion: @escaping () -> Void) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    hasContactsPermission = true
                    completion()
                } else {
                    // Handle denial; for now, do nothing
                }
            }
        }
    }
    
    func startInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityCountdown = 240
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            inactivityCountdown -= 1
            if inactivityCountdown <= 0 {
                showInactivityAlert = true
                inactivityTimer?.invalidate()
                // For later development: Send texts here
                // let recipients = selectedContacts.map { $0.phone }
                // Present MessageComposer(recipients: recipients, bodyText: "Contact the owner...", completion: { _ in })
            }
        }
    }
    
    func resetInactivityTimer() {
        startInactivityTimer()  // Resets the timer
    }
}

struct ShieldView: View {
    var body: some View {
        ZStack {
            Image(systemName: "shield.fill")
                .foregroundColor(.blue)
                .font(.system(size: 100))
            Image(systemName: "shield")
                .foregroundColor(.white)
                .font(.system(size: 100))
        }
    }
}

#Preview {
    ContentView()
}
