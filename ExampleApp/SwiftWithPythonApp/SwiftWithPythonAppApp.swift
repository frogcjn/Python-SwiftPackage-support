import SwiftUI

@main
struct SwiftPythonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    init() {
        initPythonSimpleVersion()
        testPythonKit() // this line is needed only when you want to test PythonKit
    }
}
