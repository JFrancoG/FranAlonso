//
//  ContentView.swift
//  FranAlonso
//
//  Created by Jesús Franco on 11.06.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(LocalizedStringResource.bootstrapWelcomeTitle)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
