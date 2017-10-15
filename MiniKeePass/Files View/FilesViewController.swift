/*
 * Copyright 2016 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit

class FilesViewController: UITableViewController, NewDatabaseDelegate {
    private let databaseReuseIdentifier = "DatabaseCell"
    private let keyFileReuseIdentifier = "KeyFileCell"

    private enum Section : Int {
        case databases = 0
        case keyFiles = 1

        static let AllValues = [Section.databases, Section.keyFiles]
    }

    var databaseFiles: [String] = []
    var keyFiles: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.tableView.estimatedRowHeight = 30
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateFiles();
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "newDatabase"?:
            guard let navigationController = segue.destination as? UINavigationController,
                let newDatabaseViewController = navigationController.topViewController as? NewDatabaseViewController else {
                    return
            }

            newDatabaseViewController.delegate = self
        case "fileOpened"?:
            guard let groupViewController = segue.destination as? GroupViewController else {
                return
            }

            let appDelegate = AppDelegate.getDelegate()
            let document = appDelegate?.databaseDocument
            
            groupViewController.parentGroup = document?.kdbTree.root
            groupViewController.title = URL(fileURLWithPath: document!.filename).lastPathComponent
        default:
            break
        }
    }
    
    @objc func updateFiles() {
        if let databaseManager = DatabaseManager.sharedInstance() {
            databaseFiles = databaseManager.getDatabases() as! [String]
            keyFiles = databaseManager.getKeyFiles() as! [String]
        }
    }
    
    // MARK: - Empty State

    func toggleEmptyState() {
        if (databaseFiles.count == 0 && keyFiles.count == 0) {
            let emptyStateLabel = UILabel()
            emptyStateLabel.text = NSLocalizedString("Tap the + button to add a new KeePass file.", comment: "")
            emptyStateLabel.textAlignment = .center
            emptyStateLabel.textColor = UIColor.gray
            emptyStateLabel.numberOfLines = 0
            emptyStateLabel.lineBreakMode = .byWordWrapping

            tableView.backgroundView = emptyStateLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }

    // MARK: - UITableView data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.AllValues.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section.AllValues[section] {
        case .databases:
            return NSLocalizedString("Databases", comment: "")
        case .keyFiles:
            return NSLocalizedString("Key Files", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Hide the section titles if there are no files in a section
        switch Section.AllValues[section] {
        case .databases:
            if (databaseFiles.count == 0) {
                return 0
            }
        case .keyFiles:
            if (keyFiles.count == 0) {
                return 0
            }
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        toggleEmptyState()

        switch Section.AllValues[section] {
        case .databases:
            return databaseFiles.count
        case .keyFiles:
            return keyFiles.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let filename: String

        // Get the cell and filename
        switch Section.AllValues[indexPath.section] {
        case .databases:
            cell = tableView.dequeueReusableCell(withIdentifier: databaseReuseIdentifier, for: indexPath)
            filename = databaseFiles[indexPath.row]
        case .keyFiles:
            cell = tableView.dequeueReusableCell(withIdentifier: keyFileReuseIdentifier, for: indexPath)
            filename = keyFiles[indexPath.row]
        }

        cell.textLabel!.text = filename

        // Get the file's last modification time
        let databaseManager = DatabaseManager.sharedInstance()
        let url = databaseManager?.getFileUrl(filename)
        let date = databaseManager?.getFileLastModificationDate(url)

        // Format the last modified time as the subtitle of the cell
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        cell.detailTextLabel!.text = NSLocalizedString("Last Modified", comment: "") + ": " + dateFormatter.string(from: date!)

        return cell
    }

    // MARK: - UITableView delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Load the database
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager?.openDatabaseDocument(databaseFiles[indexPath.row], animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.deleteRowAtIndexPath(indexPath)
        }
        
        let renameAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Rename", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.renameRowAtIndexPath(indexPath)
        }
        
        switch Section.AllValues[indexPath.section] {
        case .databases:
            return [deleteAction, renameAction]
        case .keyFiles:
            return [deleteAction]
        }
    }
    
    func renameRowAtIndexPath(_ indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "RenameDatabase", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        
        let viewController = navigationController.topViewController as! RenameDatabaseViewController
        viewController.donePressed = { (renameDatabaseViewController: RenameDatabaseViewController, originalUrl: URL, newUrl: URL) in
            let databaseManager = DatabaseManager.sharedInstance()
            databaseManager?.renameDatabase(originalUrl, newUrl: newUrl)
            
            // Update the filename in the files list
            self.databaseFiles[indexPath.row] = newUrl.lastPathComponent
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            
            self.dismiss(animated: true, completion: nil)
        }
        
        let databaseManager = DatabaseManager.sharedInstance()
        viewController.originalUrl = databaseManager?.getFileUrl(databaseFiles[indexPath.row])
        
        present(navigationController, animated: true, completion: nil)
    }
    
    func deleteRowAtIndexPath(_ indexPath: IndexPath) {
        // Get the filename to delete
        let filename: String
        switch Section.AllValues[indexPath.section] {
        case .databases:
            filename = databaseFiles.remove(at: indexPath.row)
        case .keyFiles:
            filename = keyFiles.remove(at: indexPath.row)
        }
        
        // Delete the file
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager?.deleteFile(filename)
        
        // Update the table
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    func newDatabaseCreated(filename: String) {
        let index = self.databaseFiles.insertionIndexOf(filename) {
            $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
        }
        self.databaseFiles.insert(filename, at: index)
        
        // Notify the table of the new row
        if (self.databaseFiles.count == 1) {
            // Reload the section if it was previously empty
            let indexSet = IndexSet(integer: Section.databases.rawValue)
            self.tableView.reloadSections(indexSet, with: .right)
        } else {
            let indexPath = IndexPath(row: index, section: Section.databases.rawValue)
            self.tableView.insertRows(at: [indexPath], with: .right)
        }
    }
}
