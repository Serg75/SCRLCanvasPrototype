//
//  OverlayFetcher.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import Foundation

class OverlayFetcher {
    static let shared = OverlayFetcher()
    private let overlayURL = URL(string: "https://appostropheanalytics.herokuapp.com/scrl/test/overlays")!

    // In-memory cache to prevent redundant network requests
    private var cachedOverlays: [OverlayItem]?

    func fetchOverlays() async throws -> [OverlayItem] {
        if let cached = cachedOverlays {
            return cached
        }

        let (data, _) = try await URLSession.shared.data(from: overlayURL)
        let categories = try JSONDecoder().decode([OverlayCategory].self, from: data)
        let allOverlays = categories.flatMap { $0.items }

        cachedOverlays = allOverlays // Cache the results
        return allOverlays
    }
}
