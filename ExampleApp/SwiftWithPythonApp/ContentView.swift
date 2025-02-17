import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("🐍")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, Python Version: \(version)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
