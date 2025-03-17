//
//  OverlaySelectionViewController.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import UIKit

protocol OverlaySelectionDelegate: AnyObject {
    func didSelectOverlay(_ overlay: OverlayItem)
}

class OverlaySelectionViewController: UIViewController {

    weak var delegate: OverlaySelectionDelegate?
    private var overlays: [OverlayItem] = []

    private let overlayFetcher: OverlayFetcher

    init(overlayFetcher: OverlayFetcher = .shared) {
        self.overlayFetcher = overlayFetcher
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        Task { await fetchOverlays() }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupNavigationBar()

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(OverlayCell.self, forCellWithReuseIdentifier: OverlayCell.identifier)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        navigationItem.title = "Overlays"

        let config = UIImage.SymbolConfiguration(hierarchicalColor: .label)
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill", withConfiguration: config),
            style: .plain,
            target: self,
            action: #selector(closeSheet)
        )
        navigationItem.rightBarButtonItem = closeButton
    }

    @objc private func closeSheet() {
        dismiss(animated: true)
    }

    func fetchOverlays() async {
        do {
            overlays = try await overlayFetcher.fetchOverlays()
            collectionView.reloadData()
        } catch {
            print("Failed to fetch overlays:", error.localizedDescription)
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension OverlaySelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return overlays.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OverlayCell.identifier, for: indexPath) as! OverlayCell
        cell.configure(with: overlays[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedOverlay = overlays[indexPath.row]
        delegate?.didSelectOverlay(selectedOverlay)
        dismiss(animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = 4
        let padding: CGFloat = 10
        let totalPadding = padding * (itemsPerRow - 1)
        let itemWidth = (collectionView.bounds.width - totalPadding) / itemsPerRow
        return CGSize(width: itemWidth, height: itemWidth)
    }
}


#if DEBUG
import SwiftUI

struct OverlaySelectionPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UINavigationController(rootViewController: OverlaySelectionViewController())
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    OverlaySelectionPreview()
}

#endif
