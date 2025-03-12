//
//  CanvasViewController.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import UIKit

class CanvasViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let canvasView = CanvasView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAddButton()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Configure ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .lightGray
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Configure CanvasView
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(canvasView)

        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            canvasView.widthAnchor.constraint(equalToConstant: 1000),
            canvasView.heightAnchor.constraint(equalToConstant: 2000)
        ])
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

    @objc private func showOverlaySelection() {
        let overlaySelectionVC = OverlaySelectionViewController()
        overlaySelectionVC.delegate = self
        let navController = UINavigationController(rootViewController: overlaySelectionVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
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
        let overlayView = OverlayItemView(image: image)
        canvasView.addSubview(overlayView)

        // Position overlay at the center initially
        overlayView.center = CGPoint(x: canvasView.bounds.midX, y: canvasView.bounds.midY)
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
