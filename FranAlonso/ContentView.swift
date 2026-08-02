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
    let requestSignOut: @MainActor () -> Void

    var body: some View {
        ClientListScreen(observeClients: dependencies.observeClients)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        requestSignOut()
                    } label: {
                        Label {
                            Text(.authenticationRootSignOut)
                        } icon: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    NavigationStack {
        ContentView(requestSignOut: {})
    }
}
