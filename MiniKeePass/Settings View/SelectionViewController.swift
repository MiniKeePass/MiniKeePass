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

class SelectionViewController: UITableViewController {
    var items = [String]()
    var selectedIndex = -1
    
    var itemSelected: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Configure the cell
        cell.textLabel!.text = items[indexPath.row]
        
        if (indexPath.row == selectedIndex) {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none;
        }

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row != selectedIndex) {
            // Remove the checkmark from the current selection
            if (selectedIndex != -1) {
                let cell = tableView.cellForRow(at: IndexPath(row: selectedIndex, section: 0))!
                cell.accessoryType = UITableViewCellAccessoryType.none;
            }
            
            // Add the checkmark to the new selection
            let cell = tableView.cellForRow(at: indexPath)!
            cell.accessoryType = UITableViewCellAccessoryType.checkmark;
            
            selectedIndex = indexPath.row;
            
            // Notify the change
            itemSelected?(selectedIndex)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
