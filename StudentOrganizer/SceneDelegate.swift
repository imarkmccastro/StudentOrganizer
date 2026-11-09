import UIKit
import CoreData

/// Manages the application's UI lifecycle and window scene state.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        // Handles optional launch arguments for automated UI navigation verification and screenshot generation
        if let screenArg = CommandLine.arguments.first(where: { $0.starts(with: "--screen=") }) {
            let screenName = screenArg.replacingOccurrences(of: "--screen=", with: "")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let nav = window?.rootViewController as? UINavigationController else { return }

            let context = CoreDataStack.shared.context
            let subjectReq = NSFetchRequest<Subject>(entityName: "Subject")
            subjectReq.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            let subjects = (try? context.fetch(subjectReq)) ?? []
            let targetSubject = subjects.first(where: { $0.name == "Mobile App Development 2" }) ?? subjects.first

            switch screenName {
            case "tasks":
                if let tasksVC = storyboard.instantiateViewController(withIdentifier: "TasksVC") as? TasksViewController {
                    tasksVC.subject = targetSubject
                    nav.pushViewController(tasksVC, animated: false)
                }

            case "taskform":
                if let tasksVC = storyboard.instantiateViewController(withIdentifier: "TasksVC") as? TasksViewController,
                   let formVC = storyboard.instantiateViewController(withIdentifier: "TaskFormVC") as? TaskFormViewController {
                    tasksVC.subject = targetSubject
                    formVC.subject = targetSubject
                    nav.setViewControllers([nav.viewControllers[0], tasksVC, formVC], animated: false)
                }

            case "notes":
                if let tasksVC = storyboard.instantiateViewController(withIdentifier: "TasksVC") as? TasksViewController,
                   let notesVC = storyboard.instantiateViewController(withIdentifier: "NotesVC") as? NotesViewController {
                    tasksVC.subject = targetSubject
                    notesVC.subject = targetSubject
                    nav.setViewControllers([nav.viewControllers[0], tasksVC, notesVC], animated: false)
                }

            case "noteform":
                if let tasksVC = storyboard.instantiateViewController(withIdentifier: "TasksVC") as? TasksViewController,
                   let notesVC = storyboard.instantiateViewController(withIdentifier: "NotesVC") as? NotesViewController,
                   let noteFormVC = storyboard.instantiateViewController(withIdentifier: "NoteFormVC") as? NoteFormViewController {
                    tasksVC.subject = targetSubject
                    notesVC.subject = targetSubject
                    noteFormVC.subject = targetSubject
                    nav.setViewControllers([nav.viewControllers[0], tasksVC, notesVC, noteFormVC], animated: false)
                }

            case "notedetail":
                if let tasksVC = storyboard.instantiateViewController(withIdentifier: "TasksVC") as? TasksViewController,
                   let notesVC = storyboard.instantiateViewController(withIdentifier: "NotesVC") as? NotesViewController,
                   let noteDetailVC = storyboard.instantiateViewController(withIdentifier: "NoteDetailVC") as? NoteDetailViewController {
                    tasksVC.subject = targetSubject
                    notesVC.subject = targetSubject

                    let noteReq = NSFetchRequest<Note>(entityName: "Note")
                    if let target = targetSubject {
                        noteReq.predicate = NSPredicate(format: "subject == %@", target)
                    }
                    noteReq.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                    let notes = (try? context.fetch(noteReq)) ?? []
                    noteDetailVC.note = notes.first(where: { $0.photoData != nil }) ?? notes.first

                    nav.setViewControllers([nav.viewControllers[0], tasksVC, notesVC, noteDetailVC], animated: false)
                }

            default:
                break
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Persist any outstanding Core Data changes when backgrounding
        CoreDataStack.shared.save()
    }
}
