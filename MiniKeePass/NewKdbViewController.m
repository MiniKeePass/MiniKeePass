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

@synthesize statusLabel;

-(id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    int y = 150;
    
    self.tableView.delegate = self;
    
    nameTextField = [[UITextField alloc] init];
    nameTextField.delegate = self;
    nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    nameTextField.placeholder = @"Name";
    
    passwordTextField = [[UITextField alloc] init];
    passwordTextField.delegate = self;
    passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    passwordTextField.placeholder = @"Password";
    passwordTextField.secureTextEntry = YES;
    passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
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
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;    
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

@end
