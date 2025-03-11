//
//  OverlayItem.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import Foundation

struct OverlayCategory: Decodable {
    let title: String
    let id: Int
    let items: [OverlayItem]
}

struct OverlayItem: Decodable {
    let id: Int
    let name: String
    let imageURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case name = "overlay_name"
        case imageURL = "source_url"
    }
}
