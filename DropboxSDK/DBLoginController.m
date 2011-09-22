//
//  DBLoginController.m
//  DropboxSDK
//
//  Created by Brian Smith on 5/20/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBLoadingView.h"
#import "DBLoginController.h"
#import "DBCreateAccountController.h"
#import "DBRestClient.h"


#define kTextFieldFrame CGRectMake(100, 11, 190, 24)


@interface DBLoginController () <UITextFieldDelegate, DBRestClientDelegate, 
UITableViewDataSource, UITableViewDelegate>

- (void)didPressLogin;
- (void)didPressCreateAccount;
- (void)setWorking:(BOOL)working;
- (void)errorWithTitle:(NSString*)title message:(NSString*)message;
- (void)updateActionButton;

@property (nonatomic, readonly) DBRestClient* restClient;

@end


@implementation DBLoginController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return interfaceOrientation == UIInterfaceOrientationPortrait;
    } else {
        return YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem* cancelItem =
        [[[UIBarButtonItem alloc] 
          initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
          target:self action:@selector(didPressCancel)] 
         autorelease];
         
    self.title = @"Link Account";

    UIImageView* background = 
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"db_background.png"]];
    background.frame = self.view.bounds;
    background.autoresizingMask = 
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:background];
    [background release];

    CGRect tableFrame = self.view.bounds;
    tableFrame.size.width = 320;
    tableFrame.origin.x = floor(self.view.bounds.size.width/2 - tableFrame.size.width/2);
    tableView = 
        [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | 
            UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.scrollEnabled = NO;
    tableView.delegate = self;
    tableView.dataSource = self;
    if ([tableView respondsToSelector:@selector(setBackgroundView:)]) {
        [tableView performSelector:@selector(setBackgroundView:) withObject:nil];
    }
        
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 152)];
    UIImageView* logo = 
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"db_logo.png"]];
    logo.contentMode = UIViewContentModeCenter;
    logo.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [logo sizeToFit];
    logo.center = headerView.center;
    CGRect logoFrame = logo.frame;
    logoFrame.origin.y += 7;
    logo.frame = logoFrame;
    [headerView addSubview:logo];
    tableView.tableHeaderView = headerView;
    [headerView release];
    [logo release];
    
    UIButton* createAccountButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [createAccountButton 
        setImage:[UIImage imageNamed:@"db_create_account.png"] 
        forState:UIControlStateNormal];
    [createAccountButton 
        addTarget:self action:@selector(didPressCreateAccount) 
        forControlEvents:UIControlEventTouchUpInside];
    CGFloat createAccountHeight = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 36 : 44;
    createAccountButton.frame = CGRectMake(0, 0, 264, createAccountHeight);
    tableView.tableFooterView = createAccountButton;
    
    [self.view addSubview:tableView];
    
    self.navigationItem.leftBarButtonItem = cancelItem;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.navigationItem.rightBarButtonItem =
            [[[UIBarButtonItem alloc]
              initWithTitle:@"Link" style:UIBarButtonItemStyleDone
              target:self action:@selector(didPressLogin)]
             autorelease];
        self.navigationItem.backBarButtonItem = 
            [[[UIBarButtonItem alloc] 
              initWithTitle:@"Link" style:UIBarButtonItemStylePlain target:nil action:nil] 
             autorelease];
    }
}


- (void)releaseViews {
    [tableView release];
    tableView = nil;
    [descriptionLabel release];
    descriptionLabel = nil;
    [emailCell release];
    emailCell = nil;
    [emailField release];
    emailField = nil;
    [passwordCell release];
    passwordCell = nil;
    [passwordField release];
    passwordField = nil;
    [footerView release];
    footerView = nil;
    [activityIndicator release];
    activityIndicator = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self releaseViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateActionButton];
}

- (void)dealloc {
    [loadingView release];
    [restClient release];
    [self releaseViews];
    [super dealloc];
}


- (void)presentFromController:(UIViewController*)controller {
    UINavigationController* navController = 
        [[[UINavigationController alloc] initWithRootViewController:self] autorelease];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [controller presentModalViewController:navController animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    hasAppeared = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    hasAppeared = YES;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && 
            UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            
        [emailField becomeFirstResponder];
    }
}


@synthesize delegate;


- (void)didPressLogin {
    if ([emailField.text length] == 0) {
        [self errorWithTitle:@"Email Required" message:@"Please enter your email."];
        return;
    } else if ([passwordField.text length] == 0) {
        [self errorWithTitle:@"Password Required" message:@"Please enter you password."];
        return;
    }

    [emailField resignFirstResponder];
    [passwordField resignFirstResponder];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [tableView setContentOffset:CGPointZero animated:YES];
    }
    [self setWorking:YES];
    
    [self.restClient loginWithEmail:emailField.text password:passwordField.text];
}


- (void)didPressCreateAccount {
    DBCreateAccountController* createAccountController = 
        [[DBCreateAccountController new] autorelease];
    createAccountController.loginController = self;
    [self.navigationController pushViewController:createAccountController animated:YES];
}


- (void)didPressCancel {
    [self setWorking:NO];
    [self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
    [delegate loginControllerDidCancel:self];
}


#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [tableView setContentOffset:CGPointMake(0, 150) animated:hasAppeared];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    if (textField == emailField) {
        [passwordField becomeFirstResponder];
    } else {
        [self didPressLogin];
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string {
    [self performSelector:@selector(updateActionButton) withObject:nil afterDelay:0];
    return YES;
}


#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 2 : 0;
}

- (UITableViewCell*)newCellWithTitle:(NSString*)title textField:(UITextField*)textField {
    UITableViewCell* cell = 
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    textField.frame = kTextFieldFrame;
    textField.borderStyle = UITextBorderStyleNone;
    textField.delegate = self;
    [cell.contentView addSubview:textField];
    return cell;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([indexPath row] == 0) {
        if (!emailCell) {
            emailField = [UITextField new];
            emailField.placeholder = @"example@gmail.com";
            emailField.keyboardType = UIKeyboardTypeEmailAddress;
            emailField.returnKeyType = UIReturnKeyNext;
            emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            emailField.autocorrectionType = UITextAutocorrectionTypeNo;
            emailCell = [self newCellWithTitle:@"Email" textField:emailField];
        }
        return emailCell;
    } else {
        if (!passwordCell) {
            passwordField = [UITextField new];
            passwordField.placeholder = @"Required";
            passwordField.secureTextEntry = YES;
            passwordField.returnKeyType = UIReturnKeyDone;
            passwordCell = [self newCellWithTitle:@"Password" textField:passwordField];
        }
        return passwordCell;
    }
}


#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if (section != 0) return 0;
    
    return 53;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 0) return nil;
    
    if (!descriptionLabel) {
        descriptionLabel = 
            [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"db_link_header.png"]];
        descriptionLabel.contentMode = UIViewContentModeCenter;
/*
        descriptionLabel = [UILabel new];
        descriptionLabel.backgroundColor = [UIColor clearColor];
        descriptionLabel.textColor = [UIColor whiteColor];
        descriptionLabel.font = [UIFont systemFontOfSize:15];
        descriptionLabel.textAlignment = UITextAlignmentCenter;
        descriptionLabel.text = 
            @"Linking will allow this app to access\nand modify files in your Dropbox";
        descriptionLabel.numberOfLines = 2;
*/
    }
    return descriptionLabel;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 80 : 0;
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) return nil;
    
    if (footerView == nil) {
        footerView = [[UIView alloc] init];
        footerView.backgroundColor = [UIColor clearColor];
        UIButton* linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [linkButton addTarget:self action:@selector(didPressLogin) 
                forControlEvents:UIControlEventTouchUpInside];
        [linkButton setImage:[UIImage imageNamed:@"db_link_button.png"]
                forState:UIControlStateNormal];
        [linkButton setImage:[UIImage imageNamed:@"db_link_button_down.png"]
                forState:UIControlStateHighlighted];
        [linkButton sizeToFit];
        CGRect linkFrame = linkButton.frame;
        linkFrame.origin.x = 320 - linkFrame.size.width - 8;
        linkFrame.origin.y = 8;
        linkButton.frame = linkFrame;
        [footerView addSubview:linkButton];
        
        activityIndicator = [[UIActivityIndicatorView alloc] 
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGRect activityFrame = activityIndicator.frame;
        activityFrame.origin.x = 320 - activityFrame.size.width - 21;
        activityFrame.origin.y = 17;
        activityIndicator.frame = activityFrame;
        [footerView addSubview:activityIndicator];
    }
    return footerView;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([indexPath row] == 0) {
        [emailField becomeFirstResponder];
    } else {
        [passwordField becomeFirstResponder];
    }
}


#pragma mark DBRestClient methods

- (void)restClientDidLogin:(DBRestClient*)client {
    [self setWorking:NO];
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    [delegate loginControllerDidLogin:self];
}


- (void)restClient:(DBRestClient*)client loginFailedWithError:(NSError*)error {
    [self setWorking:NO];

    NSString* message;
    if ([error.domain isEqual:NSURLErrorDomain]) {
        message = @"There was an error connecting to Dropbox.";
    } else {
        NSObject* errorResponse = [[error userInfo] objectForKey:@"error"];
        if ([errorResponse isKindOfClass:[NSString class]]) {
            message = (NSString*)errorResponse;
        } else if ([errorResponse isKindOfClass:[NSDictionary class]]) {
            NSDictionary* errorDict = (NSDictionary*)errorResponse;
            message = [errorDict objectForKey:[[errorDict allKeys] objectAtIndex:0]];
        } else {
            message = @"An unknown error has occurred.";
        }
    }
    [self errorWithTitle:@"Unable to Login" message:message];
}


#pragma mark private methods

- (void)setWorking:(BOOL)working {
    self.view.userInteractionEnabled = !working;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (working) {
            loadingView = [[DBLoadingView alloc] initWithTitle:@"Linking"];
            [loadingView show];
        } else {
            [loadingView dismissAnimated:NO];
            [loadingView release];
            loadingView = nil;
        }
        [self updateActionButton];
    } else {
        if (working) {
            [activityIndicator startAnimating];
        } else {
            [activityIndicator stopAnimating];
        }
    }
}


- (void)errorWithTitle:(NSString*)title message:(NSString*)message {
    [[[[UIAlertView alloc] 
       initWithTitle:title message:message delegate:nil 
       cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
}


- (void)updateActionButton {
    self.navigationItem.rightBarButtonItem.enabled = 
        [emailField.text length] > 0 &&
        [passwordField.text length] > 0 &&
        !loadingView;
}


- (DBRestClient*)restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

@end
