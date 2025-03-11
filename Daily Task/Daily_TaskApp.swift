//
//  Daily_TaskApp.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-02-28.
//

import SwiftUI
import CloudKit


@main
struct Daily_TaskApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showSignIn = false

    var body: some Scene {
        WindowGroup {
            Group {
                if showSignIn {
                    SignInView()
                } else {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
            .onAppear {
                CKContainer.default().accountStatus { status, error in
                    DispatchQueue.main.async {
                        if status != .available {
                            showSignIn = true
                        }
                    }
                }
            }
        }
    }
}

struct SignInView: View {
    @State private var accountStatus: CKAccountStatus = .couldNotDetermine

    var body: some View {
        VStack(spacing: 20) {
            Text("Please sign in to iCloud")
                .font(.title)
            Text("To enable cloud syncing, please sign in to iCloud in your device settings or use Sign in with Apple.")
                .multilineTextAlignment(.center)
            Button("Check Account Status") {
                CKContainer.default().accountStatus { status, error in
                    DispatchQueue.main.async {
                        self.accountStatus = status
                    }
                }
            }
            // Optionally, if you integrate Sign in with Apple, add that button here.
        }
        .padding()
    }
}
