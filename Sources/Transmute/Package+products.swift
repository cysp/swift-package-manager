/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageType

extension Package {
    func products(modules: [Module], tests testModules: [TestModule]) throws -> [Product] {

        var products = [Product]()

    ////// first auto-determine executables

        for case let module as SwiftModule in modules {
            if module.type == .Executable {
                let product = Product(name: module.name, type: .Executable, modules: [module])
                products.append(product)
            }
        }

    ////// auto-determine tests

        if !testModules.isEmpty {
            let modules: [SwiftModule] = testModules.map{$0} // or linux compiler crash (2016-02-03)
            //TODO name should be package name
            //TODO and then we should prefix all modules with their package probably
            let product = Product(name: "Package", type: .Test, modules: modules)
            products.append(product)
        }

    ////// add products from the manifest

        for p in manifest.products {
            //FIXME no bang
            let modules = p.modules.map{ (moduleName: String) -> Module in
                switch modules.pick({ $0.name == moduleName }) {
                case let module as SwiftModule:
                    return module
                case let module as ClangModule:
                    return module
                case let module:
                    fatalError("unexpected module type: \(module)")
                }
            }
            let product = Product(name: p.name, type: p.type, modules: modules)
            products.append(product)
        }

        return products
    }
}
