
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
        print(packageContent.removingPercentEncoding)
        /// 获取一个随机的 UUID 用于保存当前请求解析的日志
        let uuid = UUID()
        /// 获取当前环境的目录 用于存储临时的Package.swift 文件
        guard let pwd = ProcessInfo.processInfo.environment["PWD"] else {
            return ResponseContent(status: 500, message: "PWD not found")
        }
        /// 临时操作的目录
        let tempDir = pwd + "/\(uuid.uuidString)"
        defer {
            /// 结束删除临时的操作目录
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        try await req.log(content: "当前临时操作目录为:\(tempDir)", requestId: uuid)
        try await req.log(content: "获取 \(tempDir) 是否存在", requestId: uuid)
        let isExist = FileManager.default.fileExists(atPath: tempDir)
        if isExist {
            try await req.log(content: "删除 \(tempDir)", requestId: uuid)
            try FileManager.default.removeItem(atPath: tempDir)
        } else {
            try await req.log(content: "\(tempDir) 不存在 正在创建", requestId: uuid)
            try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true, attributes: nil)
        }
        /// 需要保存的 Package.swift 的目录
        let packageFile = tempDir + "/Package.swift"
        try await req.log(content: "将 \(packageContent) 写入 \(packageFile)", requestId: uuid)
        try packageContent.write(toFile: packageFile, atomically: true, encoding: .utf8)
        /// 获取CustomContext
        var context = CustomContext()
        /// 设置当前运行目录
        context.currentdirectory = tempDir
        /// 设置当前运行的环境变量
        context.env = ProcessInfo.processInfo.environment
        try await req.log(content: "执行 Swift Package Manager 的 dump-package 命令", requestId: uuid)
        let command = context.runAsync("swift", "package", "dump-package")
        command.resume()
        /// 获取命令输入的内容
        let output = command.stdout.read()
        try await req.log(content: "获取的内容:\(output)", requestId: uuid)
        guard let data = output.data(using: .utf8) else {
            throw Abort(.expectationFailed)
        }
        guard let result = try? JSONDecoder().decode(DumpPackageResponse.self, from: data) else {
            try await req.log(content: "Package Content 格式错误,或者不支持Swift5.0版本以上。", requestId: uuid)
            throw Abort(.custom(code: 500, reasonPhrase: "Package Contnt 格式错误,或者不支持Swift5.0版本以上。"))
        }
        /// 遍历依赖的库
        for dependencie in result.dependencies {
            let data = try JSONEncoder().encode(dependencie) 
            let json = String(data: data, encoding: .utf8)
            try await req.log(content: "依赖库:\(json ?? "")", requestId: uuid)
            guard let sourceControl = dependencie.sourceControl.first else {
                continue
            }
            guard let remote = sourceControl.location.remote.first else {
                continue
            }
            guard remote.contains("https://github.com/") else {
                continue
            }
            let repo = remote.replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: ".git", with: "")
            if let _ = sourceControl.requirement.range?.first {
                /// 依赖版本区间
                /// 获取所有的 release版本
                let releases = try await req.getGithubRepoTag(from: repo)
                print(releases)
            } else if let _ = sourceControl.requirement.exact?.first {
                /// 依赖指定版本
            } else if let _ = sourceControl.requirement.branch?.first {
                /// 依赖指定分支
            } else if let _ = sourceControl.requirement.revision?.first {
                /// 依赖指定提交
            } else {
                throw Abort(.badRequest, reason: "sourceControl.requirement 不支持")
            }
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

