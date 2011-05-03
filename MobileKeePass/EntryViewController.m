//
//  EntryViewController2.m
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
    
    titleCell = [[TextFieldCell alloc] initWithParent:self.tableView];
    titleCell.label.text = @"Title";
    
    urlCell = [[UrlFieldCell alloc] initWithParent:self.tableView];    urlCell.label.text = @"URL";
    
    usernameCell = [[TextFieldCell alloc] initWithParent:self.tableView];
    usernameCell.label.text = @"Username";
    usernameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    passwordCell = [[PasswordFieldCell alloc] initWithParent:self.tableView];
    passwordCell.label.text = @"Password";
    
    commentsCell = [[TextViewCell alloc] initWithParent:self.tableView];
    
    // Hide the back button and replace it with the cancel/save buttons
    self.navigationItem.hidesBackButton = YES;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(savePressed:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
    
    // Add listeners to the keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
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

- (void)dealloc {
    [titleCell release];
    [urlCell release];
    [usernameCell release];
    [passwordCell release];
    [commentsCell release];
    [super dealloc];
}

- (void)cancelPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)savePressed:(id)sender {
    entry._title = titleCell.textField.text;
    entry._url = urlCell.textField.text;
    entry._username = usernameCell.textField.text;
    entry._password = passwordCell.textField.text;
    entry._comment = commentsCell.textView.text;
    
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.databaseDocument.dirty = YES;
    
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
