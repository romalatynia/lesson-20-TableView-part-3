//
//  DirectoryViewController.swift
//  TableView_part_3
//
//  Created by Harbros47 on 4.02.21.
//

import UIKit
enum Constants {
    static let folderIdentifier = "FolderCell"
    static let fileIdentifier = "FileCell"
    static let placeholder = "Enter name folder"
    static let ok = "Ok"
    static let cancel = "Cancel"
    static let createFolder = "Create Folder"
    static let newFolder = "New folder"
    static let directory = "Directory"
}

class DirectoryViewController: UITableViewController {
    
    private var path = "/Users/romalatynia/Documents/developer harbros"
    private var pathContents = [String]()
    private var selectedPath = ""
    private var documentDir: NSString?
    private var fileManager: FileManager?
    private var tempFilesNames = [String]()
    private var filesNames =  [String]()
    private var foldersNames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pathContents = getContents(atPath: path)
        navigationItem.title = (path as NSString).lastPathComponent
        fileManager = FileManager.default
        let dirPaths: NSArray = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ) as NSArray
        documentDir = dirPaths[0] as? NSString
        tableView.register(
            UINib(nibName: "TableViewCell", bundle: nil),
            forCellReuseIdentifier: Constants.fileIdentifier
        )
        tableView.register(
            UINib(nibName: "FolderCell", bundle: nil),
            forCellReuseIdentifier: Constants.folderIdentifier
        )
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
         1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         pathContents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let fileName = pathContents[indexPath.row]
        if isDirectory(indexPath: indexPath) {
            let filePath = (path as NSString).appendingPathComponent(fileName)
            let cell: FolderCell = tableView.dequeueReusableCell(
                withIdentifier: Constants.folderIdentifier
            ) as? FolderCell ?? FolderCell()
            cell.folderNameLabel.text = fileName
            let sizeFolder = getSizeFolder(pathFolder: filePath)
            let size = ByteCountFormatter.string(fromByteCount: sizeFolder, countStyle: .memory)
            cell.folderSizeLabel.text = size
            
            return cell
        } else {
            let folderPath = (path as NSString).appendingPathComponent(fileName)
            let cell: TableViewCell = tableView.dequeueReusableCell(
                withIdentifier: Constants.fileIdentifier
            ) as? TableViewCell ?? TableViewCell()
            cell.nameLabel.text = fileName
            let sizeFile = getSize(file: folderPath)
            let size = ByteCountFormatter.string(fromByteCount: sizeFile, countStyle: .file)
            cell.sizeLabel.text = size
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isDirectory(indexPath: indexPath) {
            let fileName = pathContents[indexPath.row]
            let path = (self.path as NSString).appendingPathComponent(fileName)
            selectedPath = path
            performSegue(withIdentifier: Constants.directory, sender: nil)
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete else { return }
        let filePath = getFilePathBy(indexPath: indexPath, mainPath: path)
            do {
                try FileManager.default.removeItem(atPath: filePath)
                pathContents = getContents(atPath: path)
            } catch let error {
                print(error.localizedDescription)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? DirectoryViewController
        vc?.path = selectedPath
    }
    
    // MARK: - IBAction, Button
    @IBAction private func filesHiddenOrOpen(_ sender: UIBarButtonItem) {
        if sender.title == UIButtonTitle.hide.rawValue {
            for fileName in pathContents {
                let filePath = (self.path as NSString).appendingPathComponent(fileName)
                guard isFileHidden(atPath: filePath) else { continue }
                    let fileIndex = pathContents.firstIndex(of: fileName) ?? 0
                    let hidenName = pathContents.remove(at: fileIndex)
                    tempFilesNames.append(hidenName)
            }
        } else {
            pathContents.append(contentsOf: tempFilesNames)
            tableView.reloadData()
            tempFilesNames.removeAll()
        }
        tableView.reloadData()
        sender.title = sender.title == UIButtonTitle.open.rawValue ? UIButtonTitle.hide.rawValue :
            UIButtonTitle.open.rawValue
    }
    
    @IBAction private func addFolder(_ sender: Any) {
        let alertController = UIAlertController(title: Constants.createFolder,
                                                message: Constants.newFolder,
                                                preferredStyle: .alert)
        let alertActionOk = UIAlertAction(title: Constants.ok, style: .default) { _ in
            let folderName = alertController.textFields?[.zero].text ?? ""
            let folderPath = (self.path as NSString).appendingPathComponent(folderName)
            guard !FileManager.default.fileExists(atPath: folderPath) else { return }
                do {
                    try FileManager.default.createDirectory(atPath: folderPath,
                                                            withIntermediateDirectories: false,
                                                            attributes: nil)
                    self.pathContents.insert(folderName, at: .zero)
                } catch let error {
                    print(error.localizedDescription)
                }
                self.tableView.insertRows(at: [IndexPath(row: .zero, section: .zero)], with: .fade)
        }
        let alertActionCancel = UIAlertAction(title: Constants.cancel, style: .cancel, handler: nil)
        alertController.addAction(alertActionOk)
        alertController.addAction(alertActionCancel)
        alertController.addTextField { (textField) in
            textField.placeholder = Constants.placeholder
        }
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction private func sorted(_ sender: Any) {
        for fileName in pathContents {
            let filePath = (self.path as NSString).appendingPathComponent(fileName)
            
            if !isDirectory(byPath: filePath) {
                filesNames.append(fileName)
            } else {
                foldersNames.append(fileName)
            }
        }
        pathContents = foldersNames + filesNames
        foldersNames.removeAll()
        filesNames.removeAll()
        tableView.reloadData()
    }
    
    // MARK: - Help func
    
    private func getSize(file: String) -> Int64 {
        let fileAttributes = getAttributesOfItem(atPath: file)
        let sizeFile = fileAttributes[FileAttributeKey.size] as? Int64
        
        return sizeFile ?? Int64.min
    }
    private func getAttributesOfItem(atPath: String) -> [FileAttributeKey: Any] {
        var attributes = [FileAttributeKey: Any]()
    
        do {
            attributes = try FileManager.default.attributesOfItem(atPath: atPath)
        } catch let error {
            print("\(error.localizedDescription)")
        }
        
        return attributes
    }
    
    private func getContents(atPath: String) -> [String] {
        var pathContents = [String]()
        do {
            pathContents = try FileManager.default.contentsOfDirectory(atPath: atPath)
        } catch let error {
            print(error.localizedDescription)
        }
        return pathContents
    }
    
    private func isDirectory(indexPath: IndexPath) -> Bool {
        var isDirectory: ObjCBool = false
        let pathComponetnt = pathContents[indexPath.row]
        let fullPath = (path as NSString).appendingPathComponent(pathComponetnt)
        FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory)
        
        return isDirectory.boolValue
    }
    
    private func isDirectory(byPath: String) -> Bool {
        var result: ObjCBool = false
        FileManager.default.fileExists(atPath: byPath, isDirectory: &result)
        
        return result.boolValue
    }
        
    private func isFileHidden(atPath: String) -> Bool {
        var isHidden = false
        var valueHidden = 0
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: atPath)
            valueHidden = attributes[FileAttributeKey.extensionHidden] as? Int ?? .zero
        } catch let error {
            print(error.localizedDescription)
        }
        guard valueHidden == 1 else { return isHidden }
            isHidden = true
        
        return isHidden
    }
    
    // MARK: - Рекурсивные функции
    private func getSizeFolder(pathFolder: String) -> Int64 {
        var sizeFolder: Int64 = 0
        let contents = getContents(atPath: pathFolder)
        for path in contents {
            let filePath = (pathFolder as NSString).appendingPathComponent(path)
            
            if !isDirectory(byPath: filePath) {
                let sizeFile = getSize(file: filePath)
                sizeFolder += sizeFile
            } else {
               sizeFolder += getSizeFolder(pathFolder: filePath)
            }
        }
        return sizeFolder
    }
    
    private func getFilePathBy(indexPath: IndexPath, mainPath: String) -> String {
        var pathContents = [String]()
        do {
            pathContents = try FileManager.default.contentsOfDirectory(atPath: mainPath)
        } catch let error {
            print(error.localizedDescription)
        }
        let fileName = pathContents[indexPath.row]
        let filePath = (mainPath as NSString).appendingPathComponent(fileName)
        
        return filePath
    }
}
