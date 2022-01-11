//
//  Account.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/01/11.
//

import Foundation
import RealmSwift

class Account: Object {
    @objc dynamic var name = ""
    @objc dynamic var password = ""
    @objc dynamic var userid = ""
}
