//
//  CanvasView.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import UIKit

class CanvasView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)

        let sectionWidth = rect.width / 4

        for i in 1..<4 {
            let x = CGFloat(i) * sectionWidth
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: rect.height))
        }

        context.strokePath()
    }
}
