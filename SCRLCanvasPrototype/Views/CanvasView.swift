//
//  CanvasView.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import UIKit

class CanvasView: UIView {

    // MARK: - Properties
    private let guidelineColor = UIColor.black.withAlphaComponent(0.8)
    private let snapLineColor = UIColor.systemYellow.withAlphaComponent(0.8)
    private let guidelineThickness: CGFloat = 2.0
    private let snapLineThickness: CGFloat = 2.0
    private let canvasWidth: CGFloat
    private let canvasHeight: CGFloat

    private(set) var verticalGuidelinePositions: [CGFloat] = []
    private(set) var horizontalGuidelinePositions: [CGFloat] = []

    // shape layers for drawing lines
    private let guidelineLayer = CAShapeLayer()
    private let snapLineLayer = CAShapeLayer()

    override init(frame: CGRect) {
        canvasWidth = frame.width
        canvasHeight = frame.height

        super.init(frame: frame)

        backgroundColor = .white
        setupGuidelines()
        setupGuidelineLayer()
        setupSnapLineLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented!")
    }

    // MARK: - Setup Guidelines

    private func setupGuidelines() {
        verticalGuidelinePositions = [
            0,                        // left canvas border
            canvasWidth * 0.25,
            canvasWidth * 0.5,
            canvasWidth * 0.75,
            canvasWidth               // right canvas border
        ]

        horizontalGuidelinePositions = [
            0,                        // top canvas border
            canvasHeight              // bottom canvas border
        ]
    }

    // MARK: - Setup Guideline Layer

    private func setupGuidelineLayer() {
        guidelineLayer.strokeColor = guidelineColor.cgColor
        guidelineLayer.fillColor = nil
        guidelineLayer.lineWidth = guidelineThickness
        guidelineLayer.zPosition = 999 // ensure it's above background
        layer.addSublayer(guidelineLayer)
        drawGuidelines() // initial rendering
    }

    private func drawGuidelines() {
        let path = UIBezierPath()

        for x in verticalGuidelinePositions {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: canvasHeight))
        }

        for y in horizontalGuidelinePositions {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: canvasWidth, y: y))
        }

        guidelineLayer.path = path.cgPath
    }

    // MARK: - Setup Snap Line Layer

    private func setupSnapLineLayer() {
        snapLineLayer.strokeColor = snapLineColor.cgColor
        snapLineLayer.fillColor = nil
        snapLineLayer.lineWidth = snapLineThickness
        snapLineLayer.zPosition = 1000 // ensure it's above overlays
        layer.addSublayer(snapLineLayer)
    }

    // MARK: - Drawing Snap Lines

    func showSnapLines(vertical: [CGFloat], horizontal: [CGFloat]) {
        let path = UIBezierPath()

        for x in vertical {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: canvasHeight))
        }

        for y in horizontal {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: canvasWidth, y: y))
        }

        DispatchQueue.main.async {
            self.snapLineLayer.path = path.cgPath
        }
    }

    func hideSnapLines() {
        DispatchQueue.main.async {
            self.snapLineLayer.path = nil
        }
    }
}
