//
//  CanvasViewTests.swift
//  SCRLCanvasPrototype_Tests
//
//  Created by Sergey Slobodenyuk on 2025-03-15.
//

import UIKit

import Testing
@testable import SCRLCanvasPrototype

@MainActor
struct CanvasViewTests {

    @Test
    func testCanvasView_HasGuidelines() {
        let canvasView = CanvasView(frame: CGRect(x: 0, y: 0, width: 1000, height: 500))

        #expect(!canvasView.verticalGuidelines.isEmpty, "CanvasView should have vertical guidelines")
        #expect(!canvasView.horizontalGuidelines.isEmpty, "CanvasView should have horizontal guidelines")
    }

    @Test
    func testCanvasView_HitTest_ReturnsSubview() {
        let canvasView = CanvasView(frame: CGRect(x: 0, y: 0, width: 1000, height: 500))
        let subview = UIView(frame: CGRect(x: 100, y: 100, width: 50, height: 50))
        canvasView.addSubview(subview)

        let hitView = canvasView.hitTest(CGPoint(x: 110, y: 110), with: nil)
        #expect(hitView == subview, "HitTest should return the correct subview")
    }

    @Test
    func testCanvasView_SnapLineLayer_InitialState() {
        let canvasView = CanvasView(frame: CGRect(x: 0, y: 0, width: 1000, height: 500))

        let snapLineLayer = canvasView.layer.sublayers?.first(where: { $0 is CAShapeLayer && $0.zPosition == 1000 }) as? CAShapeLayer

        #expect(snapLineLayer != nil, "Snap line layer should be added to the canvas")
        #expect(snapLineLayer?.path == nil, "Snap line path should be empty on initialization")
    }

    @Test
    func testCanvasView_HideSnapLines_ClearsPath() {
        let canvasView = CanvasView(frame: CGRect(x: 0, y: 0, width: 1000, height: 500))

        // Trigger snap lines drawing
        canvasView.showSnapLines(vertical: [100], horizontal: [200])
        canvasView.hideSnapLines()

        let snapLineLayer = canvasView.layer.sublayers?.first(where: { $0 is CAShapeLayer && $0.zPosition == 1000 }) as? CAShapeLayer

        #expect(snapLineLayer?.path == nil, "Snap line layer path should be cleared after hideSnapLines()")
    }

    @Test
    func testCanvasView_ShowSnapLines_DrawsMultipleLines() {
        let canvasView = CanvasView(frame: CGRect(x: 0, y: 0, width: 1000, height: 500))

        // Show multiple snap lines
        canvasView.showSnapLines(vertical: [100, 300], horizontal: [50, 400])

        let snapLineLayer = canvasView.layer.sublayers?.first(where: { $0 is CAShapeLayer && $0.zPosition == 1000 }) as? CAShapeLayer
        let path = snapLineLayer?.path

        #expect(path != nil, "Snap line path should not be nil after showSnapLines()")

        // Check if path contains expected lines (rough check by bounding box)
        let boundingBox = path!.boundingBox
        #expect(boundingBox.contains(CGPoint(x: 100, y: 0)), "Snap line should include vertical line at x = 100")
        #expect(boundingBox.contains(CGPoint(x: 300, y: 0)), "Snap line should include vertical line at x = 300")
        #expect(boundingBox.contains(CGPoint(x: 0, y: 50)), "Snap line should include horizontal line at y = 50")
        #expect(boundingBox.contains(CGPoint(x: 0, y: 400)), "Snap line should include horizontal line at y = 400")
    }
}
