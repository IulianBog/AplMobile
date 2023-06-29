//
//  ViewController.swift
//  AplicatiiMobile
//
//  Created by Iulian Bogdanovici on 26.06.2023.
//

import UIKit
import CoreData
import SafariServices
import AVFoundation

protocol ToDoCellDelegate: AnyObject {
    func cellDidToggleIsCompleted(cell: ToDoTableViewCell)
}

enum Text {
    case toDoTitle
    case doneTitle
    
    var text: String {
        switch self {
        case .toDoTitle:
            return "To do"
        case .doneTitle:
            return "Done"
        default:
            return ""
        }
    }
}


class ToDosViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var texts: [NSManagedObject] = []
    var filteredTexts: [NSManagedObject] = []
    let imagePicker = UIImagePickerController()
    var imageIndex = 0
    var vcTitle: String { Text.toDoTitle.text }
    var soundEffect: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filterToDos()
        setupDateLabel()
        tableView.register(UINib(nibName: "ToDoTableViewCell", bundle: nil), forCellReuseIdentifier: "ToDoTableViewCell")
        addButton.layer.cornerRadius = 25
        addButton.layer.opacity = 0.9
        imagePicker.delegate = self
        titleLabel.text = vcTitle
    }
    
    private func setupDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMMM"
        
        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        
        dayLabel.text = formattedDate
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapFunction))
        dayLabel.isUserInteractionEnabled = true
        dayLabel.addGestureRecognizer(tap)
    }
    
    // MARK: - CoreData: get
    func fetchToDos() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ToDo")
        do {
            texts = try managedContext.fetch(fetchRequest)
        }
        catch let error as NSError {
            print("Could not fetch, \(error), \(error.userInfo) ")
        }
    }
    
    func filterToDos() {
        fetchToDos()
        filteredTexts = []
        filteredTexts = texts.filter({ ($0.value(forKey: "isCompleted") as! Bool) == false
        })
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        let ac = UIAlertController(title: "I should not forget to ... ", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Add", style: .default) { [unowned ac] _ in
            if let answer = ac.textFields![0].text {
                self.saveToCoreData(answer)
            }
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    
}

extension ToDosViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredTexts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoTableViewCell", for: indexPath) as? ToDoTableViewCell else {
            return UITableViewCell()
        }
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        cell.selectionStyle = .none
        cell.delegate = self
        cell.isCompleted = filteredTexts[indexPath.section].value(forKey: "isCompleted") as! Bool
        cell.vcTitle = vcTitle
        cell.configure(with: filteredTexts[indexPath.section].value(forKey: "name") as! String, data: filteredTexts[indexPath.section].value(forKey: "image") as? Data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint)
    -> UIContextMenuConfiguration? {
        
        let text = filteredTexts[indexPath.section].value(forKey: "name") as! String
        let id = filteredTexts[indexPath.section].value(forKey: "id") as! UUID
        
        let identifier = "\(id)" as NSString
        
        return UIContextMenuConfiguration(
            identifier: identifier,
            previewProvider: nil) { _ in
                let editAction = UIAction(
                    title: "Edit",
                    image: UIImage(systemName: "pencil")) { _ in
                        
                        let ac = UIAlertController(title: "Edit", message: nil, preferredStyle: .alert)
                        ac.addTextField()
                        ac.textFields![0].text = text
                        let submitAction = UIAlertAction(title: "Done", style: .default) { [unowned ac] _ in
                            if let answer = ac.textFields![0].text {
                                self.update(for: id, newText: answer)
                            }
                        }
                        
                        ac.addAction(submitAction)
                        self.present(ac, animated: true)
                    }
                
                let deleteAction = UIAction(
                    title: "Delete",
                    image: UIImage(systemName: "xmark.bin")) { _ in
                        self.deleteFromCoreData(with: id)
                    }
                
                let shareAction = UIAction(
                    title: "Share",
                    image: UIImage(systemName: "square.and.arrow.up")) { _ in
                        self.shareToDo(text: text)
                    }
                
                let addImageAction = UIAction(
                    title: "Add Background Image",
                    image: UIImage(systemName: "timelapse")) { _ in
                        self.imageIndex = indexPath.section
                        self.showImagePicker()
                    }
                
                return UIMenu(title: "", image: nil, children: [editAction, deleteAction, shareAction, addImageAction])
            }
    }
    
    
}
// MARK: - CoreData
extension ToDosViewController {
    // add new to do item
    private func saveToCoreData(_ text: String) {
        let entity = NSEntityDescription.entity(forEntityName: "ToDo", in: managedContext)!
        let todo = NSManagedObject(entity: entity, insertInto: managedContext)
        
        todo.setValue(UUID(), forKey: "id")
        todo.setValue(false, forKey: "isCompleted")
        todo.setValue(text, forKey: "name")
        
        do {
            try managedContext.save()
            filterToDos()
            print(todo)
        } catch let error as NSError {
            print("Could not save, \(error), \(error.userInfo) ")
        }
    }
    
    // delete item
    private func deleteFromCoreData(with id: UUID) {
        if let object = getById(id) {
            managedContext.delete(object)
            do {
                try managedContext.save()
                filterToDos()
            } catch let error as NSError {
                print("Could not delete, \(error), \(error.userInfo) ")
            }
        }
        
    }
    
    // get item by id
    private func getById(_ id: UUID) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ToDo")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            return try managedContext.fetch(fetchRequest).first as? NSManagedObject
        } catch let error as NSError {
            print("Could not delete, \(error), \(error.userInfo) ")
            return nil
        }
    }
    
    // update item
    private func update(for id: UUID, newText: String? = nil, image: UIImage? = nil, isCompleted: Bool? = nil) {
        if let object = getById(id) {
            if let text = newText { object.setValue(text, forKey: "name") }
            if let image = image { object.setValue(image.pngData(), forKey: "image") }
            if let _ = isCompleted {
                object.setValue(true, forKey: "isCompleted")
            }
            do {
                try managedContext.save()
                filterToDos()
            } catch let error as NSError {
                print("Could not update, \(error), \(error.userInfo) ")
            }
        }
    }
}

// MARK: - Implementat o metoda de Share (UIActivityViewController)
extension ToDosViewController {
    private func shareToDo(text: String) {
        let string = "Please remind me of this: \(text)"
        let activityViewController =
        UIActivityViewController(activityItems: [string],
                                 applicationActivities: nil)
        
        present(activityViewController, animated: true) {
        }
    }
}

// MARK: - Importat content media (poze sau video) din media library
extension ToDosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func showImagePicker() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            update(for: filteredTexts[imageIndex].value(forKey: "id") as! UUID, image: pickedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Integrat WKWebView || SFSafariViewController
extension ToDosViewController: SFSafariViewControllerDelegate {
    @objc
    func tapFunction(sender:UITapGestureRecognizer) {
        let safariVC = SFSafariViewController(url: URL(string: "https://www.accuweather.com/en/ro/bucharest/287430/weather-forecast/287430")! as URL)
        self.present(safariVC, animated: true, completion: nil)
        safariVC.delegate = self
    }
}

// MARK: - Video/Audio Playback sau streaming
extension ToDosViewController: ToDoCellDelegate {
    func cellDidToggleIsCompleted(cell: ToDoTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        guard let url = Bundle.main.url(forResource: "Achievement-mp3-sound", withExtension: "mp3") else { return }
        do {
            soundEffect = try AVAudioPlayer(contentsOf: url)
            soundEffect?.play()
        } catch {
            // couldn't load file
        }
        update(for: filteredTexts[indexPath.section].value(forKey: "id") as! UUID, isCompleted: true)
        filterToDos()
    }
    
}
