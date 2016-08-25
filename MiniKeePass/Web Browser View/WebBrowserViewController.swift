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
import WebKit

class WebBrowserViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    // FIXME Add stop button too

    private var webView: WKWebView!
    
    var url: NSURL?
    var entry: KdbEntry?

    override func loadView() {
        super.loadView()
        
        webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        view.insertSubview(webView, belowSubview: progressView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the title from the url
        navigationItem.title = url?.host
        
        // Set the buttons disabled by default
        backButton.enabled = false
        forwardButton.enabled = false

        // Add autolayout constraints for the web view
        webView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: webView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: 0)
        view.addConstraints([widthConstraint, heightConstraint])

        // Configure the delegate and observers
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)

        // Load the URL
        let urlRequest = NSURLRequest(URL:url!)
        webView!.loadRequest(urlRequest)
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "loading")
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    func autotypeString(string: String) {
        // Escape backslashes & single quotes
        var escapedString = string
        escapedString = escapedString.stringByReplacingOccurrencesOfString("\\", withString: "\\\\")
        escapedString = escapedString.stringByReplacingOccurrencesOfString("\'", withString: "\\'")
        
        // Execute a script to set the value of the selected element
        let script = String(format:"if (document.activeElement) { document.activeElement.value = '%@'; }", escapedString)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // MARK: - NSKeyValueObserving
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "loading") {
            backButton.enabled = webView.canGoBack
            forwardButton.enabled = webView.canGoForward
        } else if (keyPath == "estimatedProgress") {
            progressView.hidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }

    // MARK: - WKWebView delegate

    func webView(webView: WKWebView, didFinishNavigation navigation:
        WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
        
        // Update the title
        navigationItem.title = webView.title
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
    }
    
    // MARK: - Actions
    
    @IBAction func closePressed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func pasteUsernamePressed(sender: UIBarButtonItem) {
        autotypeString(entry!.username())
    }
    
    @IBAction func pastePasswordPressed(sender: UIBarButtonItem) {
        autotypeString(entry!.password())
    }
    
    @IBAction func backPressed(sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func forwardPressed(sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func reloadPressed(sender: UIBarButtonItem) {
        let request = NSURLRequest(URL:webView.URL!)
        webView.loadRequest(request)
    }
    
    @IBAction func actionPressed(sender: UIBarButtonItem) {
        let application = UIApplication.sharedApplication()
        application.openURL(webView.URL!)
    }
}
