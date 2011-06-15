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
#import "InfoBar.h"

#define VSPACER 12
#define HSPACER 9
#define BUTTON_WIDTH (320 - 2 * HSPACER)
#define BUTTON_HEIGHT 32

@implementation NewKdbViewController

@synthesize nameTextField;
@synthesize passwordTextField1;
@synthesize passwordTextField2;
@synthesize versionSegmentedControl;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"New Database";
        
        self.tableView.scrollEnabled = NO;
        self.tableView.delegate = self;
        
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
        
        versionSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Version 1.x", @"Version 2.x", nil]];
        versionSegmentedControl.selectedSegmentIndex = 0;
        versionSegmentedControl.frame = CGRectMake(HSPACER, VSPACER, BUTTON_WIDTH, BUTTON_HEIGHT);
        [footerView addSubview:versionSegmentedControl];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(okPressed:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        [doneButton release];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];
        
        infoBar = [[InfoBar alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
        [self.view addSubview:infoBar];
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
    [versionSegmentedControl release];
    [infoBar release];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return VSPACER + BUTTON_HEIGHT + VSPACER;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return footerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

- (void)showMessage:(NSString *)message {
    [self.view bringSubviewToFront:infoBar];
    infoBar.label.text = message;
    [infoBar showBar];
}

@end
