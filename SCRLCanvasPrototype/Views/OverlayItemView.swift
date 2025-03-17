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

class OverlayItemView: UIView {

    // MARK: - UI Components

    private let contentContainer = UIView()
    private let overlayImageView = UIImageView()
    private let highlightView = UIView()
    private let rotationHandle = UIView()
    private let rotationIcon = UIImageView()

    // MARK: - State

    weak var delegate: OverlayItemViewDelegate?
    private var panGesture: UIPanGestureRecognizer!
    private var rotationGesture: UIPanGestureRecognizer!
    private var hapticGenerator: UIImpactFeedbackGenerator?

    // MARK: - State

    private var lastSnappedAngle: CGFloat?
    private var initialCenter: CGPoint = .zero
    private var isActive: Bool = false {
        didSet { updateHighlight() }
    }

    private(set) var currentRotation: CGFloat = 0 // in radians
    private var isRotating = false
    private var initialTouchAngle: CGFloat = 0
    private var initialRotation: CGFloat = 0

    // Snap logic
    var canSnapsToEdges: Bool {
        let normalizedRotation = abs(currentRotation.truncatingRemainder(dividingBy: 2 * .pi))
        let tolerance: CGFloat = .pi / 90
        let snapAngles: [CGFloat] = [0, .pi / 2, .pi, 3 * .pi / 2]

        for snap in snapAngles {
            if abs(normalizedRotation - snap) < tolerance {
                return true // full snapping allowed
            }
        }
        return false // center-only snap mode
    }

    // MARK: - Init

    init(image: UIImage, delegate: OverlayItemViewDelegate?) {
        self.delegate = delegate
        hapticGenerator = UIImpactFeedbackGenerator(style: .light)
        hapticGenerator?.prepare()

        super.init(frame: CGRect(origin: .zero, size: image.size))

        self.translatesAutoresizingMaskIntoConstraints = true
        self.isUserInteractionEnabled = true

        setupContainer(image: image)
        setupHighlightView()
        setupRotationHandle()
        addGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented!")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // convert point to rotationHandle's coordinate space
        if !rotationHandle.isHidden {
            let convertedPoint = rotationHandle.convert(point, from: self)
            if rotationHandle.bounds.contains(convertedPoint) {
                return rotationHandle.hitTest(convertedPoint, with: event)
            }
        }

        // fallback to default hitTest
        return super.hitTest(point, with: event)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // convert touch point to contentContainer space (rotated space)
        let rotatedPoint = convert(point, to: contentContainer)

        // check if the touch is inside the rotated container
        return contentContainer.bounds.contains(rotatedPoint)
    }

    // MARK: - Setup UI

    private func setupContainer(image: UIImage) {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentContainer)

        overlayImageView.image = image
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayImageView.contentMode = .scaleAspectFit
        overlayImageView.clipsToBounds = true
        contentContainer.addSubview(overlayImageView)

        NSLayoutConstraint.activate([
            contentContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            overlayImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            overlayImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            overlayImageView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            overlayImageView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            overlayImageView.widthAnchor.constraint(equalToConstant: image.size.width),
            overlayImageView.heightAnchor.constraint(equalToConstant: image.size.height)
        ])
    }

    private func setupHighlightView() {
        highlightView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        highlightView.isHidden = true
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(highlightView)

        NSLayoutConstraint.activate([
            highlightView.topAnchor.constraint(equalTo: overlayImageView.topAnchor),
            highlightView.leadingAnchor.constraint(equalTo: overlayImageView.leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: overlayImageView.trailingAnchor),
            highlightView.bottomAnchor.constraint(equalTo: overlayImageView.bottomAnchor)
        ])
    }

    private func setupRotationHandle() {
        // circle background
        rotationHandle.backgroundColor = .white
        rotationHandle.layer.cornerRadius = 40 // for a 80x80 circle
        rotationHandle.layer.shadowColor = UIColor.black.cgColor
        rotationHandle.layer.shadowOpacity = 0.4
        rotationHandle.layer.shadowOffset = CGSize(width: 0, height: 2)
        rotationHandle.layer.shadowRadius = 10

        rotationHandle.translatesAutoresizingMaskIntoConstraints = false
        rotationHandle.isUserInteractionEnabled = true
        addSubview(rotationHandle)

        rotationIcon.image = UIImage(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
        rotationIcon.tintColor = .systemBlue
        rotationIcon.translatesAutoresizingMaskIntoConstraints = false
        rotationHandle.addSubview(rotationIcon)

        NSLayoutConstraint.activate([
            rotationHandle.widthAnchor.constraint(equalToConstant: 80),
            rotationHandle.heightAnchor.constraint(equalToConstant: 80),

            rotationIcon.centerXAnchor.constraint(equalTo: rotationHandle.centerXAnchor),
            rotationIcon.centerYAnchor.constraint(equalTo: rotationHandle.centerYAnchor),
            rotationIcon.widthAnchor.constraint(equalToConstant: 60),
            rotationIcon.heightAnchor.constraint(equalToConstant: 60)
        ])

        rotationHandle.isHidden = true
    }

    // MARK: - Gesture Setup

    private func addGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)

        rotationGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationHandle.addGestureRecognizer(rotationGesture)
    }

    // MARK: - Gesture Actions

    @objc private func handleTap() {
        delegate?.setActiveItem(self)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isActive, !isRotating, let superview = self.superview else { return }

        let translation = gesture.translation(in: superview)
        let proposedPosition = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
        let snapResult = delegate?.detectSnaps(for: self, proposedPosition: proposedPosition) ?? SnapDetector.SnapResult()

        var newCenter = proposedPosition
        if let snappedX = snapResult.snappedX { newCenter.x = snappedX }
        if let snappedY = snapResult.snappedY { newCenter.y = snappedY }

        switch gesture.state {
        case .began:
            initialCenter = self.center
            delegate?.setScrollEnabled(false)
        case .changed:
            self.center = newCenter
            delegate?.updateSnapLines(for: snapResult)
        case .ended, .cancelled:
            delegate?.setScrollEnabled(true)
        default:
            break
        }
    }

    @objc private func handleRotation(_ gesture: UIPanGestureRecognizer) {
        guard let canvas = superview else { return }

        let location = gesture.location(in: canvas)
        let centerInCanvas = self.center

        let dx = location.x - centerInCanvas.x
        let dy = location.y - centerInCanvas.y
        let angleToTouch = atan2(dy, dx)

        switch gesture.state {
        case .began:
            isRotating = true
            delegate?.setScrollEnabled(false)
            initialTouchAngle = angleToTouch
            initialRotation = currentRotation

        case .changed:
            let delta = angleToTouch - initialTouchAngle
            var newAngle = initialRotation + delta
            newAngle = snapRotation(newAngle)
            currentRotation = newAngle
            contentContainer.transform = CGAffineTransform(rotationAngle: currentRotation)
            setNeedsLayout()

        case .ended, .cancelled:
            isRotating = false
            delegate?.setScrollEnabled(true)

        default:
            break
        }
    }

    private func snapRotation(_ angle: CGFloat) -> CGFloat {
        let snapThreshold: CGFloat = .pi / 36 // 5 degrees
        let snapPoints: [CGFloat] = [0, .pi / 2, .pi, 3 * .pi / 2] // 0°, 90°, 180°, 270° (in radians)

        let fullTurns = floor(angle / (2 * .pi))
        let baseAngle = angle - fullTurns * (2 * .pi)

        for snapPoint in snapPoints {
            if abs(baseAngle - snapPoint) < snapThreshold {
                let snappedAngle = fullTurns * (2 * .pi) + snapPoint

                if lastSnappedAngle == nil {
                    hapticGenerator?.impactOccurred()
                    lastSnappedAngle = snappedAngle
                }
                return snappedAngle
            }
        }
        lastSnappedAngle = nil
        return angle
    }

    // MARK: - Highlight and Handle Visibility

    func setActive(_ active: Bool) {
        isActive = active
    }

    private func updateHighlight() {
        highlightView.isHidden = !isActive
        rotationHandle.isHidden = !isActive
    }

    // MARK: - Layout Handle Below Rotated Overlay

    override func layoutSubviews() {
        super.layoutSubviews()
        positionRotationHandle()
    }

    func prepareForDisplay() {
        layoutIfNeeded()
        positionRotationHandle()
    }

    private func positionRotationHandle() {
        let handleDistance = max(overlayImageView.bounds.height / 2 + 60, 80)
        let rotatedOffset = CGPoint(x: 0, y: handleDistance).applying(CGAffineTransform(rotationAngle: currentRotation))
        let handleCenter = CGPoint(x: bounds.midX + rotatedOffset.x, y: bounds.midY + rotatedOffset.y)
        rotationHandle.center = handleCenter
    }
}

// MARK: - UIGestureRecognizerDelegate

extension OverlayItemView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return isActive
    }
}
