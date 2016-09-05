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

struct GroupModel {
    var group: KdbGroup
    var name: String
    var indent: Int
    var selectable: Bool
}

class MoveItemsViewController: UITableViewController {
    private let SelectableReuseIdentifier = "SelectableGroupCell"
    private let UnselectableReuseIdentifier = "UnselectableGroupCell"
    private let IndentWidth = 10

    private var groupModels: [GroupModel] = []

    var itemsToMove: [AnyObject] = []
    var groupSelected: ((moveItemsViewController: MoveItemsViewController, group: KdbGroup) -> Void)?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        groupModels = []

        // Get parameters for the root
        let appDelegate = MiniKeePassAppDelegate.getDelegate()

        let rootGroup = appDelegate.databaseDocument.kdbTree.root
        let filename = appDelegate.databaseDocument.filename as NSString

        // Recursivly add subgroups
        addGroup(rootGroup, name: filename.lastPathComponent, indent: 0)
    }

    func isSelectable(group: KdbGroup) -> Bool {
        var containsEntry = false

        // Check if group is a subgroup of any groups to be moved
        for obj in itemsToMove {
            if (obj is KdbGroup) {
                let movingGroup = obj as! KdbGroup

                if (movingGroup.parent == group || movingGroup.containsGroup(group)) {
                    return false
                }
            } else if (obj is KdbEntry) {
                containsEntry = true

                let movingEntry = obj as! KdbEntry
                if (movingEntry.parent == group) {
                    return false
                }
            }
        }

        // Check if trying to move entries to top level in 1.x database
        let appDelegate = MiniKeePassAppDelegate.getDelegate()
        let tree = appDelegate.databaseDocument.kdbTree
        if (containsEntry && group == tree.root && tree is Kdb3Tree) {
            return false
        }

        return true
    }

    func addGroup(group: KdbGroup, name: String, indent: Int) {
        // Check if this group is selectable
        let selectable = isSelectable(group)

        // Add the group model
        groupModels.append(GroupModel(group: group, name:name, indent: indent, selectable: selectable))

        // Sort all the sub-groups
        let subGroups = group.groups.sort {
            $0.name.localizedCaseInsensitiveCompare($1.name) == NSComparisonResult.OrderedAscending
        } as! [KdbGroup]

        // Add sub-groups
        for subGroup in subGroups {
            addGroup(subGroup, name: subGroup.name, indent: indent + 1)
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupModels.count;
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let groupModel = groupModels[indexPath.row]

        let cell = tableView.dequeueReusableCellWithIdentifier(groupModel.selectable ? SelectableReuseIdentifier : UnselectableReuseIdentifier, forIndexPath: indexPath) as! GroupCell
        cell.groupTitleLabel.text = groupModel.name
        let imageFactory = ImageFactory.sharedInstance()
        cell.groupImageView.image = imageFactory.imageForGroup(groupModel.group)
        cell.leadingContraint.constant = CGFloat(groupModel.indent * IndentWidth)

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let groupModel = groupModels[indexPath.row]
        if (!groupModel.selectable) {
            return
        }

        let selectedGroup = groupModel.group

        // Move all the items
        for obj in itemsToMove {
            if (obj is KdbGroup) {
                let movingGroup = obj as! KdbGroup
                movingGroup.parent.moveGroup(movingGroup, toGroup:selectedGroup)
            } else if (obj is KdbEntry) {
                let movingEntry = obj as! KdbEntry
                movingEntry.parent.moveEntry(movingEntry, toGroup:selectedGroup)
            }
        }

        // Save the database
        let appDelegate = MiniKeePassAppDelegate.getDelegate()
        let databaseDocument = appDelegate.databaseDocument
        databaseDocument.save()

        groupSelected?(moveItemsViewController: self, group: groupModel.group)

        dismissViewControllerAnimated(true, completion: nil)
    }
}
