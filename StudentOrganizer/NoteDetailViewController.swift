import UIKit
import CoreData

/// Full-detail view for an individual Note.
/// Displays high-resolution note imagery (or placeholder icon), formatted date/time,
/// full note description, and a destructive delete action with user confirmation.
class NoteDetailViewController: UIViewController {

    // MARK: - Injected Properties
    /// The target Note entity to display and potentially delete.
    var note: Note?

    // MARK: - Interface Builder Outlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Note"

        guard let note = note else { return }
        noteLabel.text = note.text
        dateLabel.text = note.createdAt?.formatted(date: .long, time: .shortened)

        // Show photo full width if available, or fall back to system symbol
        if let data = note.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFit
        } else {
            photoImageView.image = UIImage(systemName: "text.alignleft")
            photoImageView.contentMode = .center
            photoImageView.tintColor = .systemGray3
        }
    }

    // MARK: - User Actions
    /// Prompts the user with a confirmation alert before permanently deleting the note from Core Data.
    @IBAction func deleteTapped(_ sender: UIButton) {
        // Confirmation alert prevents accidental data loss
        let alert = UIAlertController(title: "Delete this note?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {
            [weak self] _ in
            guard let self = self, let note = self.note else { return }

            // Nullify delete rule on Note ensures deleting this note does not delete the parent Subject
            CoreDataStack.shared.context.delete(note)
            CoreDataStack.shared.save()

            // Return to the notes collection grid
            self.navigationController?.popViewController(animated: true)
        }

        alert.addAction(deleteAction)
        present(alert, animated: true)
    }
}
