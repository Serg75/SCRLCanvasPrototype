//
//  OverlaySelectionViewControllerTests.swift
//  SCRLCanvasPrototype_Tests
//
//  Created by Sergey Slobodenyuk on 2025-03-15.
//

import UIKit

import Testing
@testable import SCRLCanvasPrototype

@MainActor
struct OverlaySelectionViewControllerTests {

    @Test func testOverlaySelection_DelegateCalledOnSelection() async throws {
        let mockFetcher = MockOverlayFetcher()
        let controller = OverlaySelectionViewController(overlayFetcher: mockFetcher)
        let mockDelegate = MockOverlaySelectionDelegate()
        controller.delegate = mockDelegate

        // Trigger the async overlay loading logic
        await controller.fetchOverlays()

        // Simulate item selection
        controller.collectionView(controller.collectionView, didSelectItemAt: IndexPath(row: 0, section: 0))

        #expect(mockDelegate.selectedOverlay != nil, "OverlaySelectionDelegate should be called when an overlay is selected")
        #expect(mockDelegate.selectedOverlay?.name == "MockOverlay", "Selected overlay should match the mock overlay")
    }
}

class MockOverlaySelectionDelegate: OverlaySelectionDelegate {
    var selectedOverlay: OverlayItem?

    func didSelectOverlay(_ overlay: OverlayItem) {
        selectedOverlay = overlay
    }
}

class MockOverlayFetcher: OverlayFetcher {
    override func fetchOverlays() async throws -> [OverlayItem] {
        return [
            OverlayItem(id: 1, name: "MockOverlay", imageURL: "https://example.com/mock.png")
        ]
    }
}
