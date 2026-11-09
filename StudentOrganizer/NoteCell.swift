import UIKit

/// Custom UICollectionViewCell rendering an individual note inside the 2-column grid.
/// Features a square top image (photo or placeholder SF Symbol) and a bottom text summary.
class NoteCell: UICollectionViewCell {

    // MARK: - Interface Builder Outlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!

    // MARK: - Cell Life Cycle
    /// Configures visual styling when deserialized from the storyboard.
    override func awakeFromNib() {
        super.awakeFromNib()
        // Provide modern rounded card appearance
        layer.cornerRadius = 12
        clipsToBounds = true
        backgroundColor = .secondarySystemBackground
        photoImageView.clipsToBounds = true
    }

    /// Populates cell subviews with persistent data from the provided Note model.
    func configure(with note: Note) {
        noteLabel.text = note.text

        // If an image was saved as JPEG binary data, decode and scale it to aspect fill
        if let data = note.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFill // fill square photo area and clip overflow
        } else {
            // When no photo is attached, display an SF Symbol icon representing plain text notes
            photoImageView.image = UIImage(systemName: "text.alignleft")
            photoImageView.contentMode = .center
            photoImageView.tintColor = .systemGray3
        }
    }

    /// Reset image state before cell reuse to prevent visual flickering during fast scrolling.
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }
}
