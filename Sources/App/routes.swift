import Fluent
import Vapor

func routes(_ app: Application) throws {
    /// 添加 Package 解析路由
    try app.register(collection: PackageController())
}
