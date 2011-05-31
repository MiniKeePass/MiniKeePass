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

#import "PasswordEntryController.h"

#define SPACER 12
#define LABEL_FIELD_HEIGHT 21
#define BUTTON_HEIGHT 37
#define BUTTON_WIDTH (147 - SPACER / 2)

@implementation PasswordEntryController

@synthesize statusLabel;
@synthesize delegate;

-(id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    int y = 100;
    
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.scrollEnabled = NO;
        
    textField = [[UITextField alloc] init];
    textField.secureTextEntry = YES;
    textField.placeholder = @"Password";
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyDone;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    okButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    okButton.frame = CGRectMake(9, y, BUTTON_WIDTH, BUTTON_HEIGHT);
    [okButton setTitle:@"OK" forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(okPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:okButton];
    
    cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cancelButton.frame = CGRectMake(17 + BUTTON_WIDTH + SPACER, y, BUTTON_WIDTH, BUTTON_HEIGHT);
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
    y += BUTTON_HEIGHT + SPACER;
    
    statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 280, LABEL_FIELD_HEIGHT)];
    statusLabel.textColor = [UIColor redColor];
    statusLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:statusLabel];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)dealloc {
    [textField release];
    [statusLabel release];
    [delegate release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [textField becomeFirstResponder];
}

- (void)applicationWillResignActive:(id)sender {
    [textField resignFirstResponder];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 37;
}

- (NSString *)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Database password";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;    
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellEditingStyleNone;
    
    CGRect frame = cell.frame;
    frame.size.width -= 40;
    frame.size.height -= 23;
    frame.origin.x = 20;
    frame.origin.y = 8;
    
    textField.frame = frame;
    [cell addSubview:textField];
    
    return cell;
}

- (void)okPressed:(id)sender {
    BOOL shouldDismiss = YES;
    
    if ([delegate respondsToSelector:@selector(passwordEntryController:passwordEntered:)]) {
        shouldDismiss = [delegate passwordEntryController:self passwordEntered:textField.text];
    }
    
    if (shouldDismiss) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)cancelPressed:(id)sender {
    if ([delegate respondsToSelector:@selector(passwordEntryControllerCancelButtonPressed:)]) {
        [delegate passwordEntryControllerCancelButtonPressed:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self okPressed:nil];
    return YES;
}

@end
