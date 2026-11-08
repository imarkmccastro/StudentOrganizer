import UIKit
import CoreData

/// Form for creating a new TaskItem or editing an existing one.
/// Validates user input before committing to Core Data.
class TaskFormViewController: UIViewController {

    // MARK: - Data passed in from TasksViewController
    var subject: Subject?
    var taskToEdit: TaskItem? // nil = adding a new task, not nil = editing

    // MARK: - Outlets
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var prioritySegmentedControl: UISegmentedControl!
    @IBOutlet weak var completedSwitch: UISwitch!

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if let task = taskToEdit {
            // Edit mode: fill the controls with the saved values.
            title = "Edit Task"
            titleTextField.text = task.title
            detailsTextField.text = task.details
            dueDatePicker.date = task.dueDate ?? Date()
            prioritySegmentedControl.selectedSegmentIndex = Int(task.priority)
            completedSwitch.isOn = task.isDone
        } else {
            // New task mode
            title = "New Task"
            dueDatePicker.date = Date()
        }

        // Tap anywhere on the background to hide the keyboard.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false // do not block taps on the other controls
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Actions
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)

        // Read the text field safely: validate non-empty trimmed title
        let taskTitle = (titleTextField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !taskTitle.isEmpty else {
            showAlert(title: "Title required",
                      message: "Please type a title for your task.")
            return
        }

        // Reuse the task being edited, or create a brand-new one in the Core Data context
        let task = taskToEdit ?? TaskItem(context: CoreDataStack.shared.context)
        task.title = taskTitle
        task.details = detailsTextField.text
        task.dueDate = dueDatePicker.date
        task.priority = Int16(prioritySegmentedControl.selectedSegmentIndex)
        task.isDone = completedSwitch.isOn

        if taskToEdit == nil {
            task.subject = subject // link the new task to its subject
        }

        CoreDataStack.shared.save()
        navigationController?.popViewController(animated: true)
    }
}
