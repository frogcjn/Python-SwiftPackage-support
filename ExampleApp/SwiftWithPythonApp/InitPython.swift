import Foundation
import Python

func setEnvs() {
    #if os(macOS)
    print("macOS do not need set envs")
    #else
    print("iOS need set envs")
    print(Bundle.allBundles)
    print(Bundle.allFrameworks)
    print(Bundle.main.bundleURL)
    guard let pythonHome = Bundle.main.path(forResource: "Frameworks/Python.framework/Resources/python", ofType: nil) else { return }
    setenv("PYTHONHOME", pythonHome, 1)

    /*
         The PYTHONPATH for the interpreter includes:
         the python/lib/python3.X subfolder of your app’s bundle,
         the python/lib/python3.X/lib-dynload subfolder of your app’s bundle, and
         the app subfolder of your app’s bundle
    */
    guard let pythonPath = Bundle.main.path(forResource: "Frameworks/Python.framework/Resources/python/lib/python3.13", ofType: nil) else { return }
    guard let libDynLoad = Bundle.main.path(forResource: "Frameworks/Python.framework/Resources/python/lib/python3.13/lib-dynload", ofType: nil) else { return }
    let appPath = Bundle.main.path(forResource: "app", ofType: nil)
    setenv("PYTHONPATH", [pythonPath, libDynLoad, appPath].compactMap { $0 }.joined(separator: ":"), 1)
    #endif
}

// Init Python Part (Neccessary)
var version: String = "Not Available"
func initPythonSimpleVersion() {
    print("init Python")
    
    setEnvs()
    //Py_Initialize()
    // we now have a Python interpreter ready to be used

    version = String(cString: Py_GetVersion())
    print(version)
    print("init Success")
    
}

// Test PythonKit Part (Optional)
import PythonKit
func testPythonKit() {
    print("test PythonKit")
    
    let sys = Python.import("sys")
    version = version + "\nPythonKit: \(sys.version)"
    print(version)
    print("Python Version: \(sys.version_info.major).\(sys.version_info.minor)")
    print("Python Encoding: \(sys.getdefaultencoding().upper())")
    print("Python Path: \(sys.path)")
    let platform = Python.import("platform")
    print("Python Platform: \(platform.system())")
    print("finish")
    let math = Python.import("math") // verifies `lib-dynload` is found and signed successfully
    print(math)
    print("Python math.pi: \(math.pi)")
}
