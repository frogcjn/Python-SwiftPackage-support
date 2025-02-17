// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let dylibModuleNames = [
    "_asyncio",
    "_bisect",
    "_blake2",
    "_bz2",
    "_codecs_cn",
    "_codecs_hk",
    "_codecs_iso2022",
    "_codecs_jp",
    "_codecs_kr",
    "_codecs_tw",
    "_contextvars",
    "_csv",
    "_ctypes",
    "_ctypes_test",
    "_datetime",
    "_dbm",
    "_decimal",
    "_elementtree",
    "_hashlib",
    "_heapq",
    "_interpchannels",
    "_interpqueues",
    "_interpreters",
    "_json",
    "_lsprof",
    "_lzma",
    "_md5",
    "_multibytecodec",
    "_opcode",
    "_pickle",
    "_queue",
    "_random",
    "_sha1",
    "_sha2",
    "_sha3",
    "_socket",
    "_sqlite3",
    "_ssl",
    "_statistics",
    "_struct",
    "_testbuffer",
    "_testcapi",
    "_testclinic",
    "_testclinic_limited",
    "_testexternalinspection",
    "_testimportmultiple",
    "_testinternalcapi",
    "_testlimitedcapi",
    "_testmultiphase",
    "_testsinglephase",
    "_uuid",
    "_xxtestfuzz",
    "_zoneinfo",
    "array",
    "binascii",
    "cmath",
    "fcntl",
    "math",
    "mmap",
    "pyexpat",
    "resource",
    "select",
    "termios",
    "unicodedata",
    "xxlimited",
    "xxlimited_35",
    "xxsubtype",
    "zlib"
]

let package = Package(
    name: "PACKAGE_NAME",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "PACKAGE_NAME", targets: ["PACKAGE_NAME"]),
    ],
    targets: [
        .target(
            name: "PACKAGE_NAME",
            dependencies: [
                .target(name: "Python")
            ] + dylibModuleNames.map {
                .target(name: $0, condition: .when(platforms: [.iOS]))
            }
        ),
        .binaryTarget(
            name: "Python",
            path: "Sources/Python/Python.xcframework"
        )
    ] + dylibModuleNames.map {
        .binaryTarget(
            name: $0,
            path: "Sources/\($0)/\($0).xcframework"
        )
    }
)
