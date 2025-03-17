# SCRLCanvasPrototype

An iOS prototype that simulates a canvas-based editor with overlay elements, snapping functionality, and zooming support.\
\
It was created as a test assignment.

## Features

- Scrollable and zoomable canvas (`CanvasViewController`, `CanvasView`)
- Overlays fetched from a remote API (`OverlayFetcher`)
- Overlay selection sheet (`OverlaySelectionViewController`)
- Snapping to guidelines and other overlays (`SnapDetector`)
- Visual snap lines with haptic feedback
- In-memory image caching (`ImageCache`)
- Custom overlay views with interactive dragging (`OverlayItemView`)

## Project Structure

- **CanvasViewController.swift**: Manages the canvas, overlays, zoom, and snapping logic.
- **CanvasView.swift**: Renders static guidelines and dynamic snap lines.
- **OverlayFetcher.swift**: Fetches overlay data from a remote API.
- **OverlaySelectionViewController.swift**: Displays a modal with available overlays to add.
- **OverlayItemView.swift**: Interactive overlay views with drag and tap gestures.
- **SnapDetector.swift**: Logic for detecting snapping to guidelines and other overlays.
- **OverlayCell.swift**: UICollectionViewCell for displaying overlay thumbnails.
- **OverlayItem.swift**: Models for overlay categories and items.
- **ImageCache.swift**: Lightweight in-memory cache for images.

## Notes

- UIKit-based, targeting iOS 16+
- Uses Swift concurrency (`async/await`) for network and image loading
- Includes SwiftUI previews for debugging UI in Xcode

## Author

Created by Sergey Slobodenyuk on March 2025
