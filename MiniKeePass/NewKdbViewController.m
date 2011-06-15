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
        self.title = @"New Database";
        
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
        
        self.controls = [NSArray arrayWithObjects:nameTextField, passwordTextField1, passwordTextField2, nil];
    }
    return self;
}

- (void)dealloc {
    [nameTextField release];
    [passwordTextField1 release];
    [passwordTextField2 release];
    [footerView release];
    [versionSegmentedControl release];
    [super dealloc];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return VSPACER + BUTTON_HEIGHT + VSPACER;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return footerView;
}

@end
