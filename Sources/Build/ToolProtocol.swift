/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageType
import Utility

/// Describes a tool which can be understood by llbuild's BuildSystem library.
protocol ToolProtocol {
    /// The list of inputs to declare.
    var inputs: [String] { get }
    
    /// The list of outputs to declare.
    var outputs: [String] { get }
    
    /// Write a description of the tool to the given output `stream`.
    ///
    /// This should append JSON or YAML content; if it is YAML it should be indented by 4 spaces.
    func append(to stream: OutputByteStream)
}

struct ShellTool: ToolProtocol {
    let description: String
    let inputs: [String]
    let outputs: [String]
    let args: [String]

    func append(to stream: OutputByteStream) {
        stream <<< "    tool: shell\n"
        stream <<< "    description: " <<< Format.asJSON(description) <<< "\n"
        stream <<< "    inputs: " <<< Format.asJSON(inputs) <<< "\n"
        stream <<< "    outputs: " <<< Format.asJSON(outputs) <<< "\n"
    
        // If one argument is specified we assume pre-escaped and have llbuild
        // execute it passed through to the shell.
        if self.args.count == 1 {
            stream <<< "    args: " <<< Format.asJSON(args[0]) <<< "\n"
        } else {
            stream <<< "    args: " <<< Format.asJSON(args) <<< "\n"
        }
    }
}


struct SwiftcTool: ToolProtocol {
    let module: SwiftModule
    let prefix: String
    let otherArgs: [String]
    let executable: String
    let conf: Configuration
    static let numThreads = 8

    var inputs: [String] {
        return module.recursiveDependencies.flatMap{ (module: Module) -> [String] in
            switch module {
            case is SwiftModule, is CModule:
                return [module.targetName]
            case let module as ClangModule:
                let wd = Path.join(prefix, "\(module.c99name).build")
                return [module.targetName, Path.join(wd, "\(module.c99name).o")]
            case _:
                fatalError("unexpected Module type: \(module.dynamicType)")
            }
        }
    }

    var outputs: [String]                   { return [module.targetName] + objects }
    var moduleName: String                  { return module.c99name }
    var moduleOutputPath: String            { return Path.join(prefix, "\(module.c99name).swiftmodule") }
    var importPaths: [String]               { return [prefix] }
    var tempsPath: String                   { return Path.join(prefix, "\(module.c99name).build") }
    var objects: [String]                   { return module.sources.relativePaths.map{ Path.join(tempsPath, "\($0).o") } }
    var sources: [String]                   { return module.sources.paths }
    var isLibrary: Bool                     { return module.type == .Library }
    var enableWholeModuleOptimization: Bool { return conf == .Release }

    func append(to stream: OutputByteStream) {
        stream <<< "    tool: swift-compiler\n"
        stream <<< "    executable: " <<< Format.asJSON(executable) <<< "\n"
        stream <<< "    module-name: " <<< Format.asJSON(moduleName) <<< "\n"
        stream <<< "    module-output-path: " <<< Format.asJSON(moduleOutputPath) <<< "\n"
        stream <<< "    inputs: " <<< Format.asJSON(inputs) <<< "\n"
        stream <<< "    outputs: " <<< Format.asJSON(outputs) <<< "\n"
        stream <<< "    import-paths: " <<< Format.asJSON(importPaths) <<< "\n"
        stream <<< "    temps-path: " <<< Format.asJSON(tempsPath) <<< "\n"
        stream <<< "    objects: " <<< Format.asJSON(objects) <<< "\n"
        stream <<< "    other-args: " <<< Format.asJSON(otherArgs) <<< "\n"
        stream <<< "    sources: " <<< Format.asJSON(sources) <<< "\n"
        stream <<< "    is-library: " <<< Format.asJSON(isLibrary) <<< "\n"
        stream <<< "    enable-whole-module-optimization: " <<< Format.asJSON(enableWholeModuleOptimization) <<< "\n"
        stream <<< "    num-threads: " <<< Format.asJSON("\(SwiftcTool.numThreads)") <<< "\n"
    }
}

struct Target {
    let node: String
    var cmds: [Command]
}

struct ClangTool: ToolProtocol {
    let desc: String
    let inputs: [String]
    let outputs: [String]
    let args: [String]
    let deps: String?

    func append(to stream: OutputByteStream) {
        stream <<< "    tool: clang\n"
        stream <<< "    description: " <<< Format.asJSON(desc) <<< "\n"
        stream <<< "    inputs: " <<< Format.asJSON(inputs) <<< "\n"
        stream <<< "    outputs: " <<< Format.asJSON(outputs) <<< "\n"
        // FIXME: This does not work for paths with spaces.
        stream <<< "    args: " <<< Format.asJSON(args.joined(separator: " ")) <<< "\n"
        if let deps = deps {
            stream <<< "    deps: " <<< Format.asJSON(deps) <<< "\n"
        }
    }
}

struct ArchiveTool: ToolProtocol {
    let inputs: [String]
    let outputs: [String]

    func append(to stream: OutputByteStream) {
        stream <<< "    tool: archive\n"
        stream <<< "    inputs: " <<< Format.asJSON(inputs) <<< "\n"
        stream <<< "    outputs: " <<< Format.asJSON(outputs) <<< "\n"
    }
}
