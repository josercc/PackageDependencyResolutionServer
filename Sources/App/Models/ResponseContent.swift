import Vapor
struct ResponseContent<T: Content>: Content {
    let status: Int
    let message: String
    let data: T?
    let isSuccess: Bool

    /// 成功
    init(message: String = "success", data: T? = nil) {
        self.status = 0
        self.message = message
        self.data = data
        self.isSuccess = true
    }

    /// 失败
    init(status: Int = 500, message: String = "failure", data: T? = nil) {
        self.status = status
        self.message = message
        self.data = data
        self.isSuccess = false
    }

}
