
import Vapor
import SwiftShell
import Foundation
struct PackageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let packages = routes.grouped("packages")
        packages.post(use: createHandler)
    }

    func createHandler(_ req: Request) async throws -> ResponseContent<String> {
        try CreateRequest.validate(content: req)
        let package = try req.content.decode(CreateRequest.self)
        let uuid = UUID()
        guard let pwd = ProcessInfo.processInfo.environment["PWD"] else {
            return ResponseContent(status: 500, message: "PWD not found")
        }
        let tempDir = pwd + "/\(uuid.uuidString)"
        let dumpPackageResponse:DumpPackageResponse = try await req.application.threadPool.runIfActive(eventLoop: req.eventLoop, {
            defer {
                try? FileManager.default.removeItem(atPath: tempDir)
            }
            /// 获取 tempDir 是否存在
            let isExist = FileManager.default.fileExists(atPath: tempDir)
            if isExist {
                try FileManager.default.removeItem(atPath: tempDir)
            }
            let packageFile = tempDir + "/Package.swift"
            /// 将 package.content 写入到文件中
            try package.content.write(toFile: packageFile, atomically: true, encoding: .utf8)
            try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true, attributes: nil)
            /// 获取CustomContext
            var context = CustomContext()
            context.currentdirectory = tempDir
            context.env = ProcessInfo.processInfo.environment
            let command = context.runAsync("swift", "package", "dump-package")
            command.resume()
            let output = command.stdout.read()
            guard let data = output.data(using: .utf8) else {
                throw Abort(.expectationFailed)
            }
            guard let result = try? JSONDecoder().decode(DumpPackageResponse.self, from: data) else {
                throw Abort(.custom(code: 500, reasonPhrase: "Package Contnt 格式错误,或者不支持Swift5.0版本以上。"))
            }
            return result
            
        }).get()
        return ResponseContent(message: "success", data: package.content)
    }
}

extension PackageController {
    struct CreateRequest: Content, Validatable {
        var content: String

        static func validations(_ validations: inout Validations) {
            validations.add("content", as: String.self, is: !.empty)
        }
    }
}

