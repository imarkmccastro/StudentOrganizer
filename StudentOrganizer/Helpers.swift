import UIKit
extension UIViewController {
    /// Shows a simple alert with one OK button (used for validation messages).
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
extension UIImage {
    /// Returns a smaller copy whose longest side is at most maxDimension pixels.
    /// Photos from the iPhone camera are huge; shrinking them keeps the database small.
    func resized(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1 // 1 point = 1 pixel, so the pixel size is exactly newSize
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
/// A centered gray label shown in a list or grid when there is nothing to display.
func emptyStateLabel(_ message: String) -> UILabel {
    let label = UILabel()
    label.text = message
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .body)
    return label
}

