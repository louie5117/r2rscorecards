// StartupFailureView.swift
// Shown when the app cannot create a local data store at launch.

import SwiftUI

struct StartupFailureView: View {
    let errorMessage: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Startup Error")
                        .font(.title.bold())
                    Text("The app could not create a local data store, so it cannot continue safely.")
                        .foregroundStyle(.secondary)
                    Text("Details:")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("r2rscorecards")
        }
    }
}
