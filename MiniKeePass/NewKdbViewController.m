/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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

#define VSPACER 12
#define HSPACER 9
#define BUTTON_WIDTH (320 - 2 * HSPACER)
#define BUTTON_HEIGHT 32

@implementation NewKdbViewController

@synthesize nameTextField;
@synthesize passwordTextField1;
@synthesize passwordTextField2;
@synthesize versionSegmentedControl;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.headerTitle = NSLocalizedString(@"New Database", nil);
        self.footerTitle = NSLocalizedString(@"Do not forget your database password, it cannot be recovered.", nil);


        nameTextField = [[UITextField alloc] init];
        nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        nameTextField.placeholder = NSLocalizedString(@"Name", nil);
        nameTextField.returnKeyType = UIReturnKeyNext;
        nameTextField.delegate = self;
        
        passwordTextField1 = [[UITextField alloc] init];
        passwordTextField1.clearButtonMode = UITextFieldViewModeWhileEditing;
        passwordTextField1.placeholder = NSLocalizedString(@"Password", nil);
        passwordTextField1.secureTextEntry = YES;
        passwordTextField1.autocapitalizationType = UITextAutocapitalizationTypeNone;
        passwordTextField1.autocorrectionType = UITextAutocorrectionTypeNo;
        passwordTextField1.returnKeyType = UIReturnKeyNext;
        passwordTextField1.delegate = self;
        
        passwordTextField2 = [[UITextField alloc] init];
        passwordTextField2.clearButtonMode = UITextFieldViewModeWhileEditing;
        passwordTextField2.placeholder = NSLocalizedString(@"Confirm Password", nil);
        passwordTextField2.secureTextEntry = YES;
        passwordTextField2.autocapitalizationType = UITextAutocapitalizationTypeNone;
        passwordTextField2.autocorrectionType = UITextAutocorrectionTypeNo;
        passwordTextField2.returnKeyType = UIReturnKeyDone;
        passwordTextField2.delegate = self;

        versionSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Version 1.x", nil), NSLocalizedString(@"Version 2.x", nil), nil]];
        versionSegmentedControl.selectedSegmentIndex = 0;
        versionSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.navigationItem.titleView = versionSegmentedControl;
        
        self.controls = [NSArray arrayWithObjects:nameTextField, passwordTextField1, passwordTextField2, nil];
        self.tableView.scrollEnabled = YES;
    }
    return self;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {    
    CGPoint point = [self.tableView convertPoint:CGPointZero fromView:textField];
     UITableViewCell *cell =[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForRowAtPoint:point]];
    [self.tableView scrollRectToVisible:cell.frame animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == nameTextField) {
        [passwordTextField1 becomeFirstResponder];
    } else if (textField == passwordTextField1) {
        [passwordTextField2 becomeFirstResponder];
    } else if (textField == passwordTextField2) {
        [self okPressed:nil];
    }
    
    return YES;
}

@end
