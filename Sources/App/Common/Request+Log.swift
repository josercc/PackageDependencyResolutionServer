import Vapor

extension Request {
    /// 记录日志
    ///
    /// - Parameters:
    ///   - content: 日志内容
    ///   - requestId: 请求ID
    /// - Returns: 日志
    func log(content: String, requestId: UUID) async throws {
        self.logger.info(Logger.Message(stringLiteral: "Log: \(content)"))
        let log = Log(content: content, requestId: requestId)
        try await log.save(on: self.db)
    }
}