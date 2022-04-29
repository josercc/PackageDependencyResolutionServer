//
//  Token.swift
//  
//
//  Created by 张行 on 2022/4/24.
//

import Foundation
import Vapor

public struct Token {
    public let github: String

    public init() throws {
        self.github = try Token.get("GITHUB_TOKEN")
    }
    
    public static func check() throws {
        try get("GITHUB_TOKEN")
    }
    
    @discardableResult
    static func get(_ key:String) throws -> String {
        guard let value = ProcessInfo.processInfo.environment[key] else {
            throw Abort(.internalServerError, reason: "\(key) not found")
        }
        return value
    }
}
