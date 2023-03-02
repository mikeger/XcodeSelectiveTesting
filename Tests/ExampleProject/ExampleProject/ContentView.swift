//
//  ContentView.swift
//  ExampleProject
//
//  Created by Mike on 02.03.23.
//

import SwiftUI
import ExampleLibrary
import ExmapleTargetLibrary
import ExamplePackage

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(ExampleLibrary.exampleText())
            Text(ExampleTargetLibrary.exampleTargetText())
            Text(ExamplePackage.exampleText())
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
