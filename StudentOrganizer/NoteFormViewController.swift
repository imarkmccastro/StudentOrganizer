import UIKit
import PhotosUI
import CoreData

/// Handles creation of new notes with optional image picking via PHPickerViewController.
/// Scales images to a maximum dimension of 1024 before storing in Core Data.
class NoteFormViewController: UIViewController, PHPickerViewControllerDelegate {

    // MARK: - Data passed in from NotesViewController
    var subject: Subject?

    // The photo the student picked (nil = no photo).
    private var selectedImage: UIImage?

    // MARK: - Outlets
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Note"

        // Give the text view a visible border.
        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.systemGray4.cgColor
        noteTextView.layer.cornerRadius = 8

        // Start with a gray placeholder icon until a photo is chosen.
        photoImageView.image = UIImage(systemName: "photo")
        photoImageView.tintColor = .systemGray3
        photoImageView.contentMode = .center

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Actions
    @IBAction func choosePhotoTapped(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // photos only, no videos
        configuration.selectionLimit = 1 // one photo per note

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        let text = (noteTextView.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            showAlert(title: "Note is empty",
                      message: "Please write something before saving.")
            return
        }

        let note = Note(context: CoreDataStack.shared.context)
        note.text = text
        note.createdAt = Date()
        // Convert the image to JPEG bytes for the Binary Data attribute.
        // If no photo was chosen, selectedImage is nil, so photoData stays nil too.
        note.photoData = selectedImage?.jpegData(compressionQuality: 0.8)
        note.subject = subject

        CoreDataStack.shared.save()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - PHPickerViewControllerDelegate
    // Called when the student taps a photo, or taps Cancel.
    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        // results is empty when the student cancelled.
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Loading happens on a background thread, so update the UI on the main thread.
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let image = object as? UIImage else { return }
            let smallImage = image.resized(maxDimension: 1024) // keep the database small
            DispatchQueue.main.async {
                self?.selectedImage = smallImage
                self?.photoImageView.image = smallImage
                self?.photoImageView.contentMode = .scaleAspectFit
            }
        }
    }
}
