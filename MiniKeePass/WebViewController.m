//
//  WebViewController.m
//  MiniKeePass
//
//  Created by Jason Rush on 1/25/13.
//  Copyright (c) 2013 Self. All rights reserved.
//

#import "WebViewController.h"

#define kUrlFieldPortHeight 30.0f
#define kUrlFieldLandHeight 24.0f
#define UrlFieldHeight(orientation) (UIInterfaceOrientationIsPortrait(orientation) ? kUrlFieldPortHeight : kUrlFieldLandHeight)

@protocol MKPWebViewDelegate;

@interface MKPWebView : UIWebView
@property (nonatomic, assign)id<MKPWebViewDelegate> mkpDelegate;
@end

@protocol MKPWebViewDelegate <NSObject>
- (void)usernamePressed:(MKPWebView *)webview;
- (void)passwordPressed:(MKPWebView *)webview;
@end

@implementation MKPWebView

- (id)init {
    self = [super init];
    if (self) {
        UIMenuItem *username = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Username", nil) action:@selector(pasteUsername:)];
        UIMenuItem *password = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Password", nil) action:@selector(pastePassword:)];

        UIMenuController *menuController = [UIMenuController sharedMenuController];
        menuController.menuItems = @[username, password];
    }
    return self;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [super canPerformAction:action withSender:sender] || action == @selector(pasteUsername:) || action == @selector(pastePassword:);
}

- (void)pasteUsername:(id)sender {
    [self.mkpDelegate usernamePressed:self];
}

- (void)pastePassword:(id)sender {
    [self.mkpDelegate passwordPressed:self];
}

@end

@interface WebViewController () <UIWebViewDelegate, UITextFieldDelegate, MKPWebViewDelegate> {
    UITextField *_urlTextField;
    CGRect _originalUrlFrame;

    UIBarButtonItem *_autotypeButton;

    MKPWebView *_webView;
    UIBarButtonItem *_backButton;
    UIBarButtonItem *_forwardButton;
    UIBarButtonItem *_reloadButton;
    UIBarButtonItem *_openInButton;
}
@end

@implementation WebViewController

- (void)viewDidLoad {
    // Create the URL text field
    CGFloat height = UrlFieldHeight(self.interfaceOrientation);
    _urlTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.navigationBar.bounds.size.width, height)];
    _urlTextField.contentVerticalAlignment = UIViewContentModeCenter;
    _urlTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _urlTextField.borderStyle = UITextBorderStyleRoundedRect;
    _urlTextField.font = [UIFont systemFontOfSize:14.0f];
    _urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _urlTextField.keyboardType = UIKeyboardTypeURL;
    _urlTextField.returnKeyType = UIReturnKeyGo;
    [_urlTextField addTarget:self action:@selector(textFieldEditingDidEnd:) forControlEvents:UIControlEventEditingDidEndOnExit];
    _urlTextField.delegate = self;
    self.navigationItem.titleView = _urlTextField;

    // Create the autotype buttons
    NSArray *items = @[[UIImage imageNamed:@"username"], [UIImage imageNamed:@"password"]];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    [segmentedControl addTarget:self
                         action:@selector(autotypePressed:)
               forControlEvents:UIControlEventValueChanged];
    _autotypeButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    self.navigationItem.rightBarButtonItem = _autotypeButton;

    // Create the web view
    _webView = [[MKPWebView alloc] init];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	_webView.backgroundColor = [UIColor whiteColor];
    _webView.scalesPageToFit = YES;
	_webView.delegate = self;
    _webView.mkpDelegate = self;
    _webView.keyboardDisplayRequiresUserAction = NO;
	[self.view addSubview:_webView];

    // Create the toolbar button
    _backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"]
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(backPressed)];
    _backButton.enabled = NO;

    _forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(forwardPressed)];
    _forwardButton.enabled = NO;

    _reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                  target:self
                                                                  action:@selector(reloadPressed)];

    _openInButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                  target:self
                                                                  action:@selector(openInPressed)];

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10.0f;

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];

    self.toolbarItems = @[
                          fixedSpace,
                          _backButton,
                          flexibleSpace,
                          _forwardButton,
                          flexibleSpace,
                          _reloadButton,
                          flexibleSpace,
                          _openInButton,
                          fixedSpace
                          ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSURL *url = [NSURL URLWithString:self.entry.url];
    if (url.scheme == nil) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:self.entry.url]];
    }

    _urlTextField.text = [url absoluteString];

    _webView.frame = self.view.bounds;
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Stop the network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    CGFloat height = UrlFieldHeight(self.interfaceOrientation);
    _urlTextField.frame = CGRectMake(0, 0, self.navigationController.navigationBar.bounds.size.width, height);
}

#pragma mark - URL Text Field

- (void)textFieldEditingDidEnd:(id)sender {
    NSURL *url = [NSURL URLWithString:_urlTextField.text];
    if (url.scheme == nil) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:_urlTextField.text]];
        _urlTextField.text = [url absoluteString];
    }

    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // Save the original size of the url text field
    _originalUrlFrame = _urlTextField.frame;

    // Compute a new frame size
    CGFloat height = UrlFieldHeight(self.interfaceOrientation);
    CGRect frame = CGRectMake(0, 0, self.navigationController.navigationBar.bounds.size.width, height);

    // Hide the buttons
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];

    // Animate the size of the url text field
    [UIView animateWithDuration:0.4 animations:^{
        _urlTextField.frame = frame;
    }];

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.4 animations:^{
        // Display the buttons
        [self.navigationItem setHidesBackButton:NO animated:YES];
        [self.navigationItem setRightBarButtonItem:_autotypeButton animated:YES];

        // Restore the url text fields frame
        _urlTextField.frame = _originalUrlFrame;
    }];

    return YES;
}

#pragma mark - Buttons

- (void)updateButtons {
    _backButton.enabled = _webView.canGoBack;
    _forwardButton.enabled = _webView.canGoForward;
    _openInButton.enabled = !_webView.isLoading;
}

- (void)backPressed {
    if (_webView.canGoBack) {
        [_webView goBack];
    }
}

- (void)forwardPressed {
    if (_webView.canGoForward) {
        [_webView goForward];
    }
}

- (void)reloadPressed {
    [_webView reload];
}

- (void)openInPressed {
    [[UIApplication sharedApplication] openURL:_webView.request.URL];
}

- (void)autotypeString:(NSString *)string {
    // Escape single quotes
    NSString *escapedString = [string stringByReplacingOccurrencesOfString:@"\'" withString:@"\\'"];

    NSString *script = [NSString stringWithFormat:@"if (document.activeElement) { document.activeElement.value = '%@'; }", escapedString];
    [_webView stringByEvaluatingJavaScriptFromString:script];
}

- (void)autotypePressed:(UISegmentedControl *)segmentedControl {
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            [self autotypeString:self.entry.username];
            break;

        case 1:
            [self autotypeString:self.entry.password];
            break;

        default:
            break;
    }
}

- (void)usernamePressed:(MKPWebView *)webview {
    [self autotypeString:self.entry.username];
}

- (void)passwordPressed:(MKPWebView *)webview {
    [self autotypeString:self.entry.password];
}

#pragma mark - WebView delegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self updateButtons];

    // Start the network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self updateButtons];
    _urlTextField.text = [webView.request.URL absoluteString];

    // Stop the network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self updateButtons];

    // Stop the network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
