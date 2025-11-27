//
//  EmergencySendView.swift
//  SafeCheck
//
//  Created by User on 11/25/25.
//

// EmergencySendView.swift
import SwiftUI
import MessageUI

struct EmergencySendView: View {
    @EnvironmentObject var manager: CheckInManager
    @State private var isShowingMessage = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Emergency Alert")
                .font(.title)
                .bold()
            
            Text("Your check-in timer has expired.\nTap below to send a help message to your emergency contacts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if MFMessageComposeViewController.canSendText() {
                Button("Send Help Message Now") {
                    isShowingMessage = true
                }
                .font(.title2)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            } else {
                Text("This device cannot send SMS messages")
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Button("I'm Safe – Cancel Alert") {
                manager.userIsSafe()
            }
            .padding()
        }
        .padding()
        .sheet(isPresented: $isShowingMessage) {
            MessageView(contacts: manager.emergencyContacts)
        }
    }
}

// MARK: - SMS Composer (iOS 15 compatible)
struct MessageView: UIViewControllerRepresentable {
    let contacts: [Contact]
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = contacts.map { $0.phone }
        vc.messageComposeDelegate = context.coordinator
        
        // Simple test location – replace later with real one
        let mapLink = "https://maps.apple.com/?ll=37.3318,-122.0312&q=Possible%20Location"
        
        vc.body = """
        AUTOMATED SAFECHECK ALERT
        
        I may need help. I did not check in on time.
        
        Last known location: \(mapLink)
        
        Sent: \(Date())
        """
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageView
        
        init(parent: MessageView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
    
    // iOS 15 safe date formatter
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
}
