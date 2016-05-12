/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageType
import Utility
import PkgConfig

extension Command {
    static func compile(swiftModule module: SwiftModule, configuration conf: Configuration, prefix: String, otherArgs: [String], SWIFT_EXEC: String) throws -> Command {

        let otherArgs = otherArgs + module.XccFlags(prefix) + (try module.pkgConfigSwiftcArgs()) + module.moduleCacheArgs(prefix: prefix) /*+ recursiveDependencies([module]).flatMap({ (module: Module) -> [String] in
            switch module {
            case is SwiftModule:
                return []
            case is ClangModule:
                return ["-l\(module.c99name)"]
            case let module as CModule:
                return []
            case _:
                return []
            }
        })*/
        var args = ["-j\(SwiftcTool.numThreads)", "-D", "SWIFT_PACKAGE"]

        switch conf {
        case .Debug:
            args += ["-Onone", "-g", "-enable-testing"]
        case .Release:
            args += ["-O"]
        }

        #if os(OSX)
        args += ["-F", try platformFrameworksPath()]
        #endif

        let tool = SwiftcTool(module: module, prefix: prefix, otherArgs: args + otherArgs, executable: SWIFT_EXEC, conf: conf)
        return Command(node: module.targetName, tool: tool)
    }
}
