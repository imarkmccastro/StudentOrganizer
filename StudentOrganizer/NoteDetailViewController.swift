import UIKit
import CoreData

/// Displays a note in full detail: date, text, and full-resolution photo (if attached).
/// Allows the user to delete the note with confirmation.
class NoteDetailViewController: UIViewController {

    // MARK: - Data passed in from NotesViewController
    var note: Note?

    // MARK: - Outlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Note"

        guard let note = note else { return }
        noteLabel.text = note.text
        dateLabel.text = note.createdAt?.formatted(date: .long, time: .shortened)

        if let data = note.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFit
        } else {
            photoImageView.image = UIImage(systemName: "text.alignleft")
            photoImageView.contentMode = .center
            photoImageView.tintColor = .systemGray3
        }
    }

    // MARK: - Actions
    @IBAction func deleteTapped(_ sender: UIButton) {
        // Ask first: deleting cannot be undone.
        let alert = UIAlertController(title: "Delete this note?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {
            [weak self] _ in
            guard let self = self, let note = self.note else { return }
            CoreDataStack.shared.context.delete(note)
            CoreDataStack.shared.save()
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(deleteAction)
        present(alert, animated: true)
    }
}
