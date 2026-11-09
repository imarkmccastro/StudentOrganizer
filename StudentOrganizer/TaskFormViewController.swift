import UIKit
import CoreData

/// View controller managing input and persistence for adding or editing a TaskItem.
/// Enforces non-empty title validation and gracefully handles optional details and dates.
class TaskFormViewController: UIViewController {

    // MARK: - Data Injected from TasksViewController
    /// The subject under which the new or edited task is cataloged.
    var subject: Subject?

    /// Holds the existing TaskItem if editing, or nil when creating a new task.
    var taskToEdit: TaskItem?

    // MARK: - Interface Builder Outlets
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var prioritySegmentedControl: UISegmentedControl!
    @IBOutlet weak var completedSwitch: UISwitch!

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if let task = taskToEdit {
            // Edit mode: pre-fill input controls with persistent values
            title = "Edit Task"
            titleTextField.text = task.title
            detailsTextField.text = task.details
            dueDatePicker.date = task.dueDate ?? Date()
            prioritySegmentedControl.selectedSegmentIndex = Int(task.priority)
            completedSwitch.isOn = task.isDone
        } else {
            // Add mode: prepare defaults (current timestamp and initial priority)
            title = "New Task"
            dueDatePicker.date = Date()
        }

        // Add a gesture recognizer allowing users to tap anywhere outside inputs to dismiss the software keyboard.
        // cancelsTouchesInView is false to avoid intercepting touches on buttons, switches, or pickers.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    /// Resigns first responder status across all subviews to hide the keyboard.
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - User Actions
    /// Validates user entries, commits changes to Core Data, and pops back to the task list.
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)

        // Trim whitespace defensively to ensure empty spaces are rejected as titles
        let taskTitle = (titleTextField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !taskTitle.isEmpty else {
            // Alert user that a title is mandatory before creating the task
            showAlert(title: "Title required",
                      message: "Please type a title for your task.")
            return
        }

        // Reuse the existing TaskItem entity if editing, or instantiate a fresh one in the managed context
        let task = taskToEdit ?? TaskItem(context: CoreDataStack.shared.context)
        task.title = taskTitle
        task.details = detailsTextField.text
        task.dueDate = dueDatePicker.date
        task.priority = Int16(prioritySegmentedControl.selectedSegmentIndex)
        task.isDone = completedSwitch.isOn

        // Only assign the subject relationship when creating a new task
        if taskToEdit == nil {
            task.subject = subject
        }

        // Persist to disk and return to the task list
        CoreDataStack.shared.save()
        navigationController?.popViewController(animated: true)
    }
}
