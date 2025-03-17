//
//  SnapDetector.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-14.
//

import UIKit

private enum Axis {
    case horizontal, vertical
}

private enum EdgeType {
    case left, centerX, right
    case top, centerY, bottom
}

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
        let snapToCenterOnly = !overlay.canSnapsToEdges

        let edges = rotatedEdges(for: overlay, at: proposedPosition)

        // canvas snapping

        result.snappedX = snap(for: edges,
                               axis: .horizontal,
                               centerOnly: snapToCenterOnly,
                               candidates: verticalGuidelines,
                               proposed: proposedPosition.x,
                               result: &result)

        result.snappedY = snap(for: edges,
                               axis: .vertical,
                               centerOnly: snapToCenterOnly,
                               candidates: horizontalGuidelines,
                               proposed: proposedPosition.y,
                               result: &result)

        // snap to other overlays

        for otherOverlay in overlays where otherOverlay !== overlay {
            let otherEdges = rotatedEdges(for: otherOverlay, at: otherOverlay.center)
            let xCandidates = [otherEdges.left, otherEdges.centerX, otherEdges.right]
            let yCandidates = [otherEdges.top, otherEdges.centerY, otherEdges.bottom]

            result.snappedX = snap(for: edges,
                                   axis: .horizontal,
                                   centerOnly: snapToCenterOnly,
                                   candidates: xCandidates,
                                   proposed: proposedPosition.x,
                                   result: &result,
                                   override: result.snappedX)

            result.snappedY = snap(for: edges,
                                   axis: .vertical,
                                   centerOnly: snapToCenterOnly,
                                   candidates: yCandidates,
                                   proposed: proposedPosition.y,
                                   result: &result,
                                   override: result.snappedY)
        }

        return result
    }

    // MARK: - Helper Methods

    private func findClosestSnap(to position: CGFloat, in candidates: [CGFloat]) -> CGFloat? {
        guard let closest = candidates.min(by: { abs($0 - position) < abs($1 - position) }) else { return nil }

        return abs(closest - position) <= snapThreshold ? closest : nil
    }

    private func rotatedEdges(for overlay: OverlayItemView, at position: CGPoint) -> (left: CGFloat, centerX: CGFloat, right: CGFloat, top: CGFloat, centerY: CGFloat, bottom: CGFloat) {
        let rotation = overlay.currentRotation
        let size = overlay.bounds.size
        let halfSize = CGSize(width: size.width / 2, height: size.height / 2)

        let corners = [
            CGPoint(x: -halfSize.width, y: -halfSize.height),
            CGPoint(x:  halfSize.width, y: -halfSize.height),
            CGPoint(x:  halfSize.width, y:  halfSize.height),
            CGPoint(x: -halfSize.width, y:  halfSize.height)
        ]

        let rotatedCorners = corners.map { point -> CGPoint in
            let rotatedX = cos(rotation) * point.x - sin(rotation) * point.y
            let rotatedY = sin(rotation) * point.x + cos(rotation) * point.y
            return CGPoint(x: position.x + rotatedX, y: position.y + rotatedY)
        }

        let xs = rotatedCorners.map { $0.x }
        let ys = rotatedCorners.map { $0.y }

        return (
            left: xs.min()!,
            centerX: position.x,
            right: xs.max()!,
            top: ys.min()!,
            centerY: position.y,
            bottom: ys.max()!
        )
    }

    private func snap(for edges: (left: CGFloat, centerX: CGFloat, right: CGFloat, top: CGFloat, centerY: CGFloat, bottom: CGFloat),
                      axis: Axis,
                      centerOnly: Bool,
                      candidates: [CGFloat],
                      proposed: CGFloat,
                      result: inout SnapResult,
                      override: CGFloat? = nil) -> CGFloat? {

        guard override == nil else { return override } // already snapped

        let edgeSnaps: [(value: CGFloat, type: EdgeType)]
        let isVertical = (axis == .horizontal)

        if centerOnly {
            edgeSnaps = [(
                axis == .horizontal ? edges.centerX : edges.centerY,
                axis == .horizontal ? .centerX : .centerY
            )]
        } else {
            if axis == .horizontal {
                edgeSnaps = [
                    (edges.left, .left),
                    (edges.centerX, .centerX),
                    (edges.right, .right)
                ]
            } else {
                edgeSnaps = [
                    (edges.top, .top),
                    (edges.centerY, .centerY),
                    (edges.bottom, .bottom)
                ]
            }
        }

        for (value, type) in edgeSnaps {
            if let snap = findClosestSnap(to: value, in: candidates) {
                result.snapLines.append(SnapLine(position: snap, isVertical: isVertical))

                switch type {
                case .left, .top, .right, .bottom:
                    return proposed + (snap - value)
                case .centerX, .centerY:
                    return snap
                }
            }
        }
        return nil
    }
}

// MARK - Equatable

extension SnapDetector.SnapResult: Equatable {
    static func == (lhs: SnapDetector.SnapResult, rhs: SnapDetector.SnapResult) -> Bool {
        return lhs.snappedX == rhs.snappedX &&
               lhs.snappedY == rhs.snappedY &&
               lhs.snapLines == rhs.snapLines
    }
}

extension SnapDetector.SnapLine: Equatable {
    static func == (lhs: SnapDetector.SnapLine, rhs: SnapDetector.SnapLine) -> Bool {
        return lhs.position == rhs.position && lhs.isVertical == rhs.isVertical
    }
}
