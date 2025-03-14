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

    private var verticalSnapLinePositions: [CGFloat] = []
    private var horizontalSnapLinePositions: [CGFloat] = []

    override init(frame: CGRect) {
        canvasWidth = frame.width
        canvasHeight = frame.height

        super.init(frame: frame)

        backgroundColor = .white
        setupGuidelines()
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

    // MARK: - Drawing Guidelines & Snap Lines

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setLineWidth(guidelineThickness)

        // draw vertical guidelines (black)
        context.setStrokeColor(guidelineColor.cgColor)
        for x in verticalGuidelinePositions {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: canvasHeight))
        }

        // draw horizontal guidelines (black)
        for y in horizontalGuidelinePositions {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: canvasWidth, y: y))
        }
        context.strokePath()

        // draw snap lines (yellow)
        context.setStrokeColor(snapLineColor.cgColor)
        context.setLineWidth(snapLineThickness)

        for x in verticalSnapLinePositions {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: canvasHeight))
        }

        for y in horizontalSnapLinePositions {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: canvasWidth, y: y))
        }
        context.strokePath()
    }

    // MARK: - Snapping Line Management

    func showSnapLines(vertical: [CGFloat], horizontal: [CGFloat]) {
        verticalSnapLinePositions = vertical
        horizontalSnapLinePositions = horizontal
        setNeedsDisplay()
    }

    func hideSnapLines() {
        verticalSnapLinePositions.removeAll()
        horizontalSnapLinePositions.removeAll()
        setNeedsDisplay()
    }
}
