/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageType
import Utility

extension Command {
    static func compile(swiftModule module: SwiftModule, configuration conf: Configuration, prefix: String, otherArgs: [String]) throws -> (Command, [Command]) {

        let otherArgs = otherArgs + module.Xcc /*+ recursiveDependencies([module]).flatMap({ (module: Module) -> [String] in
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


        func cmd(tool: ToolProtocol) -> Command {
            return Command(node: module.targetName, tool: tool)
        }

        switch conf {
        case .Debug:
            var args = ["-j8","-Onone","-g","-D","SWIFT_PACKAGE", "-enable-testing"]

        #if os(OSX)
            if let platformPath = Toolchain.platformPath {
                let path = Path.join(platformPath, "Developer/Library/Frameworks")
                args += ["-F", path]
            } else {
                throw Error.InvalidPlatformPath
            }
        #endif
            let tool = SwiftcTool(module: module, prefix: prefix, otherArgs: args + otherArgs)
            let mkdirs = Set(tool.objects.map{ $0.parentDirectory }).map(Command.createDirectory)
            return (cmd(tool), mkdirs)

        case .Release:
            let inputs = module.dependencies.map{ $0.targetName } + module.sources.paths
            var args = ["-c", "-emit-module", "-D", "SWIFT_PACKAGE", "-O", "-whole-module-optimization", "-I", prefix] + otherArgs
            let productPath = Path.join(prefix, "\(module.c99name).o")

            if module.type == .Library {
                args += ["-parse-as-library"]
            }

            let tool = ShellTool(
                description: "Compiling \(module.name)",
                inputs: inputs,
                outputs: [productPath, module.targetName],
                args: [Toolchain.swiftc, "-o", productPath] + args + module.sources.paths + otherArgs)

            return (cmd(tool), [])
        }
    }
}
