import ExampleLibrary
import ExamplePackage
import ExmapleTargetLibrary
import SwiftUI

struct FolderContentView: View {
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

struct FolderContentView_Previews: PreviewProvider {
    static var previews: some View {
        FolderContentView()
    }
}
