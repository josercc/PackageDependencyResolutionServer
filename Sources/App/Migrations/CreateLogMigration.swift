import FluentKit
import Vapor

struct CreateLogMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Log.schema)
            .id()
            .field("content", .string, .required)
            .field("request_id", .uuid, .required)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Log.schema).delete()
    }
}