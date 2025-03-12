//
//  OverlayItemView.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-12.
//

import UIKit

class OverlayItemView: UIImageView {

    private var initialCenter: CGPoint = .zero

    init(image: UIImage) {
        super.init(image: image)
        
        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFit
        self.translatesAutoresizingMaskIntoConstraints = false

        addPanGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addPanGesture()
    }

    private func addPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGesture)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }

        let translation = gesture.translation(in: superview)

        switch gesture.state {
        case .began:
            initialCenter = self.center
        case .changed:
            self.center = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
        case .ended, .cancelled:
            // TODO: implement snapping
            break
        default:
            break
        }
    }
}
