//
//  ImageCacheTests.swift
//  SCRLCanvasPrototype_Tests
//
//  Created by Sergey Slobodenyuk on 2025-03-15.
//

import UIKit

import Testing
@testable import SCRLCanvasPrototype

struct ImageCacheTests {

    @Test func testImageCache_CanStoreAndRetrieveImage() {
        let cache = ImageCache.shared
        let testImage = UIImage(systemName: "star")!

        cache.set("test_url", image: testImage)
        let retrievedImage = cache.get("test_url")

        #expect(retrievedImage != nil, "ImageCache should retrieve stored image")
    }
}
