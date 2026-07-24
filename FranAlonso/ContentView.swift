//
//  ContentView.swift
//  FranAlonso
//
//  Created by Jesús Franco on 11.06.2026.
//

import SwiftUI

@MainActor
struct ContentView: View {
    @Environment(\.appDependencies) private var dependencies

    var body: some View {
        NavigationStack {
            ClientListScreen(observeClients: dependencies.observeClients)
        }
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    ContentView()
}
