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
@property (nonatomic, assign) id<MKPWebViewDelegate> mkpDelegate;
@end

@protocol MKPWebViewDelegate <NSObject>
- (void)usernamePressed:(MKPWebView *)webview;
- (void)passwordPressed:(MKPWebView *)webview;
@end

@implementation MKPWebView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
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

@interface WebViewController () <UIWebViewDelegate, UITextFieldDelegate, MKPWebViewDelegate>
@property (nonatomic, strong) UITextField *urlTextField;
@property (nonatomic, assign) CGRect originalUrlFrame;

@property (nonatomic, strong) UIBarButtonItem *autotypeButtons;

@property (nonatomic, strong) MKPWebView *webView;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *forwardButton;
@property (nonatomic, strong) UIBarButtonItem *reloadButton;
@property (nonatomic, strong) UIBarButtonItem *openInButton;
@end

@implementation WebViewController

- (void)viewDidLoad {
    // Create the URL text field
    CGFloat height = UrlFieldHeight(self.interfaceOrientation);
    self.urlTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.navigationBar.bounds.size.width, height)];
    self.urlTextField.contentVerticalAlignment = UIViewContentModeCenter;
    self.urlTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.urlTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.urlTextField.font = [UIFont systemFontOfSize:14.0f];
    self.urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.urlTextField.keyboardType = UIKeyboardTypeURL;
    self.urlTextField.returnKeyType = UIReturnKeyGo;
    [self.urlTextField addTarget:self action:@selector(textFieldEditingDidEnd:) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.urlTextField.delegate = self;
    self.navigationItem.titleView = self.urlTextField;

    // Create the autotype buttons
    NSArray *items = @[[UIImage imageNamed:@"user"], [UIImage imageNamed:@"asterisk"]];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    [segmentedControl addTarget:self
                         action:@selector(autotypePressed:)
               forControlEvents:UIControlEventValueChanged];
    self.autotypeButtons = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    self.navigationItem.rightBarButtonItem = self.autotypeButtons;

    // Create the web view
    self.webView = [[MKPWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    self.webView.mkpDelegate = self;
    self.webView.keyboardDisplayRequiresUserAction = NO;
	[self.view addSubview:self.webView];

    // Create the toolbar button
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"]
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(backPressed)];
    self.backButton.enabled = NO;

    self.forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(forwardPressed)];
    self.forwardButton.enabled = NO;

    self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                  target:self
                                                                  action:@selector(reloadPressed)];

    self.openInButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                  target:self
                                                                  action:@selector(openInPressed)];

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                target:nil
                                                                                action:nil];
    fixedSpace.width = 10.0f;

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];

    self.toolbarItems = @[
                          fixedSpace,
                          self.backButton,
                          flexibleSpace,
                          self.forwardButton,
                          flexibleSpace,
                          self.reloadButton,
                          flexibleSpace,
                          self.openInButton,
                          fixedSpace
                          ];

    // Load the URL
    NSURL *url = [NSURL URLWithString:self.entry.url];
    if (url.scheme == nil) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:self.entry.url]];
    }

    self.urlTextField.text = [url absoluteString];

    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Stop the network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    CGFloat height = UrlFieldHeight(self.interfaceOrientation);
    self.urlTextField.frame = CGRectMake(0, 0, self.navigationController.navigationBar.bounds.size.width, height);
}

#pragma mark - URL Text Field

- (void)textFieldEditingDidEnd:(id)sender {
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    if (url.scheme == nil) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:self.urlTextField.text]];
        self.urlTextField.text = [url absoluteString];
    }

    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // Save the original size of the url text field
    self.originalUrlFrame = self.urlTextField.frame;

    // Compute a new frame size
    CGFloat height = UrlFieldHeight(self.interfaceOrientation);
    CGRect frame = CGRectMake(0, 0, self.navigationController.navigationBar.bounds.size.width, height);

    // Hide the buttons
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];

    // Animate the size of the url text field
    [UIView animateWithDuration:0.4 animations:^{
        self.urlTextField.frame = frame;
    }];

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.4 animations:^{
        // Display the buttons
        [self.navigationItem setHidesBackButton:NO animated:YES];
        [self.navigationItem setRightBarButtonItem:self.autotypeButtons animated:YES];

        // Restore the url text fields frame
        self.urlTextField.frame = self.originalUrlFrame;
    }];

    return YES;
}

#pragma mark - Buttons

- (void)updateButtons {
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    self.openInButton.enabled = !self.webView.isLoading;
}

- (void)backPressed {
    if (self.webView.canGoBack) {
        [self.webView goBack];
    }
}

- (void)forwardPressed {
    if (self.webView.canGoForward) {
        [self.webView goForward];
    }
}

- (void)reloadPressed {
    [self.webView reload];
}

- (void)openInPressed {
    [[UIApplication sharedApplication] openURL:self.webView.request.URL];
}

- (void)autotypeString:(NSString *)string {
    // Escape single quotes
    NSString *escapedString = [string stringByReplacingOccurrencesOfString:@"\'" withString:@"\\'"];

    NSString *script = [NSString stringWithFormat:@"if (document.activeElement) { document.activeElement.value = '%@'; }", escapedString];
    [self.webView stringByEvaluatingJavaScriptFromString:script];
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
    self.urlTextField.text = [webView.request.URL absoluteString];

    // Stop the network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self updateButtons];

    // Stop the network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
