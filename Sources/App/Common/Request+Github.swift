
import Vapor
import OctoKit

extension Request {
    /// 获取Github 仓库Tag
    ///
    /// - Parameters:
    ///   - repoPath: 仓库 vapor/vapor
    /// - Returns: 仓库Tag
    func getGithubRepoTag(from repoPath:String) async throws -> [String] {
        let token = try Token()
        let repoResult = repoPath.components(separatedBy: "/")
        guard repoResult.count == 2 else {
            throw Abort(.custom(code: 10000, reasonPhrase: "\(repoPath)不是一个仓库路径"))
        }
        let octoKit = Octokit(TokenConfiguration(token.github))
        return try await withCheckedThrowingContinuation({ continuation in
            octoKit.listReleases(owner: repoResult[0], repository: repoResult[1], completion: { response in
                switch response {
                case .success(let releases):
                    let tags = releases.map({$0.tagName})
                    continuation.resume(returning: tags)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        })
    }
}
