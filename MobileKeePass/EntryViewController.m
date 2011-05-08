//
//  EntryViewController.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "EntryViewController.h"
#import "MobileKeePassAppDelegate.h"

@implementation EntryViewController

@synthesize entry;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delaysContentTouches = YES;
    
    // Replace the back button with our own so we can ask if they are sure
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backPressed:)];
    self.navigationItem.leftBarButtonItem = backButton;
    [backButton release];    
    
    titleCell = [[TextFieldCell alloc] initWithParent:self.tableView];
    titleCell.label.text = @"Title";
    
    urlCell = [[UrlFieldCell alloc] initWithParent:self.tableView];    
    urlCell.label.text = @"URL";
    
    usernameCell = [[TextFieldCell alloc] initWithParent:self.tableView];
    usernameCell.label.text = @"Username";
    usernameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    passwordCell = [[PasswordFieldCell alloc] initWithParent:self.tableView];
    passwordCell.label.text = @"Password";
    
    commentsCell = [[TextViewCell alloc] initWithParent:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Add listeners to the keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    // Update the fields
    titleCell.textField.text = entry._title;
    urlCell.textField.text = entry._url;
    usernameCell.textField.text = entry._username;
    passwordCell.textField.text = entry._password;
    commentsCell.textView.text = entry._comment;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    originalHeight = self.view.frame.size.height;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Remove listeners from the keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [titleCell release];
    [urlCell release];
    [usernameCell release];
    [passwordCell release];
    [commentsCell release];
    [entry release];
    [super dealloc];
}

BOOL stringsEqual(NSString *str1, NSString *str2) {
    str1 = str1 == nil ? @"" : str1;
    str2 = str2 == nil ? @"" : str2;
    return [str1 isEqualToString:str2];
}

- (BOOL)isDirty {
    return !(stringsEqual(entry._title, titleCell.textField.text) &&
        stringsEqual(entry._url, urlCell.textField.text) &&
        stringsEqual(entry._username, usernameCell.textField.text) &&
        stringsEqual(entry._password, passwordCell.textField.text) &&
        stringsEqual(entry._comment, commentsCell.textView.text));
}

- (void)save {
    entry._title = titleCell.textField.text;
    entry._url = urlCell.textField.text;
    entry._username = usernameCell.textField.text;
    entry._password = passwordCell.textField.text;
    entry._comment = commentsCell.textView.text;
    
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.databaseDocument.dirty = YES;
}

- (void)backPressed:(id)sender {
    if ([self isDirty]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Save Changes?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Discard" otherButtonTitles:@"Save", nil];
        [actionSheet showInView:self.view.window];
        [actionSheet release];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
        [self save];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)keyboardWasShown:(NSNotification*)notification {
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGRect frame = self.view.frame;
    frame.size.height = originalHeight - kbSize.height;
    
    self.tableView.frame = frame;
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
    CGRect rect = self.view.frame;
    rect.size.height = originalHeight;
    
    self.tableView.frame = rect;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 4;
        case 1:
            return 1;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 40;
        case 1:
            return 190;
    }
    
    return 40;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return nil;
        case 1:
            return @"Comments";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    return titleCell;
                case 1:
                    return urlCell;
                case 2:
                    return usernameCell;
                case 3:
                    return passwordCell;
            }
        case 1:
            return commentsCell;
    }
    
    return nil;
}

@end
