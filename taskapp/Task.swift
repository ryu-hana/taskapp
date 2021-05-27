//
//  Task.swift
//  taskapp
//
//  Created by SugiuraArisa on 2021/05/20.
//

import RealmSwift

class Task: Object {
    // 管理用 ID。プライマリーキー
    @objc dynamic var id = 0
    
    // カテゴリ
    @objc dynamic var category: Category? = nil

    // タイトル
    @objc dynamic var title = ""

    // 内容
    @objc dynamic var contents = ""

    // 日時
    @objc dynamic var date = Date()

    // id をプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}

class Category: Object {
    // 管理用 ID。プライマリーキー
    @objc dynamic var id = 0
    
    // カテゴリ名
    @objc dynamic var name = ""
    
    // id をプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // 逆方向のリレーション
    let relationTask = LinkingObjects(fromType: Task.self, property: "category")
}
