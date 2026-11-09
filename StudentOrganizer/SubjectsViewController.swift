import UIKit
import CoreData

/// Manages and displays the student's list of academic subjects.
/// Acts as the root view controller in the main navigation hierarchy,
/// providing capabilities to add subjects, view pending task counters,
/// delete subjects with cascading deletion of tasks/notes, and navigate into tasks.
class SubjectsViewController: UITableViewController {

    // MARK: - Properties
    /// In-memory cache of subjects fetched from Core Data, sorted alphabetically.
    private var subjects: [Subject] = []

    /// Shared Core Data managed object context used for database operations.
    private let context = CoreDataStack.shared.context

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Subjects"
    }

    /// Reloads the subject list every time this screen becomes visible.
    /// This ensures task counters update automatically when returning from child screens.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSubjects()
    }

    // MARK: - Core Data Operations
    /// Fetches all Subject entities from Core Data ordered alphabetically by name.
    /// Displays a user-friendly empty state prompt if no subjects are recorded yet.
    private func loadSubjects() {
        let request: NSFetchRequest<Subject> = Subject.fetchRequest()
        // Sort subjects alphabetically for predictable navigation
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            subjects = try context.fetch(request)
        } catch {
            print("Could not fetch subjects: \(error)")
            subjects = []
        }

        // Display an empty state placeholder if the student has no subjects yet
        tableView.backgroundView = subjects.isEmpty
            ? emptyStateLabel("No subjects yet.\nTap + to add one.") : nil

        tableView.reloadData()
    }

    // MARK: - User Actions
    /// Presents a modal alert with a text field allowing the student to name and create a new Subject.
    @IBAction func addSubjectTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Subject",
                                      message: "Enter the name of the subject.",
                                      preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "e.g., Mobile Application Development 2"
            // Capitalize each word according to typical academic course title casing
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [weak self, weak alert] _ in
            // Defensively extract and trim user input to prevent saving empty or whitespace-only subject names
            guard let self = self,
                  let name = alert?.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }

            // Insert a new Subject entity into the managed object context
            let subject = Subject(context: self.context)
            subject.name = name
            subject.createdAt = Date()

            // Persist changes to SQLite store and refresh the table view
            CoreDataStack.shared.save()
            self.loadSubjects()
        }

        alert.addAction(saveAction)
        present(alert, animated: true)
    }

    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return subjects.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubjectCell",
                                                 for: indexPath)
        let subject = subjects[indexPath.row]

        // Access the To-Many relationship 'tasks' without executing a separate fetch request.
        // Core Data lazily resolves the relationship faults as needed.
        let allTasks = subject.tasks as? Set<TaskItem> ?? []
        let pendingCount = allTasks.filter { !$0.isDone }.count

        // Utilize modern UIContentConfiguration for standard iOS cell appearance
        var content = cell.defaultContentConfiguration()
        content.text = subject.name ?? "Untitled subject"
        content.secondaryText = "\(pendingCount) pending task(s)"
        cell.contentConfiguration = content

        // Indicate to the student that tapping a row navigates to detailed contents
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Table View Delegate
    /// Enables swipe-to-delete on subject rows.
    /// The Core Data model specifies a 'Cascade' deletion rule for tasks and notes,
    /// ensuring all associated child records are cleaned up automatically.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        // Cascade rule configured in the data model automatically deletes related TaskItem and Note entities
        context.delete(subjects[indexPath.row])
        CoreDataStack.shared.save()

        subjects.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)

        // Show empty state if the last subject was removed
        tableView.backgroundView = subjects.isEmpty
            ? emptyStateLabel("No subjects yet.\nTap + to add one.") : nil
    }

    /// Handles row selection to drill down into the selected subject's task list.
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Hand the tapped Subject entity as the sender object to the segue
        performSegue(withIdentifier: "ShowTasksSegue",
                     sender: subjects[indexPath.row])
    }

    // MARK: - Navigation
    /// Prepares destination view controllers with required model dependencies before presentation.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowTasksSegue",
              let destination = segue.destination as? TasksViewController,
              let subject = sender as? Subject else { return }

        // Forward the chosen subject entity to TasksViewController
        destination.subject = subject
    }
}
