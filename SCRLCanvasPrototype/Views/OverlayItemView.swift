//
//  OverlayItemView.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-12.
//

import UIKit

protocol OverlayItemViewDelegate: AnyObject {
    func setActiveItem(_ item: OverlayItemView)
    func updateSnapLines(for result: SnapDetector.SnapResult)
    func setScrollEnabled(_ enabled: Bool)
    func detectSnaps(for overlay: OverlayItemView, proposedPosition: CGPoint) -> SnapDetector.SnapResult
}

class OverlayItemView: UIImageView {

    // MARK: - Properties

    weak var delegate: OverlayItemViewDelegate?

    private let highlightView = UIView()

    private var initialCenter: CGPoint = .zero
    private var isActive: Bool = false {
        didSet {
            updateHighlight()
        }
    }

    // MARK: - Initializers

    init(image: UIImage, delegate: OverlayItemViewDelegate?) {
        self.delegate = delegate

        super.init(image: image)

        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFit
        self.translatesAutoresizingMaskIntoConstraints = false

        setupHighlightView()
        addTapGesture()
        addPanGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented!")
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
        delegate?.setActiveItem(self)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isActive, let superview = self.superview else { return }

        let translation = gesture.translation(in: superview)
        let proposedPosition = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)

        let snapResult = delegate?.detectSnaps(for: self, proposedPosition: proposedPosition) ?? SnapDetector.SnapResult()

        var newCenter = proposedPosition
        if let snappedX = snapResult.snappedX { newCenter.x = snappedX }
        if let snappedY = snapResult.snappedY { newCenter.y = snappedY }

        switch gesture.state {
        case .began:
            initialCenter = self.center
            delegate?.setScrollEnabled(false) // disable scrolling while dragging

        case .changed:
            self.center = newCenter
            delegate?.updateSnapLines(for: snapResult)

        case .ended, .cancelled:
            delegate?.setScrollEnabled(true) // re-enable scrolling

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
}

// MARK: - UIGestureRecognizerDelegate

extension OverlayItemView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return isActive // allow dragging only when active
    }
}
