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

class KeyFileViewController: UITableViewController {
    var keyFiles: [String]!
    var selectedKeyIndex: Int?

    var keyFileSelected: ((_ selectedIndex: Int?) -> Void)?

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Number of key files plus one for the "None" entry
        return keyFiles.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KeyFileCell", for: indexPath)
        if (indexPath.row == 0) {
            cell.textLabel?.text = NSLocalizedString("None", comment: "")
            cell.accessoryType = (selectedKeyIndex == nil ? .checkmark : .none)
        } else {
            let keyIndex = indexPath.row - 1
            cell.textLabel?.text = keyFiles[keyIndex]
            cell.accessoryType = (keyIndex == selectedKeyIndex ? .checkmark : .none)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let keyIndex = indexPath.row > 0 ? indexPath.row - 1 : nil
        let oldIndexPath = IndexPath(row: (selectedKeyIndex ?? -1) + 1, section: 0)

        if (indexPath != oldIndexPath) {
            let oldCell = tableView.cellForRow(at: oldIndexPath)
            oldCell!.accessoryType = .none
            
            let cell = tableView.cellForRow(at: indexPath)
            cell!.accessoryType = .checkmark
            
            selectedKeyIndex = keyIndex
            
            keyFileSelected?(selectedKeyIndex)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
