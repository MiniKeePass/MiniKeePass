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

#import "NewKdbViewController.h"

#define SPACER 12
#define LABEL_FIELD_HEIGHT 21
#define BUTTON_HEIGHT 37
#define BUTTON_WIDTH (147 - SPACER / 2)

@implementation NewKdbViewController

@synthesize nameTextField;
@synthesize passwordTextField1;
@synthesize passwordTextField2;
@synthesize versionSegmentedControl;
@synthesize statusLabel;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.delegate = self;
        self.tableView.scrollEnabled = NO;
        
        nameTextField = [[UITextField alloc] init];
        nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        nameTextField.placeholder = @"Name";
        
        passwordTextField1 = [[UITextField alloc] init];
        passwordTextField1.clearButtonMode = UITextFieldViewModeWhileEditing;
        passwordTextField1.placeholder = @"Password";
        passwordTextField1.secureTextEntry = YES;
        passwordTextField1.autocapitalizationType = UITextAutocapitalizationTypeNone;
        passwordTextField1.autocorrectionType = UITextAutocorrectionTypeNo;
        
        passwordTextField2 = [[UITextField alloc] init];
        passwordTextField2.clearButtonMode = UITextFieldViewModeWhileEditing;
        passwordTextField2.placeholder = @"Confirm Password";
        passwordTextField2.secureTextEntry = YES;
        passwordTextField2.autocapitalizationType = UITextAutocapitalizationTypeNone;
        passwordTextField2.autocorrectionType = UITextAutocorrectionTypeNo;
        
        footerView = [[UIView alloc] init];
        
        UIButton *okButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        okButton.frame = CGRectMake(9, SPACER, BUTTON_WIDTH, BUTTON_HEIGHT);
        [okButton setTitle:@"OK" forState:UIControlStateNormal];
        [okButton addTarget:self action:@selector(okPressed:) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:okButton];
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        cancelButton.frame = CGRectMake(9 + BUTTON_WIDTH + SPACER, SPACER, BUTTON_WIDTH, BUTTON_HEIGHT);
        [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:cancelButton];
        
        statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, SPACER + BUTTON_HEIGHT + SPACER, 300, LABEL_FIELD_HEIGHT)];
        statusLabel.textColor = [UIColor redColor];
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.textAlignment = UITextAlignmentCenter;
        [footerView addSubview:statusLabel];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)dealloc {
    [nameTextField release];
    [passwordTextField1 release];
    [passwordTextField2 release];
    [footerView release];
    [statusLabel release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [nameTextField becomeFirstResponder];
}

- (void)applicationWillResignActive:(id)sender {
    [nameTextField resignFirstResponder];
    [passwordTextField1 resignFirstResponder];
    [passwordTextField2 resignFirstResponder];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;    
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    return @"New Database";
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return SPACER + BUTTON_HEIGHT + SPACER + LABEL_FIELD_HEIGHT + SPACER;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return footerView;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
    cell.selectionStyle = UITableViewCellEditingStyleNone;
    
    CGRect frame = cell.frame;
    frame.size.width -= 40;
    frame.size.height -= 22;
    frame.origin.x = 20;
    frame.origin.y = 11;
    
    switch (indexPath.row) {
        case 0:
            nameTextField.frame = frame;
            [cell addSubview:nameTextField];
            break;
            
        case 1:
            passwordTextField1.frame = frame;
            [cell addSubview:passwordTextField1];
            break;
            
        case 2:
            passwordTextField2.frame = frame;
            [cell addSubview:passwordTextField2];
            break;
    }
    
    return cell;
}

- (void)okPressed:(id)sender {
    if ([delegate respondsToSelector:@selector(newKdbViewController:buttonIndex:)]) {
        [delegate newKdbViewController:self buttonIndex:ButtonIndexOk];
    }
}

- (void)cancelPressed:(id)sender {
    if ([delegate respondsToSelector:@selector(newKdbViewController:buttonIndex:)]) {
        [delegate newKdbViewController:self buttonIndex:ButtonIndexCancel];
    }
}

@end
