//
//  SnapDetectorTests.swift
//  SCRLCanvasPrototype_Tests
//
//  Created by Sergey Slobodenyuk on 2025-03-15.
//

import UIKit

import Testing
@testable import SCRLCanvasPrototype

@MainActor
struct SnapDetectorTests {

    @Test func testSnapDetection_AlignsToGuidelines() {
        let detector = SnapDetector()
        detector.updateGuidelines(vertical: [100, 200, 300], horizontal: [150, 250, 350])

        let overlayMock = OverlayItemView(image: UIImage(), delegate: nil)
        let snapResult = detector.detectSnaps(for: overlayMock, proposedPosition: CGPoint(x: 205, y: 255))

        #expect(snapResult.snappedX == 200, "Overlay should snap to nearest vertical guideline")
        #expect(snapResult.snappedY == 250, "Overlay should snap to nearest horizontal guideline")
    }

    @Test func testSnapDetection_DoesNotSnapIfOutsideThreshold() {
        let detector = SnapDetector()
        detector.updateGuidelines(vertical: [100, 200, 300], horizontal: [150, 250, 350])

        let overlayMock = OverlayItemView(image: UIImage(), delegate: nil)
        let snapResult = detector.detectSnaps(for: overlayMock, proposedPosition: CGPoint(x: 170, y: 100))

        #expect(snapResult.snappedX == nil, "Overlay should not snap if outside threshold")
        #expect(snapResult.snappedY == nil, "Overlay should not snap if outside threshold")
    }
}
