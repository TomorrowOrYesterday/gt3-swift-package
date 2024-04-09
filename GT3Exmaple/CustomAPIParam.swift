//
//  CustomAPIParam.swift
//  GT3Example
//
//  Created by NikoXu on 2020/4/29.
//  Copyright © 2020 Xniko. All rights reserved.
//

import Foundation

struct API1Response: Codable {
    var gt: String
    var challenge: String
    var success: Int
    var new_captcha: Bool?
}

struct API2Response: Codable {
    var status: String
}
