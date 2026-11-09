import UIKit
import CoreData

/// Manages and displays the list of tasks belonging to a specific Subject.
/// Supports status toggling (done/undo) via leading swipe gestures,
/// destructive task deletion via trailing swipe gestures,
/// row selection to edit tasks, and header navigation to the photo notes gallery.
class TasksViewController: UITableViewController {

    // MARK: - Properties
    /// The parent Subject instance injected by SubjectsViewController during navigation segue.
    var subject: Subject?

    /// Local cache of tasks fetched for this subject, ordered by completion and due date.
    private var tasks: [TaskItem] = []

    /// Shared Core Data managed object context used for fetching, mutating, and deleting tasks.
    private let context = CoreDataStack.shared.context

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Display the subject name as the navigation bar title
        title = subject?.name
    }

    /// Automatically re-queries Core Data whenever the screen appears,
    /// refreshing the task list after adding or editing tasks in TaskFormViewController.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
    }

    // MARK: - Core Data Operations
    /// Fetches all TaskItem entities matching the current subject.
    /// Sorts unfinished tasks first so urgent work remains prominent,
    /// followed chronologically by earliest due date.
    private func loadTasks() {
        guard let subject = subject else { return }

        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        // Filter strictly by the active subject foreign-key relationship
        request.predicate = NSPredicate(format: "subject == %@", subject)
        // Order pending tasks above finished ones, then earliest deadlines first
        request.sortDescriptors = [
            NSSortDescriptor(key: "isDone", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true)
        ]

        do {
            tasks = try context.fetch(request)
        } catch {
            print("Could not fetch tasks: \(error)")
            tasks = []
        }

        // Show empty state prompt if this subject has no tasks assigned
        tableView.backgroundView = tasks.isEmpty
            ? emptyStateLabel("No tasks yet.\nTap + to add one.") : nil

        tableView.reloadData()
    }

    // MARK: - User Actions
    /// Triggers navigation to the TaskFormViewController in creation mode (sender = nil).
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowTaskFormSegue", sender: nil)
    }

    /// Pushes the NotesViewController gallery for the current subject.
    @IBAction func notesTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowNotesSegue", sender: nil)
    }

    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell",
                                                 for: indexPath)
        let task = tasks[indexPath.row]

        // Format due date concisely for readability on compact screens
        let dueText = task.dueDate?.formatted(date: .abbreviated, time: .shortened)
            ?? "no due date"

        var content = cell.defaultContentConfiguration()
        content.text = task.title ?? "Untitled task"
        content.secondaryText = "Due \(dueText) - \(priorityName(for: task.priority))"

        // Visually de-emphasize completed tasks using secondary label coloring
        content.textProperties.color = task.isDone ? .secondaryLabel : .label
        cell.contentConfiguration = content

        // Indicate completion status with a native checkmark
        cell.accessoryType = task.isDone ? .checkmark : .none
        return cell
    }

    /// Maps numerical priority enum values to human-readable strings.
    /// Core Data stores priorities as Int16 (0 = Low, 1 = Medium, 2 = High).
    private func priorityName(for value: Int16) -> String {
        switch value {
        case 0: return "Low"
        case 2: return "High"
        default: return "Medium"
        }
    }

    // MARK: - Table View Delegate
    /// Tapping an existing task passes the model object to open TaskFormViewController in edit mode.
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowTaskFormSegue",
                     sender: tasks[indexPath.row])
    }

    /// Leading swipe action (swipe right) toggles completion status between Done and Undo.
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        let title = task.isDone ? "Undo" : "Done"

        let action = UIContextualAction(style: .normal, title: title) {
            [weak self] _, _, completion in
            task.isDone.toggle()
            CoreDataStack.shared.save()
            self?.loadTasks()
            completion(true)
        }
        action.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [action])
    }

    /// Trailing swipe action (swipe left) provides destructive deletion of individual tasks.
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            // Nullify delete rule on TaskItem ensures deleting this task does not affect the Subject
            self.context.delete(self.tasks[indexPath.row])
            CoreDataStack.shared.save()
            self.loadTasks()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowTaskFormSegue":
            guard let destination = segue.destination as? TaskFormViewController
            else { return }
            destination.subject = subject
            // If sender is a TaskItem, the form opens in edit mode; nil indicates add mode
            destination.taskToEdit = sender as? TaskItem

        case "ShowNotesSegue":
            guard let destination = segue.destination as? NotesViewController
            else { return }
            // Pass the parent subject forward so the photo notes gallery filters properly
            destination.subject = subject

        default:
            break
        }
    }
}
