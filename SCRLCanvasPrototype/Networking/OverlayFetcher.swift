//
//  OverlayFetcher.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import Foundation

class OverlayFetcher {
    static let shared = OverlayFetcher()
    static let productionURL: URL = URL(string: "https://appostropheanalytics.herokuapp.com/scrl/test/overlays")!

    private let overlayURL: URL
    private var cachedOverlays: [OverlayItem]?
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared, overlayURL: URL = productionURL) {
        self.urlSession = urlSession
        self.overlayURL = overlayURL
    }

    func fetchOverlays() async throws -> [OverlayItem] {
        if let cached = cachedOverlays {
            return cached
        }

        let (data, _) = try await urlSession.data(from: overlayURL)
        let categories = try JSONDecoder().decode([OverlayCategory].self, from: data)
        let allOverlays = categories.flatMap { $0.items }

        cachedOverlays = allOverlays
        return allOverlays
    }
}
