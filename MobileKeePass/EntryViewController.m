/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
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
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPressed)];
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Add listeners to the keyboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    // Update the fields
    titleCell.textField.text = [entry getEntryName];
    urlCell.textField.text = [entry getURL];
    usernameCell.textField.text = [entry getUserName];
    passwordCell.textField.text = [entry getPassword];
    commentsCell.textView.text = [entry getComments];
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

- (void)applicationWillResignActive:(id)sender {
    //resign first responder to prevent password being in sight and UI glitchs
    [titleCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
    
    [titleCell dismissActionSheet];
    [urlCell dismissActionSheet];
    [usernameCell dismissActionSheet];
    [passwordCell dismissActionSheet];
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
    return !(stringsEqual([entry getEntryName], titleCell.textField.text) &&
        stringsEqual([entry getURL], urlCell.textField.text) &&
        stringsEqual([entry getUserName], usernameCell.textField.text) &&
        stringsEqual([entry getPassword], passwordCell.textField.text) &&
        stringsEqual([entry getComments], commentsCell.textView.text));
}

- (void)save {
    [entry setEntryName:titleCell.textField.text];
    [entry setURL:urlCell.textField.text];
    [entry setUserName:usernameCell.textField.text];
    [entry setPassword:passwordCell.textField.text];
    [entry setComments:commentsCell.textView.text];
    
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

- (void)tapPressed {
    [titleCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
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
