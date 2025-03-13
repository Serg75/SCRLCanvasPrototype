//
//  OverlayItemView.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-12.
//

import UIKit

class OverlayItemView: UIImageView {

    // MARK: - Properties

    private let highlightView = UIView()

    private var initialCenter: CGPoint = .zero
    private var isActive: Bool = false {
        didSet {
            updateHighlight()
        }
    }

    // MARK: - Initializers

    init(image: UIImage) {
        super.init(image: image)
        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFit
        self.translatesAutoresizingMaskIntoConstraints = false

        setupHighlightView()
        addTapGesture()
        addPanGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHighlightView()
        addTapGesture()
        addPanGesture()
    }

    // MARK: - Setup Methods

    private func setupHighlightView() {
        highlightView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        highlightView.isHidden = true
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(highlightView)

        NSLayoutConstraint.activate([
            highlightView.topAnchor.constraint(equalTo: topAnchor),
            highlightView.leadingAnchor.constraint(equalTo: leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: trailingAnchor),
            highlightView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }

    private func addPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap() {
        guard let canvasVC = findCanvasViewController() else { return }
        canvasVC.setActiveItem(self) // notify the canvas that this item is now active
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isActive else { return } // only allow movement if the item is active
        guard let superview = self.superview else { return }
        guard let canvasVC = findCanvasViewController() else { return }

        let translation = gesture.translation(in: superview)

        switch gesture.state {
        case .began:
            initialCenter = self.center
            canvasVC.setScrollEnabled(false) // disable scrolling while dragging
        case .changed:
            self.center = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
        case .ended, .cancelled:
            canvasVC.setScrollEnabled(true) // re-enable scrolling
        default:
            break
        }
    }

    // MARK: - State Management

    func setActive(_ active: Bool) {
        isActive = active
    }

    private func updateHighlight() {
        highlightView.isHidden = !isActive
    }

    // MARK: - Helper Methods

    private func findCanvasViewController() -> CanvasViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? CanvasViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}

// MARK: - UIGestureRecognizerDelegate

extension OverlayItemView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return isActive // allow dragging only when active
    }
}
