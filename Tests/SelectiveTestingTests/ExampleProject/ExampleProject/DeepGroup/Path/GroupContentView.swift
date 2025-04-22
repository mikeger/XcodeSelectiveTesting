//
//  GroupContentView.swift
//  ExampleProject
//
//  Created by Mike on 02.03.23.
//

import ExampleLibrary
import ExamplePackage
import ExmapleTargetLibrary
import SwiftUI

struct GroupContentView: View {
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

struct GroupContentView_Previews: PreviewProvider {
    static var previews: some View {
        GroupContentView()
    }
}
