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
        
        func title() -> String {
            switch self {
            case .Databases:
                return NSLocalizedString("Databases", comment: "")
            case .KeyFiles:
                return NSLocalizedString("Key Files", comment: "")
            }
        }
    }
    
    var databaseFiles: [String] = []
    var keyFiles: [String] = []
    
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
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        toggleEmptyState()
        
        switch Section.AllValues[section] {
        case .Databases:
            return databaseFiles.count
        case .KeyFiles:
            return keyFiles.count
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.AllValues[section].title()
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

        return super.tableView(tableView, heightForHeaderInSection: section)
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
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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
            self.createNewDatabase(url, password: password, version: version)
            newDatabaseViewController.dismissViewControllerAnimated(true, completion: nil)
        }
        
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func createNewDatabase(url: NSURL, password: String, version: Int) -> Void {
        let filename = url.lastPathComponent!
        
        // Create the KdbWriter for the requested version
        let kdbWritter: KdbWriter
        if (version == 1) {
            kdbWritter = Kdb3Writer()
        } else {
            kdbWritter = Kdb4Writer()
        }
        
        // Create the KdbPassword
        let kdbPassword = KdbPassword(password: password, passwordEncoding: NSUTF8StringEncoding, keyFile: nil)

        // Create the new database
        kdbWritter.newFile(url.path, withPassword: kdbPassword)

        // Store the password in the keychain if enabled
        let appSettings = AppSettings.sharedInstance()
        if (appSettings.rememberPasswordsEnabled()) {
            KeychainUtils.setString(password, forKey: filename, andServiceName: KEYCHAIN_PASSWORDS_SERVICE)
        }
        
        // Add the file to the list of files
        let index = databaseFiles.insertionIndexOf(filename) {
            $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending
        }
        databaseFiles.insert(filename, atIndex: index)
        
        // Notify the table of the new row
        if (databaseFiles.count == 1) {
            // Reload the section if it was previously empty
            let indexSet = NSIndexSet(index: Section.Databases.rawValue)
            tableView.reloadSections(indexSet, withRowAnimation: .Right)
        } else {
            let indexPath = NSIndexPath(forRow: index, inSection: Section.Databases.rawValue)
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
        }
    }
}
