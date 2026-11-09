import UIKit
import CoreData

/// Presents the collection of notes associated with a selected Subject in a 2-column grid.
/// Conforms to UICollectionViewDataSource and UICollectionViewDelegateFlowLayout
/// to compute dynamic, responsive item sizes that adapt to varying screen widths.
class NotesViewController: UIViewController,
                           UICollectionViewDataSource,
                           UICollectionViewDelegateFlowLayout {

    // MARK: - Injected Properties
    /// The active subject whose notes are displayed.
    var subject: Subject?

    // MARK: - State Properties
    /// Collection of Note records fetched from persistent storage.
    private var notes: [Note] = []

    /// Shared Core Data managed object context.
    private let context = CoreDataStack.shared.context

    /// Target number of columns for the photo note grid.
    private let columns: CGFloat = 2

    /// Uniform spacing in points between cells and around grid edges.
    private let spacing: CGFloat = 12

    // MARK: - Interface Builder Outlets
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    /// Reloads notes whenever this view controller appears,
    /// ensuring new photos or edits from NoteFormViewController are displayed immediately.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()
    }

    // MARK: - Core Data Operations
    /// Fetches all Note entities filtered by the active Subject.
    /// Sorts chronologically descending so recent notes appear first.
    private func loadNotes() {
        guard let subject = subject else { return }

        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "subject == %@", subject)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            notes = try context.fetch(request)
        } catch {
            print("Could not fetch notes: \(error)")
            notes = []
        }

        // Show empty state prompt if no notes exist for this subject
        collectionView.backgroundView = notes.isEmpty
            ? emptyStateLabel("No notes yet.\nTap + to add one.") : nil

        collectionView.reloadData()
    }

    // MARK: - User Actions
    /// Triggers navigation to the NoteFormViewController to add a new note.
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
    /// Tapping a note opens NoteDetailViewController with the selected Note model.
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowNoteDetailSegue",
                     sender: notes[indexPath.item])
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    /// Dynamically computes item size so the 2-column grid scales smoothly on any iPhone screen size.
    /// Total available width subtracts the leading, middle, and trailing margins, divided evenly by 2.
    /// Height provides a 1:1 square aspect ratio for the photo plus 40pt for note text caption.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = spacing * (columns + 1)
        let width = floor((collectionView.bounds.width - totalSpacing) / columns)
        return CGSize(width: width, height: width + 40)
    }

    /// Section insets provide outer margins around the grid perimeter.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
    }

    /// Spacing between rows in the vertical grid.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }

    /// Spacing between items within the same horizontal row.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowNoteFormSegue":
            guard let destination = segue.destination as? NoteFormViewController
            else { return }
            destination.subject = subject

        case "ShowNoteDetailSegue":
            guard let destination = segue.destination as? NoteDetailViewController,
                  let note = sender as? Note else { return }
            destination.note = note

        default:
            break
        }
    }
}
