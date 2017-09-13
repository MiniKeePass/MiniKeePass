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

    fileprivate var webView: WKWebView!
    
    @objc var url: URL?
    @objc var entry: KdbEntry?

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
        backButton.isEnabled = false
        forwardButton.isEnabled = false

        // Add autolayout constraints for the web view
        webView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0)
        view.addConstraints([widthConstraint, heightConstraint])

        // Configure the delegate and observers
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)

        // Load the URL
        let urlRequest = URLRequest(url:url!)
        webView!.load(urlRequest)
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "loading")
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    func autotypeString(_ string: String) {
        // Escape backslashes & single quotes
        var escapedString = string
        escapedString = escapedString.replacingOccurrences(of: "\\", with: "\\\\")
        escapedString = escapedString.replacingOccurrences(of: "\'", with: "\\'")
        
        // Execute a script to set the value of the selected element
        let script = String(format:"if (document.activeElement) { document.activeElement.value = '%@'; }", escapedString)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // MARK: - NSKeyValueObserving
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "loading") {
            backButton.isEnabled = webView.canGoBack
            forwardButton.isEnabled = webView.canGoForward
        } else if (keyPath == "estimatedProgress") {
            progressView.isHidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }

    // MARK: - WKWebView delegate

    func webView(_ webView: WKWebView, didFinish navigation:
        WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
        
        // Update the title
        navigationItem.title = webView.title
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
    }
    
    // MARK: - Actions
    
    @IBAction func closePressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pasteUsernamePressed(_ sender: UIBarButtonItem) {
        autotypeString(entry!.username())
    }
    
    @IBAction func pastePasswordPressed(_ sender: UIBarButtonItem) {
        autotypeString(entry!.password())
    }
    
    @IBAction func backPressed(_ sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func forwardPressed(_ sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func reloadPressed(_ sender: UIBarButtonItem) {
        let request = URLRequest(url:webView.url!)
        webView.load(request)
    }
    
    @IBAction func actionPressed(_ sender: UIBarButtonItem) {
        let application = UIApplication.shared
        application.openURL(webView.url!)
    }
}
