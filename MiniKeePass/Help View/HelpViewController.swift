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

struct HelpTopic {
    var title: String
    var resource: String
}

class HelpViewController: UITableViewController {
    fileprivate let reuseIdentifier = "HelpCell"

    fileprivate let helpTopics = [
        HelpTopic(title: "iTunes Import/Export", resource: "itunes"),
        HelpTopic(title: "Dropbox Import/Export", resource: "dropbox"),
        HelpTopic(title: "Safari/Email Import", resource: "safariemail"),
        HelpTopic(title: "Create New Database", resource: "createdb"),
        HelpTopic(title: "Key Files", resource: "keyfiles")
    ]
    
    // MARK: - UITableView data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return helpTopics.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        let helpTopic = helpTopics[indexPath.row]
        cell.textLabel!.text = NSLocalizedString(helpTopic.title, comment: "")

        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let indexPath = tableView.indexPathForSelectedRow
        let helpTopic = helpTopics[indexPath!.row]
        
        let language = Locale.preferredLanguages[0]
        let localizedResource = String(format: "%@-%@", language, helpTopic.resource)

        // Get the URL of the respurce
        let bundle = Bundle.main
        var url = bundle.url(forResource: localizedResource, withExtension: "html")
        if (url == nil) {
            url = bundle.url(forResource: helpTopic.resource, withExtension: "html")
        }

        let helpWebViewController = segue.destination as! HelpWebViewController
        helpWebViewController.title = NSLocalizedString(helpTopic.title, comment: "")
        helpWebViewController.url = url
    }
    
    // MARK: - Actions

    @IBAction func donePressedAction(_ sender: UIBarButtonItem?) {
        self.dismiss(animated: true, completion: nil)
    }
}
