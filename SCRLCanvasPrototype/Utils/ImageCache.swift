//
//  ImageCache.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    func get(_ url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }

    func set(_ url: String, image: UIImage) {
        cache.setObject(image, forKey: url as NSString)
    }
}
