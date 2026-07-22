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

#Preview {
    ContentView()
        .environment(
            \.appDependencies,
            AppDependencies.preview(
                clients: [
                    Client(
                        id: ClientID(
                            rawValue: UUID(
                                uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
                            )!
                        ),
                        displayName: "Ana Alonso"
                    )
                ]
            )
        )
}
