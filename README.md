# Python Swift Package Support

1. Clone this repo
2. Run `make.sh` in Shell
    1. It will download compiled Python.xcframework from Python-Apple-Support ([3.13.b3 release](https://github.com/beeware/Python-Apple-support/releases/tag/3.13-b3))
    2. It will create an empty Swift Package and
    3. It will install them into the Swift Package, Patch on Python.xcframework for iOS and macOS, and dynamic libs (lib-dynload/*.so) in iOS.
3. You know have Swift Package version of Python 3.13.0 could embed into your Swift apps and libraries, without any additional work, just `import Python`!
4. Open the Example App, Enjoy!

![Screenshot_macOS](https://github.com/user-attachments/assets/ae1f2e22-4252-447a-b913-6e7bfe9e58a3)
![Screenshot_iOS](https://github.com/user-attachments/assets/a1867aac-7c21-40d7-a64b-a7eea37117c3)
