// ContentView.swift
// This is the main view file. It handles the setup, timers, contact selection, and display.

import SwiftUI
import Contacts
import ContactsUI
import MessageUI  // For future texting; not used yet but imported for later development
import UIKit
import Combine


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
    @State private var responseSecondsLeft = 90  // how long they get to answer "Are you OK?"
    @State private var showResponsePrompt = false
    @State private var showEscalation = false
    @State private var inactivityTimer: Timer? = nil
    @State private var responseTimer: Timer? = nil
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
        .sheet(isPresented: $showResponsePrompt) {
            responsePromptView
        }
        .overlay {
            if showEscalation {
                escalationView
            }
        }
    }
    
    // The check-in prompt. This is a real view in the hierarchy (a sheet), which is
    // why it actually appears — an earlier version built the "are you OK" text inside
    // a plain function, where SwiftUI builds it, discards it, and shows nothing.
    var responsePromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.blue)
            
            Text("Are you OK?")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("\(responseSecondsLeft)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(responseSecondsLeft <= 15 ? .red : .primary)
            
            Text("If you don't tap below, SafeCheck will tell your emergency contacts that you haven't checked in.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: checkIn) {
                Text("I'm OK")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(28)
        .interactiveDismissDisabled()
    }
    
    // Shown after the response window expires.
    var escalationView: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()
            
            VStack(spacing: 22) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                
                Text("No check-in received")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Text("Your emergency contacts would be told that you have not checked in.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text("Nothing has actually been sent yet — server-side sending is not wired up.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.85))
                
                Button(action: cancelEscalation) {
                    Text("I'm OK — cancel")
                        .font(.title3)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
            .padding(28)
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
                inactivityTimer?.invalidate()
                startResponseWindow()
            }
        }
    }
    
    func resetInactivityTimer() {
        // Touches while the prompt or the escalation screen is up must not silently
        // restart the countdown — the prompt has its own explicit "I'm OK" button.
        guard !showResponsePrompt, !showEscalation else { return }
        startInactivityTimer()  // Resets the timer
    }
    
    func startResponseWindow() {
        UIApplication.shared.isIdleTimerDisabled = true  // keep the screen awake so the prompt is seen
        responseSecondsLeft = 90
        showResponsePrompt = true
        responseTimer?.invalidate()
        responseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            responseSecondsLeft -= 1
            if responseSecondsLeft <= 0 {
                responseTimer?.invalidate()
                escalate()
            }
        }
    }
    
    func checkIn() {
        responseTimer?.invalidate()
        responseTimer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        showResponsePrompt = false
        showEscalation = false
        startInactivityTimer()
    }
    
    func escalate() {
        showEscalation = true
        showResponsePrompt = false
        // Server-side send seam. iOS cannot send an SMS without the user tapping Send,
        // and this user by definition is not answering, so the notification has to be
        // sent from a server the app checks in to (Twilio). Not wired up yet.
        print("[SafeCheck] No check-in — escalation due for \(selectedContacts.count) contact(s)")
    }
    
    func cancelEscalation() {
        UIApplication.shared.isIdleTimerDisabled = false
        showEscalation = false
        startInactivityTimer()
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
