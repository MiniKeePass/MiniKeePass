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

class HelpWebViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the help page
        let urlRequest = URLRequest(url: url!)
        webView.loadRequest(urlRequest)
    }
}
