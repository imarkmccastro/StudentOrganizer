import UIKit

/// Custom UICollectionViewCell for displaying a note in a two-column grid.
/// Displays an attached photo if available, or a fallback icon otherwise.
class NoteCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!

    // Called once when the cell is loaded from the storyboard: set up its look.
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 12
        clipsToBounds = true
        backgroundColor = .secondarySystemBackground
        photoImageView.clipsToBounds = true
    }

    /// Fills the cell with one Note from the database.
    func configure(with note: Note) {
        noteLabel.text = note.text

        if let data = note.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFill // fill the square, crop extra
        } else {
            // No photo: show a text icon placeholder instead.
            photoImageView.image = UIImage(systemName: "text.alignleft")
            photoImageView.contentMode = .center
            photoImageView.tintColor = .systemGray3
        }
    }

    // Cells are reused while scrolling, so clear the old picture first.
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }
}
