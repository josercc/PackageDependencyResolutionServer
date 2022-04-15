
import FluentKit
struct CreatePackageMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Package.schema)
            .id()
            .field("content", .string, .required)
            .field("dependencies", .array(of: .string), .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Package.schema).delete()
    }


}