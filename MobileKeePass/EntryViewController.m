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

@implementation EntryViewController

@synthesize entry;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delaysContentTouches = YES;
    
    // Replace the back button with our own so we can ask if they are sure
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backPressed:)];
    self.navigationItem.leftBarButtonItem = backButton;
    [backButton release];    
    
    titleCell = [[TextFieldCell alloc] init];
    titleCell.textLabel.text = @"Title";
    
    usernameCell = [[TextFieldCell alloc] init];
    usernameCell.textLabel.text = @"Username";
    usernameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    passwordCell = [[PasswordFieldCell alloc] init];
    passwordCell.textLabel.text = @"Password";
    
    urlCell = [[UrlFieldCell alloc] init];
    urlCell.textLabel.text = @"URL";
    
    commentsCell = [[TextViewCell alloc] init];
    
    appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPressed)];
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Add listeners to the keyboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    // Update the fields
    titleCell.textField.text = entry.title;
    usernameCell.textField.text = entry.username;
    passwordCell.textField.text = entry.password;
    urlCell.textField.text = entry.url;
    commentsCell.textView.text = entry.notes;
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
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
}

- (void)dealloc {
    [titleCell release];
    [usernameCell release];
    [passwordCell release];
    [urlCell release];
    [commentsCell release];
    [entry release];
    [super dealloc];
}

BOOL stringsEqual(NSString *str1, NSString *str2) {
    str1 = str1 == nil ? @"" : [str1 stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    str2 = str2 == nil ? @"" : [str2 stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    return [str1 isEqualToString:str2];
}

- (BOOL)isDirty {
    return !(stringsEqual(entry.title, titleCell.textField.text) &&
        stringsEqual(entry.username, usernameCell.textField.text) &&
        stringsEqual(entry.password, passwordCell.textField.text) &&
        stringsEqual(entry.url, urlCell.textField.text) &&
        stringsEqual(entry.notes, commentsCell.textView.text));
}

- (void)save {
    entry.title = titleCell.textField.text;
    entry.username = usernameCell.textField.text;
    entry.password = passwordCell.textField.text;
    entry.url = urlCell.textField.text;
    entry.notes = commentsCell.textView.text;
    
    appDelegate.databaseDocument.dirty = YES;
    
    // Save the database document
    [appDelegate.databaseDocument save];
}

- (void)backPressed:(id)sender {
    if ([self isDirty]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Save Changes?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard" otherButtonTitles:@"Save", nil];

        [appDelegate showActionSheet:actionSheet];
        [actionSheet release];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)tapPressed {
    [titleCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        if (buttonIndex != actionSheet.destructiveButtonIndex) {
            [self save];
        }
    
        [self.navigationController popViewControllerAnimated:YES];
    }
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
            return 140;
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
                    return usernameCell;
                case 2:
                    return passwordCell;
                case 3:
                    return urlCell;
            }
        case 1:
            return commentsCell;
    }
    
    return nil;
}

@end
