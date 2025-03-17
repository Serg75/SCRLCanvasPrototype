//
//  CanvasViewController.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import UIKit

class CanvasViewController: UIViewController {

    // MARK: - Properties

    // set canvas size to 16:5 ratio
    private static let canvasWidth: CGFloat = 4800
    private static let canvasHeight: CGFloat = 1500
    private static let canvasFrame: CGRect = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
    
    private let canvasView = CanvasView(frame: canvasFrame)
    private let scrollView = UIScrollView()
    private let snapDetector = SnapDetector()

    private var activeItem: OverlayItemView?
    private var overlays: [OverlayItemView] = []
    private var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    private var lastSnapResult: SnapDetector.SnapResult?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupAddButton()
        setupZoom()
        addCanvasTapGesture()

        snapDetector.updateGuidelines(
            vertical: canvasView.verticalGuidelines,
            horizontal: canvasView.horizontalGuidelines
        )

        hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        hapticFeedbackGenerator?.prepare()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard scrollView.zoomScale > 0 else { return }

        let horizontalMargin: CGFloat = 40
        let scrollViewSize = scrollView.bounds.size
        let scaledCanvasHeight = CanvasViewController.canvasHeight * scrollView.zoomScale

        // calculate insets to vertically center the canvas
        let insetX = horizontalMargin
        let insetY = max((scrollViewSize.height - scaledCanvasHeight) / 2, 0)

        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .darkGray
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 4.0
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.backgroundColor = .white
        scrollView.addSubview(canvasView)

        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            canvasView.widthAnchor.constraint(equalToConstant: CanvasViewController.canvasWidth),
            canvasView.heightAnchor.constraint(equalToConstant: CanvasViewController.canvasHeight)
        ])

        scrollView.contentSize = CGSize(width: CanvasViewController.canvasWidth,
                                        height: CanvasViewController.canvasHeight)
    }

    private func setupAddButton() {
        let addButton = UIButton(type: .system)
        addButton.setTitle("+", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 30, weight: .bold)
        addButton.addTarget(self, action: #selector(showOverlaySelection), for: .touchUpInside)

        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: 50),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupZoom() {
        scrollView.zoomScale = 0.2 // start zoomed out
    }

    private func addCanvasTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCanvasTap))
        canvasView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions

    @objc private func showOverlaySelection() {
        let overlaySelectionVC = OverlaySelectionViewController()
        overlaySelectionVC.delegate = self
        let navController = UINavigationController(rootViewController: overlaySelectionVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }

    @objc private func handleCanvasTap() {
        activeItem?.setActive(false) // deactivate any active item
        activeItem = nil
    }
}

// MARK: - Overlay Selection Delegate

extension CanvasViewController: OverlaySelectionDelegate {
    func didSelectOverlay(_ overlay: OverlayItem) {
        Task {
            if let image = await fetchOverlayImage(from: overlay.imageURL) {
                addOverlayToCanvas(image: image)
            }
        }
    }

    private func addOverlayToCanvas(image: UIImage) {
        let overlayView = OverlayItemView(image: image, delegate: self)
        overlays.append(overlayView)
        snapDetector.updateOverlays(overlays)
        canvasView.addSubview(overlayView)

        let visibleCenterX = scrollView.contentOffset.x + (scrollView.bounds.width / 2)
        let visibleCenterY = scrollView.contentOffset.y + (scrollView.bounds.height / 2)

        let canvasCenter = CGPoint(
            x: visibleCenterX / scrollView.zoomScale,
            y: visibleCenterY / scrollView.zoomScale
        )
        overlayView.center = canvasCenter
        overlayView.prepareForDisplay()
        setActiveItem(overlayView)
    }

    private func fetchOverlayImage(from urlString: String) async -> UIImage? {
        if let cachedImage = ImageCache.shared.get(urlString) {
            return cachedImage
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                ImageCache.shared.set(urlString, image: image)
                return image
            }
        } catch {
            print("Image fetching error:", error.localizedDescription)
        }
        return nil
    }
}

// MARK: - UIScrollViewDelegate

extension CanvasViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return canvasView
    }
}

// MARK: - OverlayItemViewDelegate

extension CanvasViewController: OverlayItemViewDelegate {
    func setActiveItem(_ item: OverlayItemView) {
        activeItem?.setActive(false) // deactivate previously active item
        activeItem = item
        item.setActive(true) // activate the new item
    }

    func updateSnapLines(for result: SnapDetector.SnapResult) {
        let verticalSnapPositions = result.snapLines.filter { $0.isVertical }.map { $0.position }
        let horizontalSnapPositions = result.snapLines.filter { !$0.isVertical }.map { $0.position }

        if verticalSnapPositions.isEmpty && horizontalSnapPositions.isEmpty {
            canvasView.hideSnapLines()
            lastSnapResult = nil
        } else {
            if result != lastSnapResult {
                canvasView.showSnapLines(vertical: verticalSnapPositions, horizontal: horizontalSnapPositions)
                hapticFeedbackGenerator?.impactOccurred()
                lastSnapResult = result
            }
        }
    }

    func setScrollEnabled(_ enabled: Bool) {
        scrollView.isScrollEnabled = enabled
    }

    func detectSnaps(for overlay: OverlayItemView, proposedPosition: CGPoint) -> SnapDetector.SnapResult {
        return snapDetector.detectSnaps(for: overlay, proposedPosition: proposedPosition)
    }
}


// MARK: - SwiftUI Preview (For Debugging)

#if DEBUG
import SwiftUI

struct CanvasPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CanvasViewController {
        return CanvasViewController()
    }

    func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) {}
}

#Preview {
    CanvasPreview()
}

#endif
