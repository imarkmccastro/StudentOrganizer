import UIKit
import CoreData

/// Displays a 2-column grid of notes for a selected Subject using UICollectionView.
/// Allows adding notes and opening existing notes to view details or delete them.
class NotesViewController: UIViewController,
                           UICollectionViewDataSource,
                           UICollectionViewDelegateFlowLayout {

    // MARK: - Properties
    var subject: Subject?

    private var notes: [Note] = []
    private let context = CoreDataStack.shared.context

    private let columns: CGFloat = 2 // number of cells per row
    private let spacing: CGFloat = 12 // gap between cells and around the grid

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()
    }

    // MARK: - Core Data
    private func loadNotes() {
        guard let subject = subject else { return }

        let request: NSFetchRequest<Note> = Note.fetchRequest()
        // Only notes belonging to this subject
        request.predicate = NSPredicate(format: "subject == %@", subject)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            notes = try context.fetch(request)
        } catch {
            print("Could not fetch notes: \(error)")
            notes = []
        }

        // Show empty state prompt if no notes exist yet
        collectionView.backgroundView = notes.isEmpty
            ? emptyStateLabel("No notes yet.\nTap + to add one.") : nil
        collectionView.reloadData()
    }

    // MARK: - Actions
    @IBAction func addNoteTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowNoteFormSegue", sender: nil)
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "NoteCell", for: indexPath) as? NoteCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: notes[indexPath.item])
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowNoteDetailSegue",
                     sender: notes[indexPath.item])
    }

    // MARK: - UICollectionViewDelegateFlowLayout (grid size and spacing)
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Total width minus all gaps, divided equally between the columns.
        let totalSpacing = spacing * (columns + 1)
        let width = floor((collectionView.bounds.width - totalSpacing) / columns)
        return CGSize(width: width, height: width + 40) // square photo + label area
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }
}
