import UIKit
import PhotosUI
import CoreData

/// Manages creation and saving of a new Note entity.
/// Uses the modern PhotosUI framework (PHPickerViewController) for private, out-of-process
/// photo selection without needing user privacy permissions or Info.plist modifications.
/// Resizes camera photos to 1024 max dimension to conserve device storage.
class NoteFormViewController: UIViewController, PHPickerViewControllerDelegate {

    // MARK: - Injected Properties
    /// The subject under which the new note will be saved.
    var subject: Subject?

    // MARK: - State Properties
    /// The downscaled UIImage chosen by the student (nil if note is text-only).
    private var selectedImage: UIImage?

    // MARK: - Interface Builder Outlets
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Note"

        // Style the text view with a subtle border and rounded corners to demarcate the input region
        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.systemGray4.cgColor
        noteTextView.layer.cornerRadius = 8

        // Start with a generic gray placeholder symbol until the user picks a photo
        photoImageView.image = UIImage(systemName: "photo")
        photoImageView.tintColor = .systemGray3
        photoImageView.contentMode = .center

        // Tap gesture to dismiss keyboard when tapping outside the text view
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    /// Hides keyboard by ending editing across the view hierarchy.
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - User Actions
    /// Launches Apple's PHPickerViewController configured for single-photo selection.
    @IBAction func choosePhotoTapped(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // images only, filters out video
        configuration.selectionLimit = 1 // only 1 photo per note

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    /// Validates note content and writes the new Note into Core Data.
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)

        // Defensively trim text to prevent storing empty or whitespace-only notes
        let text = (noteTextView.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            showAlert(title: "Note is empty",
                      message: "Please write something before saving.")
            return
        }

        // Create new Note entity within Core Data context
        let note = Note(context: CoreDataStack.shared.context)
        note.text = text
        note.createdAt = Date()

        // Compress image to JPEG at 80% quality to optimize storage efficiency
        // If no photo was picked, selectedImage is nil and photoData remains nil
        note.photoData = selectedImage?.jpegData(compressionQuality: 0.8)
        note.subject = subject

        // Commit to database and pop back to grid
        CoreDataStack.shared.save()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - PHPickerViewControllerDelegate
    /// Delegate callback executed when the user completes or cancels photo selection.
    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        // Return quietly if user cancelled
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Photos are loaded asynchronously off the main thread
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let image = object as? UIImage else { return }

            // Downscale high-resolution camera photos so SQLite database remains lightweight
            let smallImage = image.resized(maxDimension: 1024)

            DispatchQueue.main.async {
                self?.selectedImage = smallImage
                self?.photoImageView.image = smallImage
                self?.photoImageView.contentMode = .scaleAspectFit
            }
        }
    }
}
