//
//  SnapDetector.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-14.
//

import UIKit

class SnapDetector {

    struct SnapResult {
        var snappedX: CGFloat?
        var snappedY: CGFloat?
        var snapLines: [SnapLine] = []
    }

    struct SnapLine {
        let position: CGFloat
        let isVertical: Bool
    }

    private let snapThreshold: CGFloat = 20
    private var overlays: [OverlayItemView] = []
    private var verticalGuidelines: [CGFloat] = []
    private var horizontalGuidelines: [CGFloat] = []

    // MARK: - Setup Guidelines and Overlays

    func updateGuidelines(vertical: [CGFloat], horizontal: [CGFloat]) {
        self.verticalGuidelines = vertical
        self.horizontalGuidelines = horizontal
    }

    func updateOverlays(_ overlays: [OverlayItemView]) {
        self.overlays = overlays
    }

    // MARK: - Detect Snaps

    func detectSnaps(for overlay: OverlayItemView, proposedPosition: CGPoint) -> SnapResult {
        var result = SnapResult()

        // check snapping for X-axis (left, center, right edges)
        let leftEdge = proposedPosition.x - overlay.bounds.width / 2
        let centerX = proposedPosition.x
        let rightEdge = proposedPosition.x + overlay.bounds.width / 2

        if let snapX = findClosestSnap(to: leftEdge, in: verticalGuidelines) {
            result.snappedX = snapX + overlay.bounds.width / 2
            result.snapLines.append(SnapLine(position: snapX, isVertical: true))
        } else if let snapX = findClosestSnap(to: centerX, in: verticalGuidelines) {
            result.snappedX = snapX
            result.snapLines.append(SnapLine(position: snapX, isVertical: true))
        } else if let snapX = findClosestSnap(to: rightEdge, in: verticalGuidelines) {
            result.snappedX = snapX - overlay.bounds.width / 2
            result.snapLines.append(SnapLine(position: snapX, isVertical: true))
        }

        // check snapping for Y-axis (top, center, bottom edges)
        let topEdge = proposedPosition.y - overlay.bounds.height / 2
        let bottomEdge = proposedPosition.y + overlay.bounds.height / 2

        if let snapY = findClosestSnap(to: topEdge, in: horizontalGuidelines) {
            result.snappedY = snapY + overlay.bounds.height / 2
            result.snapLines.append(SnapLine(position: snapY, isVertical: false))
        } else if let snapY = findClosestSnap(to: bottomEdge, in: horizontalGuidelines) {
            result.snappedY = snapY - overlay.bounds.height / 2
            result.snapLines.append(SnapLine(position: snapY, isVertical: false))
        }

        // check snapping between overlays
        for otherOverlay in overlays where otherOverlay !== overlay {
            let otherLeft = otherOverlay.frame.origin.x
            let otherCenterX = otherOverlay.center.x
            let otherRight = otherOverlay.frame.origin.x + otherOverlay.bounds.width

            if let snapX = findClosestSnap(to: leftEdge, in: [otherLeft, otherCenterX, otherRight]) {
                result.snappedX = snapX + overlay.bounds.width / 2
                result.snapLines.append(SnapLine(position: snapX, isVertical: true))
            } else if let snapX = findClosestSnap(to: centerX, in: [otherLeft, otherCenterX, otherRight]) {
                result.snappedX = snapX
                result.snapLines.append(SnapLine(position: snapX, isVertical: true))
            } else if let snapX = findClosestSnap(to: rightEdge, in: [otherLeft, otherCenterX, otherRight]) {
                result.snappedX = snapX - overlay.bounds.width / 2
                result.snapLines.append(SnapLine(position: snapX, isVertical: true))
            }

            let otherTop = otherOverlay.frame.origin.y
            let otherCenterY = otherOverlay.center.y
            let otherBottom = otherOverlay.frame.origin.y + otherOverlay.bounds.height

            if let snapY = findClosestSnap(to: topEdge, in: [otherTop, otherCenterY, otherBottom]) {
                result.snappedY = snapY + overlay.bounds.height / 2
                result.snapLines.append(SnapLine(position: snapY, isVertical: false))
            } else if let snapY = findClosestSnap(to: bottomEdge, in: [otherTop, otherCenterY, otherBottom]) {
                result.snappedY = snapY - overlay.bounds.height / 2
                result.snapLines.append(SnapLine(position: snapY, isVertical: false))
            }
        }

        return result
    }

    // MARK: - Helper Methods

    private func findClosestSnap(to position: CGFloat, in candidates: [CGFloat]) -> CGFloat? {
        guard let closest = candidates.min(by: { abs($0 - position) < abs($1 - position) }) else { return nil }

        return abs(closest - position) <= snapThreshold ? closest : nil
    }
}
