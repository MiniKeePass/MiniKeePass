//
//  DBCreateAccountController.m
//  DropboxSDK
//
//  Created by Brian Smith on 5/20/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBCreateAccountController.h"
#import "DBLoadingView.h"
#import "DBLoginController.h"
#import "DBRestClient.h"


enum {
    kRowFirstName,
    kRowLastName,
    kRowEmail,
    kRowPassword,
    kRowCount
};

#define kTextFieldFrame CGRectMake(108, 11, 182, 24)
#define CLEAR_OBJ(FIELD) [FIELD release]; FIELD = nil;


@interface DBCreateAccountController () <UITextFieldDelegate, DBRestClientDelegate,
UITableViewDataSource, UITableViewDelegate>

- (void)didPressCreateAccount;
- (void)setWorking:(BOOL)working;
- (void)updateActionButton;
- (void)errorWithTitle:(NSString*)title message:(NSString*)message;

@property (nonatomic, readonly) DBRestClient* restClient;

@end


@implementation DBCreateAccountController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.title = @"Create Account";
        UIBarButtonItem* saveItem = 
            [[[UIBarButtonItem alloc]
              initWithTitle:@"Create" style:UIBarButtonItemStyleDone
              target:self action:@selector(didPressCreateAccount)] 
             autorelease];
    self.navigationItem.rightBarButtonItem = saveItem;

    } else {
        self.title = @"Create Dropbox Account";
    }
    
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
    tableView.autoresizingMask = 
        UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | 
        UIViewAutoresizingFlexibleRightMargin;
    tableView.backgroundColor = [UIColor clearColor];
    if ([tableView respondsToSelector:@selector(setBackgroundView:)]) {
        [tableView performSelector:@selector(setBackgroundView:) withObject:nil];
    }
    tableView.scrollEnabled = NO;
    tableView.dataSource = self;
    tableView.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIView* tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 64)];
        tableView.tableHeaderView = tableHeaderView;
        [tableHeaderView release];
    }
    [self.view addSubview:tableView];
}

- (void)releaseViews {
    CLEAR_OBJ(tableView);
    CLEAR_OBJ(footerView);
    CLEAR_OBJ(firstNameCell);
    CLEAR_OBJ(firstNameField);
    CLEAR_OBJ(lastNameCell);
    CLEAR_OBJ(lastNameField);
    CLEAR_OBJ(emailCell);
    CLEAR_OBJ(emailField);
    CLEAR_OBJ(passwordCell);
    CLEAR_OBJ(passwordField);
    CLEAR_OBJ(footerView);
    CLEAR_OBJ(activityIndicator);
    CLEAR_OBJ(loadingView);
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self releaseViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateActionButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [firstNameField becomeFirstResponder];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return interfaceOrientation == UIInterfaceOrientationPortrait;
    } else {
        return YES;
    }
}


- (void)dealloc {
    [self releaseViews];
    [restClient release];
    [super dealloc];
}


@synthesize loginController;


- (IBAction)didPressCreateAccount {
    if ([firstNameField.text length] == 0) {
        [self errorWithTitle:@"First Name Required" message:@"Please enter your first name."];
        return;
    } else if ([lastNameField.text length] == 0) {
        [self errorWithTitle:@"Last Name Required" message:@"Please enter your last name."];
        return;
    } else if ([emailField.text length] == 0) {
        [self errorWithTitle:@"Email Address Required" message:@"Please enter your email address."];
        return;
    } else if ([passwordField.text length] == 0) {
        [self errorWithTitle:@"Password Required" message:@"Please enter your desired password"];
        return;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [firstNameField resignFirstResponder];
        [lastNameField resignFirstResponder];
        [emailField resignFirstResponder];
        [passwordField resignFirstResponder];
    }
    [self setWorking:YES];
    
    if (!hasCreatedAccount) {
        [self.restClient createAccount:emailField.text password:passwordField.text 
                         firstName:firstNameField.text lastName:lastNameField.text];
    } else {
        [self.restClient loginWithEmail:emailField.text password:passwordField.text];
    }
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    if (textField == firstNameField) {
        [lastNameField becomeFirstResponder];
    } else if (textField == lastNameField) {
        [emailField becomeFirstResponder];
    } else if (textField == emailField) {
        [passwordField becomeFirstResponder];
    } else {
        [self didPressCreateAccount];
    }

    return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string {
    // Update the button after the replacement has been made
    [self performSelector:@selector(updateActionButton) withObject:nil afterDelay:0];
    return YES;
}


#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return kRowCount;
}

- (UITableViewCell*)newCellWithLabel:(NSString*)label textField:(UITextField*)textField {

    UITableViewCell* cell = 
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = label;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    textField.frame = kTextFieldFrame;
    textField.borderStyle = UITextBorderStyleNone;
    textField.delegate = self;
    [cell.contentView addSubview:textField];
    
    return cell;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    switch ([indexPath row]) {
        case kRowFirstName:
            if (!firstNameCell) {
                firstNameField = [UITextField new];
                firstNameField.placeholder = @"John";
                firstNameField.returnKeyType = UIReturnKeyNext;
                firstNameField.autocorrectionType = UITextAutocorrectionTypeNo;
                firstNameCell = [self newCellWithLabel:@"First Name" textField:firstNameField];
            }
            return firstNameCell;
        case kRowLastName:
            if (!lastNameCell) {
                lastNameField = [UITextField new];
                lastNameField.placeholder = @"Appleseed";
                lastNameField.returnKeyType = UIReturnKeyNext;
                lastNameField.autocorrectionType = UITextAutocorrectionTypeNo;
                lastNameCell = [self newCellWithLabel:@"Last Name" textField:lastNameField];
            }
            return lastNameCell;
        case kRowEmail:
            if (!emailCell) {
                emailField = [UITextField new];
                emailField.placeholder = @"example@gmail.com";
                emailField.keyboardType = UIKeyboardTypeEmailAddress;
                emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                emailField.returnKeyType = UIReturnKeyNext;
                emailField.autocorrectionType = UITextAutocorrectionTypeNo;
                emailCell = [self newCellWithLabel:@"Email" textField:emailField];
            }
            return emailCell;
        case kRowPassword:
            if (!passwordCell) {
                passwordField = [UITextField new];
                passwordField.secureTextEntry = YES;
                passwordField.returnKeyType = UIReturnKeyDone;
                passwordField.placeholder = @"Required";
                passwordCell = [self newCellWithLabel:@"Password" textField:passwordField];
            }
            return passwordCell;
        default:
            return nil;
    }
}


#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    switch ([indexPath row]) {
        case kRowFirstName:
            [firstNameField becomeFirstResponder];
            return;
        case kRowLastName:
            [lastNameField becomeFirstResponder];
            return;
        case kRowEmail:
            [emailField becomeFirstResponder];
            return;
        case kRowPassword:
            [passwordField becomeFirstResponder];
            return;
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) return 0;
    
    return 53;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) return nil;
    
    if (headerView == nil) {
        headerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"db_link_header.png"]];
        headerView.contentMode = UIViewContentModeCenter;
    }
    return headerView;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) return 0;
    
    return 80;
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) return nil;
    
    if (footerView == nil) {
        footerView = [UIView new];
        footerView.backgroundColor = [UIColor clearColor];
        
        UIButton* createButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [createButton setImage:[UIImage imageNamed:@"db_create_account_button.png"] 
                forState:UIControlStateNormal];
        [createButton setImage:[UIImage imageNamed:@"db_create_account_button_down.png"]
                forState:UIControlStateHighlighted];
        [createButton addTarget:self action:@selector(didPressCreateAccount)
                forControlEvents:UIControlEventTouchUpInside];
        [createButton sizeToFit];
        CGRect buttonFrame = createButton.frame;
        buttonFrame.origin.x = 320 - buttonFrame.size.width - 8;
        buttonFrame.origin.y = 8;
        createButton.frame = buttonFrame;
        [footerView addSubview:createButton];
        
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


#pragma mark DBRestClientDelegate methods

- (void)restClientCreatedAccount:(DBRestClient*)client {
    hasCreatedAccount = YES;
    [self.restClient loginWithEmail:emailField.text password:passwordField.text];
}


- (void)restClient:(DBRestClient*)client createAccountFailedWithError:(NSError*)error {
    [self setWorking:NO];

    NSString* message = @"An unknown error occured.";
    if ([error.domain isEqual:NSURLErrorDomain]) {
        message = @"There was an error connecting to Dropbox.";
    } else {
        NSObject* errorResponse = [[error userInfo] objectForKey:@"error"];
        if ([errorResponse isKindOfClass:[NSString class]]) {
            message = (NSString*)errorResponse;
        } else if ([errorResponse isKindOfClass:[NSDictionary class]]) {
            NSDictionary* errorDict = (NSDictionary*)errorResponse;
            message = [errorDict objectForKey:[[errorDict allKeys] objectAtIndex:0]];
        }
    }
    [self errorWithTitle:@"Create Account Failed" message:message];
}


- (void)restClientDidLogin:(DBRestClient*)client {
    [self setWorking:NO];
    [self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
    [loginController.delegate loginControllerDidLogin:loginController];
}


- (void)restClient:(DBRestClient*)client loginFailedWithError:(NSError*)error {
    [self setWorking:NO];
    // Need to make sure they don't change the email or password if create account succeeded
    // but login failed
    emailField.enabled = NO;
    passwordField.enabled = NO;
    [self errorWithTitle:@"Login Failed" message:@"Please try again."];
}


#pragma mark private methods

- (void)setWorking:(BOOL)working {
    self.view.userInteractionEnabled = !working;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (working) {
            loadingView = [[DBLoadingView alloc] initWithTitle:@"Creating Account"];
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


- (void)updateActionButton {
    self.navigationItem.rightBarButtonItem.enabled = 
            [firstNameField.text length] > 0 &&
            [lastNameField.text length] > 0 &&
            [emailField.text length] > 0 &&
            [passwordField.text length] > 0 &&
            !loadingView;
}


- (void)errorWithTitle:(NSString*)title message:(NSString*)message {
    [[[[UIAlertView alloc] 
       initWithTitle:title message:message delegate:nil 
       cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
}


- (DBRestClient*)restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

@end
