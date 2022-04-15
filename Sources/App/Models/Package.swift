//
//  Package.swift
//  
//
//  Created by 张行 on 2022/4/15.
//

import Foundation
import FluentKit

final class Package: Model {
    static var schema: String {"package"}
    
    @ID(key: .id)
    var id: UUID?

    /// Package 内容
    @Field(key: "content")
    var content: String

    /// 依赖的链接数组
    @Field(key: "dependencies")
    var dependencies: [String]

    /// 初始化
    init() { }

    /// 初始化
    init(id: UUID? = nil, content: String, dependencies: [String]) {
        self.id = id
        self.content = content
        self.dependencies = dependencies
    }

}
