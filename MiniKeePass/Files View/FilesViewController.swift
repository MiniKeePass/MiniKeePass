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

class FilesViewController: UITableViewController {
    private let databaseReuseIdentifier = "DatabaseCell"
    private let keyFileReuseIdentifier = "KeyFileCell"

    private enum Section : Int {
        case Databases = 0
        case KeyFiles = 1

        static let AllValues = [Section.Databases, Section.KeyFiles]
    }

    var databaseFiles: [String] = []
    var keyFiles: [String] = []
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let databaseManager = DatabaseManager.sharedInstance()
        databaseFiles = databaseManager.getDatabases() as! [String]
        keyFiles = databaseManager.getKeyFiles() as! [String]
        
        tableView.reloadData()
    }

    // MARK: - Empty State

    func toggleEmptyState() {
        if (databaseFiles.count == 0 && keyFiles.count == 0) {
            let emptyStateLabel = UILabel()
            emptyStateLabel.text = NSLocalizedString("Tap the + button to add a new KeePass file.", comment: "")
            emptyStateLabel.textAlignment = .Center
            emptyStateLabel.textColor = UIColor.grayColor()
            emptyStateLabel.numberOfLines = 0
            emptyStateLabel.lineBreakMode = .ByWordWrapping

            tableView.backgroundView = emptyStateLabel
            tableView.separatorStyle = .None
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
        }
    }

    // MARK: - UITableView data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.AllValues.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section.AllValues[section] {
        case .Databases:
            return NSLocalizedString("Databases", comment: "")
        case .KeyFiles:
            return NSLocalizedString("Key Files", comment: "")
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Hide the section titles if there are no files in a section
        switch Section.AllValues[section] {
        case .Databases:
            if (databaseFiles.count == 0) {
                return 0
            }
        case .KeyFiles:
            if (keyFiles.count == 0) {
                return 0
            }
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        toggleEmptyState()

        switch Section.AllValues[section] {
        case .Databases:
            return databaseFiles.count
        case .KeyFiles:
            return keyFiles.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let filename: String

        // Get the cell and filename
        switch Section.AllValues[indexPath.section] {
        case .Databases:
            cell = tableView.dequeueReusableCellWithIdentifier(databaseReuseIdentifier, forIndexPath: indexPath)
            filename = databaseFiles[indexPath.row]
        case .KeyFiles:
            cell = tableView.dequeueReusableCellWithIdentifier(keyFileReuseIdentifier, forIndexPath: indexPath)
            filename = keyFiles[indexPath.row]
        }

        cell.textLabel!.text = filename

        // Get the file's last modification time
        let databaseManager = DatabaseManager.sharedInstance()
        let url = databaseManager.getFileUrl(filename)
        let date = databaseManager.getFileLastModificationDate(url)

        // Format the last modified time as the subtitle of the cell
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        cell.detailTextLabel!.text = NSLocalizedString("Last Modified", comment: "") + ": " + dateFormatter.stringFromDate(date)

        return cell
    }

    // MARK: - UITableView delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Load the database
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager.openDatabaseDocument(databaseFiles[indexPath.row], animated: true)
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .Destructive, title: NSLocalizedString("Delete", comment: "")) { (action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
            self.deleteRowAtIndexPath(indexPath)
        }
        
        let renameAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("Rename", comment: "")) { (action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
            self.renameRowAtIndexPath(indexPath)
        }
        
        switch Section.AllValues[indexPath.section] {
        case .Databases:
            return [deleteAction, renameAction]
        case .KeyFiles:
            return [deleteAction]
        }
    }
    
    func renameRowAtIndexPath(indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "RenameDatabase", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        
        let viewController = navigationController.topViewController as! RenameDatabaseViewController
        viewController.donePressed = { (renameDatabaseViewController: RenameDatabaseViewController, originalUrl: NSURL, newUrl: NSURL) in
            let databaseManager = DatabaseManager.sharedInstance()
            databaseManager.renameDatabase(originalUrl, newUrl: newUrl)
            
            // Update the filename in the files list
            self.databaseFiles[indexPath.row] = newUrl.lastPathComponent!
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let databaseManager = DatabaseManager.sharedInstance()
        viewController.originalUrl = databaseManager.getFileUrl(databaseFiles[indexPath.row])
        
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func deleteRowAtIndexPath(indexPath: NSIndexPath) {
        // Get the filename to delete
        let filename: String
        switch Section.AllValues[indexPath.section] {
        case .Databases:
            filename = databaseFiles.removeAtIndex(indexPath.row)
        case .KeyFiles:
            filename = keyFiles.removeAtIndex(indexPath.row)
        }
        
        // Delete the file
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager.deleteFile(filename)
        
        // Update the table
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }

    // MARK: - Actions

    @IBAction func settingsPressed(sender: UIBarButtonItem?) {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController()!

        presentViewController(viewController, animated: true, completion: nil)
    }

    @IBAction func helpPressed(sender: UIBarButtonItem?) {
        let storyboard = UIStoryboard(name: "Help", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController()!

        presentViewController(viewController, animated: true, completion: nil)
    }

    @IBAction func addPressed(sender: UIBarButtonItem?) {
        let storyboard = UIStoryboard(name: "NewDatabase", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

        let viewController = navigationController.topViewController as! NewDatabaseViewController
        viewController.donePressed = { (newDatabaseViewController: NewDatabaseViewController, url: NSURL, password: String, version: Int) -> Void in
            // Create the new database
            let databaseManager = DatabaseManager.sharedInstance()
            databaseManager.newDatabase(url, password: password, version: version)
            
            // Add the file to the list of files
            let filename = url.lastPathComponent!
            let index = self.databaseFiles.insertionIndexOf(filename) {
                $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending
            }
            self.databaseFiles.insert(filename, atIndex: index)
            
            // Notify the table of the new row
            if (self.databaseFiles.count == 1) {
                // Reload the section if it was previously empty
                let indexSet = NSIndexSet(index: Section.Databases.rawValue)
                self.tableView.reloadSections(indexSet, withRowAnimation: .Right)
            } else {
                let indexPath = NSIndexPath(forRow: index, inSection: Section.Databases.rawValue)
                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            }

            newDatabaseViewController.dismissViewControllerAnimated(true, completion: nil)
        }

        presentViewController(navigationController, animated: true, completion: nil)
    }
}
