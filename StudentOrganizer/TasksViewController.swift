import UIKit
import CoreData

/// Manages the list of tasks for a selected Subject.
/// Handles task filtering by subject, sorting by completion and due date,
/// and contextual actions for marking tasks done or deleting them.
class TasksViewController: UITableViewController {

    // MARK: - Properties
    /// Set by SubjectsViewController in prepare(for:sender:).
    var subject: Subject?

    private var tasks: [TaskItem] = []
    private let context = CoreDataStack.shared.context

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = subject?.name
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks() // Refresh task list when returning from the Task Form
    }

    // MARK: - Core Data
    private func loadTasks() {
        guard let subject = subject else { return }

        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        // Only load tasks that belong to the active subject
        request.predicate = NSPredicate(format: "subject == %@", subject)
        // Show pending tasks first, followed by the earliest due date
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

        // Show a helpful empty-state message if no tasks exist
        tableView.backgroundView = tasks.isEmpty
            ? emptyStateLabel("No tasks yet.\nTap + to add one.") : nil
        tableView.reloadData()
    }

    // MARK: - Actions
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        // sender is nil to open the form in creation mode
        performSegue(withIdentifier: "ShowTaskFormSegue", sender: nil)
    }

    @IBAction func notesTapped(_ sender: UIBarButtonItem) {
        // Navigate to the photo notes grid for this subject
        performSegue(withIdentifier: "ShowNotesSegue", sender: nil)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell",
                                                 for: indexPath)
        let task = tasks[indexPath.row]
        let dueText = task.dueDate?.formatted(date: .abbreviated, time: .shortened)
            ?? "no due date"

        var content = cell.defaultContentConfiguration()
        content.text = task.title ?? "Untitled task"
        content.secondaryText = "Due \(dueText) - \(priorityName(for: task.priority))"
        // Dim completed task title
        content.textProperties.color = task.isDone ? .secondaryLabel : .label
        cell.contentConfiguration = content
        // Display checkmark accessory if the task is finished
        cell.accessoryType = task.isDone ? .checkmark : .none
        return cell
    }

    /// Converts integer priority (0 = Low, 1 = Medium, 2 = High) to display text
    private func priorityName(for value: Int16) -> String {
        switch value {
        case 0: return "Low"
        case 2: return "High"
        default: return "Medium"
        }
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Pass the tapped task to open the form in edit mode
        performSegue(withIdentifier: "ShowTaskFormSegue",
                     sender: tasks[indexPath.row])
    }

    // Swipe right: toggle completed / pending status
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

    // Swipe left: delete task
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
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
            destination.taskToEdit = sender as? TaskItem // nil when adding a new task
        default:
            break
        }
    }
}
