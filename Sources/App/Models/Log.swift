import Vapor
import FluentKit
final class Log: Model {
    static var schema: String { "log" }
    
    @ID(key: .id)
    var id: UUID?

    /// 日志内容
    @Field(key: "content")
    var content: String

    /// 创建时间
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    /// 请求ID
    @Field(key: "request_id")
    var requestId: UUID

    /// 初始化
    init() { }

    /// 初始化
    init(id: UUID? = nil, content: String, requestId: UUID) {
        self.id = id
        self.content = content
        self.requestId = requestId
    }
}