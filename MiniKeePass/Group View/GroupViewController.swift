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

class GroupViewController: UITableViewController {
    private enum Section : Int {
        case groups = 0
        case entries = 1

        static let AllValues = [Section.groups, Section.entries]
    }

    enum StandardButton : Int {
        case Settings = 0
        case Action = 2
        case Add = 4
    }

    enum EditButton : Int {
        case Delete = 0
        case Move = 2
        case Rename = 4
    }

    private var standardToolbarItems: [UIBarButtonItem]!
    private var editingToolbarItems: [UIBarButtonItem]!

    private var documentInteractionController: UIDocumentInteractionController?

    private var groups: [KdbGroup]!
    private var entries: [KdbEntry]!

    var parentGroup: KdbGroup! {
        didSet {
            updateViewModel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsMultipleSelectionDuringEditing = true

        // Add the edit button
        navigationItem.rightBarButtonItems = [self.editButtonItem]

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        // Create the standard toolbar
        let settingsButton = UIBarButtonItem(image: UIImage(named: "gear"), style: .plain, target: self, action: #selector(settingsPressed))
        let actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionPressed))
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPressed))
        standardToolbarItems = [settingsButton, spacer, actionButton, spacer, addButton]

        // Create the editing toolbar
        let deleteButton = UIBarButtonItem(title: NSLocalizedString("Delete", comment: ""), style: .plain, target: self, action: #selector(deletePressed))
        let moveButton = UIBarButtonItem(title: NSLocalizedString("Move", comment: ""), style: .plain, target: self, action: #selector(movePressed))
        let renameButton = UIBarButtonItem(title: NSLocalizedString("Rename", comment: ""), style: .plain, target: self, action: #selector(renamePressed))
        editingToolbarItems = [deleteButton, spacer, moveButton, spacer, renameButton]

        toolbarItems = standardToolbarItems
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        documentInteractionController?.dismissMenu(animated: false)
    }

    func updateViewModel() {
        groups = parentGroup.groups as! [KdbGroup]
        entries = parentGroup.entries as! [KdbEntry]

        let appSettings = AppSettings.sharedInstance()
        if (appSettings?.sortAlphabetically())! {
            groups.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            entries.sort {
                $0.title().localizedCaseInsensitiveCompare($1.title()) == .orderedAscending
            }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        // Show/hide the back button
        navigationItem.setHidesBackButton(editing, animated: true)

        // Update the toolbar
        toolbarItems = editing ? editingToolbarItems : standardToolbarItems
        updateEditingToolbar()

        // FIXME Enable/Disable the search bar
    }

    private func updateEditingToolbar() {
        if (tableView.isEditing) {
            let numSelectedRows = tableView.indexPathsForSelectedRows?.count

            editingToolbarItems[EditButton.Delete.rawValue].isEnabled = numSelectedRows! > 0
            editingToolbarItems[EditButton.Move.rawValue].isEnabled = numSelectedRows! > 0
            editingToolbarItems[EditButton.Rename.rawValue].isEnabled = numSelectedRows == 1
        }
    }

    // MARK: - UITableView data source

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section.AllValues[section] {
        case .groups:
            return NSLocalizedString("Groups", comment: "")
        case .entries:
            return NSLocalizedString("Entries", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Hide the section titles if there are no files in a section
        switch Section.AllValues[section] {
        case .groups:
            if (groups.count == 0) {
                return 0
            }
        case .entries:
            if (entries.count == 0) {
                return 0
            }
        }

        return UITableViewAutomaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.AllValues.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.AllValues[section] {
        case .groups:
            return groups.count
        case .entries:
            return entries.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let imageFactory = ImageFactory.sharedInstance()

        var cell: UITableViewCell
        switch Section.AllValues[indexPath.section] {
        case .groups:
            let group = groups[indexPath.row]

            cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell") ?? UITableViewCell(style: .default, reuseIdentifier: "GroupCell")
            cell.textLabel?.text = group.name
            cell.imageView?.image = imageFactory?.image(for: group)
        case .entries:
            let entry = entries[indexPath.row]

            cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell") ?? UITableViewCell(style: .default, reuseIdentifier: "EntryCell")
            cell.textLabel?.text = entry.title()
            cell.imageView?.image = imageFactory?.image(for: entry)

            // Detail text is a combination of username and url
            let username = entry.username()
            let url = entry.url()
            
            if (username != nil && !(username!.isEmpty) && url != nil && !(url!.isEmpty)) {
                cell.detailTextLabel?.text = "\(username ?? "username") @ \(url ?? "")"
            } else if (username != nil && !(username!.isEmpty)) {
                cell.detailTextLabel?.text = username
            } else if (url != nil && !(url!.isEmpty)) {
                cell.detailTextLabel?.text = url
            } else {
                cell.detailTextLabel?.text = ""
            }
        }

        return cell
    }

    // MARK: - UITableView delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (!isEditing) {
            switch Section.AllValues[indexPath.section] {
            case .groups:
                let group = groups[indexPath.row]
                let groupViewController = GroupViewController(style: .plain)
                groupViewController.parentGroup = group
                groupViewController.title = group.name
                navigationController?.pushViewController(groupViewController, animated: true)

            case .entries:
                let entry = entries[indexPath.row]
                let entryViewController = EntryViewController(style: .grouped)
                entryViewController.entry = entry;
                entryViewController.title = entry.title()
                navigationController?.pushViewController(entryViewController, animated: true)
            }
        } else {
            updateEditingToolbar()
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if (isEditing) {
            updateEditingToolbar()
        }
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.deleteItems(indexPaths: [indexPath])
        }

        return [deleteAction]
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle != .delete) {
            return
        }

        deleteItems(indexPaths: [indexPath])
    }

    func deleteItems(indexPaths: [IndexPath]) -> Void {
        // Create a list of everything to delete
        var groupsToDelete: [KdbGroup] = []
        var entriesToDelete: [KdbEntry] = []
        for indexPath in indexPaths {
            switch Section.AllValues[indexPath.section] {
            case .groups:
                groupsToDelete.append(groups[indexPath.row])
            case .entries:
                entriesToDelete.append(entries[indexPath.row])
            }
        }

        // Remove the groups
        for group in groupsToDelete {
            groups.removeObject(group)
            parentGroup.removeGroup(group)
        }

        // Remove the entries
        for entry in entriesToDelete {
            entries.removeObject(entry)
            parentGroup.removeEntry(entry)
        }

        // Save the database
        let appDelegate = MiniKeePassAppDelegate.getDelegate()
        appDelegate?.databaseDocument.save()

        // Update the table
        tableView.deleteRows(at: indexPaths as [IndexPath], with: .automatic)
        let indexSet = NSMutableIndexSet()
        if (groups.isEmpty) {
            indexSet.add(Section.groups.rawValue)
        }
        if (entries.isEmpty) {
            indexSet.add(Section.entries.rawValue)
        }
        tableView.reloadSections(indexSet as IndexSet, with: .automatic)
    }

    // MARK: - Actions

    func settingsPressed(sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController()!

        present(viewController, animated: true, completion: nil)
    }

    func actionPressed(sender: UIBarButtonItem) {
        // Get the URL of the database
        let appDelegate = MiniKeePassAppDelegate.getDelegate()
        let url = URL(fileURLWithPath: (appDelegate?.databaseDocument.filename)!)

        // Present the options to handle the database
        documentInteractionController = UIDocumentInteractionController(url: url)
        let success = documentInteractionController!.presentOpenInMenu(from: standardToolbarItems[StandardButton.Action.rawValue], animated: true)
        if (!success) {
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("There are no applications installed capable of importing KeePass files", comment: ""), preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }
    }

    func addPressed(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: NSLocalizedString("Add", comment: ""), message: nil, preferredStyle: .alert)

        // Add an action to add a new group
        let groupAction = UIAlertAction(title: NSLocalizedString("Group", comment: ""), style: .default, handler: { (alertAction: UIAlertAction) in
            self.addNewGroup()
        })
        alertController.addAction(groupAction)

        // Only add an action to add a new entry if the parent group supports entries
        if (parentGroup.canAddEntries) {
            let entryAction = UIAlertAction(title: NSLocalizedString("Entry", comment: ""), style: .default, handler: { (alertAction: UIAlertAction) in
                self.addNewEntry()
            })
            alertController.addAction(entryAction)
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func addNewGroup() {
        let appDelegate = MiniKeePassAppDelegate.getDelegate()
        let databaseDocument = appDelegate?.databaseDocument

        // Create and add a group
        let group = databaseDocument?.kdbTree.createGroup(parentGroup)
        group?.name = NSLocalizedString("New Group", comment: "")
        group?.image = parentGroup.image

        // Display the Rename Item view
        let storyboard = UIStoryboard(name: "RenameItem", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

        let viewController = navigationController.topViewController as! RenameItemViewController
        viewController.donePressed = { (renameItemViewController: RenameItemViewController) in
            self.parentGroup.addGroup(group)

            // Save the database
            databaseDocument?.save()

            // Add the group to the model
            let index = self.groups.insertionIndexOf(group!) {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            self.groups.insert(group!, at: index)

            // Update the table
            if (self.groups.count == 1) {
                self.tableView.reloadSections(NSIndexSet(index: Section.groups.rawValue) as IndexSet, with: .automatic)
            } else {
                let indexPath = IndexPath(row: index, section: Section.groups.rawValue)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        };

        viewController.group = group

        self.present(navigationController, animated: true, completion: nil)
    }
    
    func addNewEntry() {
        let appDelegate = MiniKeePassAppDelegate.getDelegate()
        let databaseDocument = appDelegate?.databaseDocument

        // Create and add a entry
        let entry = databaseDocument?.kdbTree.createEntry(parentGroup)
        entry?.setTitle(NSLocalizedString("New Entry", comment: ""))
        entry?.image = parentGroup.image
        parentGroup.addEntry(entry)

        // Save the database
        databaseDocument?.save()

        // Add the entry to the model
        let index = self.entries.insertionIndexOf(entry!) {
            $0.title().localizedCaseInsensitiveCompare($1.title()) == .orderedAscending
        }
        self.entries.insert(entry!, at: index)

        // Update the table
        if (self.entries.count == 1) {
            self.tableView.reloadSections(NSIndexSet(index: Section.entries.rawValue) as IndexSet, with: .automatic)
        } else {
            let indexPath = IndexPath(row: index, section: Section.entries.rawValue)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }

        // Show the Entry view controller
        let viewController = EntryViewController(style: .grouped)
        viewController.entry = entry
        viewController.title = entry?.title()
        viewController.isNewEntry = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func deletePressed(sender: UIBarButtonItem) {
        deleteItems(indexPaths: tableView.indexPathsForSelectedRows!)
    }

    func movePressed(sender: UIBarButtonItem) {
        let indexPaths = tableView.indexPathsForSelectedRows!

        // Create a list of all the items to move
        var itemsToMove: [AnyObject] = []
        for indexPath in indexPaths {
            switch Section.AllValues[indexPath.section] {
            case .groups:
                itemsToMove.append(groups[indexPath.row])
            case .entries:
                itemsToMove.append(entries[indexPath.row])
            }
        }

        // Load the MoveItems storyboard
        let storyboard = UIStoryboard(name: "MoveItems", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

        let viewController = navigationController.topViewController as! MoveItemsViewController
        viewController.itemsToMove = itemsToMove;
        viewController.groupSelected = { (moveItemsViewController: MoveItemsViewController, selectedGroup: KdbGroup) -> Void in
            // Delete the items from the model
            for obj in itemsToMove {
                if (obj is KdbGroup) {
                    self.groups.removeObject(obj as! KdbGroup)
                } else if (obj is KdbEntry) {
                    self.entries.removeObject(obj as! KdbEntry)
                }
            }

            // Update the table
            self.tableView.deleteRows(at: indexPaths, with: .automatic)
            let indexSet = NSMutableIndexSet()
            if (self.groups.isEmpty) {
                indexSet.add(Section.groups.rawValue)
            }
            if (self.entries.isEmpty) {
                indexSet.add(Section.entries.rawValue)
            }
            self.tableView.reloadSections(indexSet as IndexSet, with: .automatic)

            self.setEditing(false, animated: true)
        }

        present(navigationController, animated: true, completion: nil)
    }

    func renamePressed(sender: UIBarButtonItem) {
        let indexPath = tableView.indexPathForSelectedRow!

        // Load the RenameItem storyboard
        let storyboard = UIStoryboard(name: "RenameItem", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

        let viewController = navigationController.topViewController as! RenameItemViewController
        viewController.donePressed = { (renameItemViewController: RenameItemViewController) -> Void in
            // Update the table
            self.tableView.reloadRows(at: [indexPath], with: .automatic)

            self.setEditing(false, animated: true)
        }
        viewController.cancelPressed = { (renameItemViewController: RenameItemViewController) -> Void in
            self.setEditing(false, animated: true)
        }

        // Set the group/entry to rename
        switch Section.AllValues[indexPath.section] {
        case .groups:
            viewController.group = groups[indexPath.row]
        case .entries:
            viewController.entry = entries[indexPath.row]
        }

        present(navigationController, animated: true, completion: nil)
    }
}
