/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import struct Utility.Path
import func POSIX.symlink
import func Utility.walk
import func POSIX.rename
import func POSIX.mkdir
import func POSIX.popen
import XCTest

#if os(OSX)
let dylibExtension = "dylib"
#else
let dylibExtension = "so"
#endif

class TestClangModulesTestCase: XCTestCase {
    
    func testSingleModuleFlatCLibrary() {
        fixture(name: "ClangModules/CLibraryFlat") { prefix in
            XCTAssertBuilds(prefix)
            XCTAssertFileExists(prefix, ".build", "debug", "libCLibraryFlat."+dylibExtension)
        }
    }
    
    func testSingleModuleCLibraryInSources() {
        fixture(name: "ClangModules/CLibrarySources") { prefix in
            XCTAssertBuilds(prefix)
            XCTAssertFileExists(prefix, ".build", "debug", "libCLibrarySources."+dylibExtension)
        }
    }
    
    func testMixedSwiftAndC() {
        fixture(name: "ClangModules/SwiftCMixed") { prefix in
            XCTAssertBuilds(prefix)
            XCTAssertFileExists(prefix, ".build", "debug", "libSeaLib.\(dylibExtension)")
            let exec = ".build/debug/SeaExec"
            XCTAssertFileExists(prefix, exec)
            let output = try popen([Path.join(prefix, exec)])
            XCTAssertEqual(output, "a = 5\n")
        }
    }
    
    func testExternalSimpleCDep() {
        fixture(name: "DependencyResolution/External/SimpleCDep") { prefix in
            XCTAssertBuilds(prefix, "Bar")
            XCTAssertFileExists(prefix, "Bar/.build/debug/Bar")
            XCTAssertFileExists(prefix, "Bar/.build/debug/libFoo."+dylibExtension)
            XCTAssertDirectoryExists(prefix, "Bar/Packages/Foo-1.2.3")
        }
    }
    
    func testiquoteDep() {
        fixture(name: "ClangModules/CLibraryiquote") { prefix in
            XCTAssertBuilds(prefix)
            XCTAssertFileExists(prefix, ".build", "debug", "libFoo."+dylibExtension)
            XCTAssertFileExists(prefix, ".build", "debug", "libBar."+dylibExtension)
        }
    }
    
    func testCUsingCDep() {
        fixture(name: "DependencyResolution/External/CUsingCDep") { prefix in
            XCTAssertBuilds(prefix, "Bar")
            XCTAssertFileExists(prefix, "Bar/.build/debug/libFoo."+dylibExtension)
            XCTAssertDirectoryExists(prefix, "Bar/Packages/Foo-1.2.3")
        }
    }
    
    func testCExecutable() {
        fixture(name: "ValidLayouts/SingleModule/CExecutable") { prefix in
            XCTAssertBuilds(prefix)
            let exec = ".build/debug/CExecutable"
            XCTAssertFileExists(prefix, exec)
            let output = try popen([Path.join(prefix, exec)])
            XCTAssertEqual(output, "hello 5")
        }
    }
    
    func testCUsingCDep2() {
        //The C dependency "Foo" has different layout
        fixture(name: "DependencyResolution/External/CUsingCDep2") { prefix in
            XCTAssertBuilds(prefix, "Bar")
            XCTAssertFileExists(prefix, "Bar/.build/debug/libFoo.so")
            XCTAssertDirectoryExists(prefix, "Bar/Packages/Foo-1.2.3")
        }
    }
    
    func testModuleMapGenerationCases() {
        fixture(name: "ClangModules/ModuleMapGenerationCases") { prefix in
            XCTAssertBuilds(prefix)
            XCTAssertFileExists(prefix, ".build", "debug", "libUmbrellaHeader.so")
            XCTAssertFileExists(prefix, ".build", "debug", "libFlatInclude.so")
            XCTAssertFileExists(prefix, ".build", "debug", "libUmbellaModuleNameInclude.so")
            XCTAssertFileExists(prefix, ".build", "debug", "libNoIncludeDir.so")
            XCTAssertFileExists(prefix, ".build", "debug", "Baz")
        }
    }
}


extension TestClangModulesTestCase {
    static var allTests : [(String, (TestClangModulesTestCase) -> () throws -> Void)] {
        return [
            ("testSingleModuleFlatCLibrary", testSingleModuleFlatCLibrary),
            ("testSingleModuleCLibraryInSources", testSingleModuleCLibraryInSources),
            ("testMixedSwiftAndC", testMixedSwiftAndC),
            ("testExternalSimpleCDep", testExternalSimpleCDep),
            ("testiquoteDep", testiquoteDep),
            ("testCUsingCDep", testCUsingCDep),
            ("testCExecutable", testCExecutable),
            ("testModuleMapGenerationCases", testModuleMapGenerationCases),
        ]
    }
}
