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

class GroupViewController: UITableViewController, UISearchResultsUpdating {
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

    private enum KdbItem {
        case group(KdbGroup)
        case entry(KdbEntry)
    }
    
    private var selectedItem: KdbItem?
    
    private var searchController: UISearchController?
    private var searchResults: [KdbEntry] = []

    var parentGroup: KdbGroup! {
        didSet {
            updateViewModel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the edit button
        navigationItem.rightBarButtonItems = [self.editButtonItem]
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

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
        
        // Search controller
        definesPresentationContext = true // Ensure searchBar stays with tableView
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.hidesNavigationBarDuringPresentation = false
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            searchController?.searchBar.sizeToFit()
            tableView.tableHeaderView = searchController?.searchBar
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        // Ensure cell reflects name change and proper cell is highlighted
        if selectedItem != nil {
            updateViewModel()
            tableView.reloadData()

            var section: Int?
            var row: Int?
            
            switch selectedItem! {
            case .entry(let entry):
                section = Section.entries.rawValue
                row = entries.index(of: entry)
            case .group(let group):
                section = Section.groups.rawValue
                row = groups.index(of: group)
            }
            selectedItem = nil
            
            if let section = section, let row = row {
                tableView.selectRow(at: IndexPath(row: row, section: section), animated: false, scrollPosition: .middle)
            }
        }
        
        self.setEditing(false, animated: false)
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        documentInteractionController?.dismissMenu(animated: false)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !isEditing
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = self.tableView.indexPathForSelectedRow else {
            return
        }
        
        if let destination = segue.destination as? GroupViewController {
            let group = groups[indexPath.row]
            selectedItem = KdbItem.group(group)
            destination.parentGroup = group
            destination.title = group.name
        }
        else if let destination = segue.destination as? EntryViewController {
            let entry = entries[indexPath.row]
            selectedItem = KdbItem.entry(entry)
            destination.entry = entry
            destination.title = entry.title()
        }
    }
    
    func updateViewModel() {
        if searchController != nil && searchController!.isActive {
            groups = []
            entries = searchResults
        } else {
            groups = parentGroup.groups as! [KdbGroup]
            entries = parentGroup.entries as! [KdbEntry]
        }

        if let appSettings = AppSettings.sharedInstance(), appSettings.sortAlphabetically() {
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

        // Enable/Disable the search bar
        searchController?.searchBar.isUserInteractionEnabled = !editing
    }

    private func updateEditingToolbar() {
        if (tableView.isEditing) {
            let numSelectedRows = tableView.indexPathsForSelectedRows?.count ?? 0

            editingToolbarItems[EditButton.Delete.rawValue].isEnabled = numSelectedRows > 0
            editingToolbarItems[EditButton.Move.rawValue].isEnabled = numSelectedRows > 0
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

            cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell")!
            cell.textLabel?.text = group.name
            cell.imageView?.image = imageFactory?.image(for: group)

        case .entries:
            let entry = entries[indexPath.row]

            cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell")!
            cell.textLabel?.text = entry.title()
            cell.imageView?.image = imageFactory?.image(for: entry)

            // Detail text is a combination of username and url
            var accountDescription = ""
            var usernameSet = false
            if let username = entry.username(), !(username.isEmpty) {
                usernameSet = true
                accountDescription += username
            }
            
            if let url = entry.url(), !(url.isEmpty) {
                if usernameSet {
                    accountDescription += " @ "
                }
                accountDescription += url
            }
            
            cell.detailTextLabel?.text = accountDescription
        }

        return cell
    }

    // MARK: - UITableView delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (isEditing) {
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

        let appDelegate = AppDelegate.getDelegate()
        
        // Remove the groups
        for group in groupsToDelete {
            groups.removeObject(group)
            appDelegate?.databaseDocument.kdbTree.remove(group)
        }

        // Remove the entries
        for entry in entriesToDelete {
            entries.removeObject(entry)
            appDelegate?.databaseDocument.kdbTree.remove(entry)
        }

        // Save the database
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

    @objc func settingsPressed(sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() else {
            return
        }

        present(viewController, animated: true, completion: nil)
    }

    @objc func actionPressed(sender: UIBarButtonItem) {
        // Get the URL of the database
        guard let appDelegate = AppDelegate.getDelegate() else {
            return
        }
        let url = URL(fileURLWithPath: appDelegate.databaseDocument.filename)

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

    @objc func addPressed(sender: UIBarButtonItem) {
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
        let appDelegate = AppDelegate.getDelegate()
        let databaseDocument = appDelegate?.databaseDocument

        // Create and add a group
        guard let group = databaseDocument?.kdbTree.createGroup(parentGroup) else {
            // Could not greate new group
            // TODO: Display an error?
            return
        }
        
        group.name = NSLocalizedString("New Group", comment: "")
        group.image = parentGroup.image

        // Display the Rename Item view
        let storyboard = UIStoryboard(name: "RenameItem", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

        let viewController = navigationController.topViewController as! RenameItemViewController
        viewController.donePressed = { (renameItemViewController: RenameItemViewController) in
            self.parentGroup.addGroup(group)

            // Save the database
            databaseDocument?.save()

            // Add the group to the model
            let index = self.groups.insertionIndexOf(group) {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            self.groups.insert(group, at: index)

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
        let appDelegate = AppDelegate.getDelegate()
        let databaseDocument = appDelegate?.databaseDocument

        // Create and add a entry
        guard let entry = databaseDocument?.kdbTree.createEntry(parentGroup) else {
            // Could not create new entry
            // TODO: Display error?
            return
        }
        
        entry.setTitle(NSLocalizedString("New Entry", comment: ""))
        entry.image = parentGroup.image
        parentGroup.addEntry(entry)

        // Save the database
        databaseDocument?.save()

        // Add the entry to the model
        let index = self.entries.insertionIndexOf(entry) {
            $0.title().localizedCaseInsensitiveCompare($1.title()) == .orderedAscending
        }
        self.entries.insert(entry, at: index)

        // Update the table
        let indexPath = IndexPath(row: index, section: Section.entries.rawValue)
        if (self.entries.count == 1) {
            self.tableView.reloadSections(NSIndexSet(index: Section.entries.rawValue) as IndexSet, with: .automatic)
        } else {
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
        
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        selectedItem = KdbItem.entry(entry)

        // Show the Entry view controller
        let viewController = EntryViewController(style: .grouped)
        viewController.entry = entry
        viewController.title = entry.title()
        viewController.isNewEntry = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func deletePressed(sender: UIBarButtonItem) {
        if let indexPaths = tableView.indexPathsForSelectedRows {
            deleteItems(indexPaths: indexPaths)
        }
    }

    @objc func movePressed(sender: UIBarButtonItem) {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            // Nothing selected. Shouldn't have been possible to press "Move"
            return;
        }

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
                if let group = obj as? KdbGroup {
                    self.groups.removeObject(group)
                } else if let entry = obj as? KdbEntry {
                    self.entries.removeObject(entry)
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

    @objc func renamePressed(sender: UIBarButtonItem) {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            // Nothing selected. This shoudn't have been called
            return
        }

        // Load the RenameItem storyboard
        let storyboard = UIStoryboard(name: "RenameItem", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

        let viewController = navigationController.topViewController as! RenameItemViewController

        // Set the group/entry to rename
        switch Section.AllValues[indexPath.section] {
        case .groups:
            let group = groups[indexPath.row]
            viewController.group = group
            selectedItem = KdbItem.group(group)
        case .entries:
            let entry = entries[indexPath.row]
            viewController.entry = entry
            selectedItem = KdbItem.entry(entry)
        }

        present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        // Set state of UI buttons
        let buttonsActive = !searchController.isActive
        editButtonItem.isEnabled = buttonsActive
        if let toolbarItems = toolbarItems {
            for toolbarItem in toolbarItems {
                toolbarItem.isEnabled = buttonsActive
            }
        }
        
        // Find results
        let results = NSMutableArray()
        DatabaseDocument.search(parentGroup, searchText: searchController.searchBar.text, results: results)
        searchResults = results as! [KdbEntry]
        searchResults.sort {
            $0.title().localizedCaseInsensitiveCompare($1.title()) == .orderedAscending
        }
        
        // Update table
        updateViewModel()
        tableView.reloadData()
    }
}
