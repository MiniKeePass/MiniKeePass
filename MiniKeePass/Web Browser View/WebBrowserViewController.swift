//
//  WebBrowserViewController.swift
//  MiniKeePass
//
//  Created by Jason Rush on 8/22/16.
//  Copyright © 2016 Self. All rights reserved.
//

import UIKit
import WebKit

class WebBrowserViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var toolbar: UIToolbar!
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
        let leading = NSLayoutConstraint(item: webView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: webView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: webView, attribute: .Bottom, relatedBy: .Equal, toItem: toolbar, attribute: .Top, multiplier: 1, constant: 0)
        view.addConstraints([top, bottom, leading, trailing])

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
