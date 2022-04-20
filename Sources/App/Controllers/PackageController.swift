
import Vapor
import SwiftShell
import Foundation
struct PackageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let packages = routes.grouped("packages")
        packages.post(use: createHandler)
    }

    func createHandler(_ req: Request) async throws -> ResponseContent<String> {
        /// 验证请求的内容
        try CreateRequest.validate(content: req)
        let package = try req.content.decode(CreateRequest.self)
        guard let packageContent = package.content.base64Decode() else {
            throw Abort(.badRequest, reason: "packageContent is not base64")
        }
        /// 获取一个随机的 UUID 用于保存当前请求解析的日志
        let uuid = UUID()
        /// 获取当前环境的目录 用于存储临时的Package.swift 文件
        guard let pwd = ProcessInfo.processInfo.environment["PWD"] else {
            return ResponseContent(status: 500, message: "PWD not found")
        }
        /// 临时操作的目录
        let tempDir = pwd + "/\(uuid.uuidString)"
        /// 获取当前内容的依赖
        let dumpPackageResponse:DumpPackageResponse = try await req.application.threadPool.runIfActive(eventLoop: req.eventLoop, {
            defer {
                /// 结束删除临时的操作目录
                try? FileManager.default.removeItem(atPath: tempDir)
            }
            /// 获取 tempDir 是否存在
            let isExist = FileManager.default.fileExists(atPath: tempDir)
            if isExist {
                /// 如果存在就删除
                try FileManager.default.removeItem(atPath: tempDir)
            } else {
                /// 如果不存在就创建
                try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true, attributes: nil)
            }
            /// 需要保存的 Package.swift 的目录
            let packageFile = tempDir + "/Package.swift"
            /// 将 package.content 写入到文件中
            try packageContent.write(toFile: packageFile, atomically: true, encoding: .utf8)
            /// 获取CustomContext
            var context = CustomContext()
            /// 设置当前运行目录
            context.currentdirectory = tempDir
            /// 设置当前运行的环境变量
            context.env = ProcessInfo.processInfo.environment
            /// 执行 Swift Package Manager 的 dump-package 命令
            let command = context.runAsync("swift", "package", "dump-package")
            command.resume()
            /// 获取命令输入的内容
            let output = command.stdout.read()
            guard let data = output.data(using: .utf8) else {
                throw Abort(.expectationFailed)
            }
            guard let result = try? JSONDecoder().decode(DumpPackageResponse.self, from: data) else {
                throw Abort(.custom(code: 500, reasonPhrase: "Package Contnt 格式错误,或者不支持Swift5.0版本以上。"))
            }
            return result
            
        }).get()
        /// 遍历依赖的库
        for dependencie in dumpPackageResponse.dependencies {
            
        }
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

