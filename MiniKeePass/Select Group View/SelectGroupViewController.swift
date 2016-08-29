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

class SelectGroupViewController: UITableViewController {
    private let SelectableReuseIdentifier = "SelectableGroupCell"
    private let UnselectableReuseIdentifier = "UnselectableGroupCell"
    private let IndentWidth = 10

    var groupModels: [GroupModel] = []

    var isSelectable: ((group: KdbGroup) -> Bool)?
    var groupSelected: ((selectGroupViewController: SelectGroupViewController, group: KdbGroup) -> Void)?

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

    func addGroup(group: KdbGroup, name: String, indent: Int) {
        // Check if this group is selectable
        let selectable = isSelectable?(group: group) ?? true

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
        if (groupModel.selectable) {
            groupSelected?(selectGroupViewController: self, group: groupModel.group)

            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
