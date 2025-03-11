//
//  OverlayCell.swift
//  SCRLCanvasPrototype
//
//  Created by Sergey Slobodenyuk on 2025-03-11.
//

import UIKit

class OverlayCell: UICollectionViewCell {
    static let identifier = "OverlayCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.clipsToBounds = true
        return iv
    }()

    private var currentImageURL: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {
        contentView.addSubview(imageView)
        contentView.backgroundColor = .clear

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with overlay: OverlayItem) {
        currentImageURL = overlay.imageURL
        Task { await loadImage(from: overlay.imageURL) }
    }

    private func loadImage(from urlString: String) async {
        guard let url = URL(string: urlString) else { return }

        if let cachedImage = ImageCache.shared.get(urlString) {
            self.imageView.image = cachedImage
            return
        }

        self.imageView.image = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    if self.currentImageURL == urlString {
                        self.imageView.image = image
                        ImageCache.shared.set(urlString, image: image)
                    }
                }
            }
        } catch {
            print("Image loading error:", error.localizedDescription)
        }
    }
}
