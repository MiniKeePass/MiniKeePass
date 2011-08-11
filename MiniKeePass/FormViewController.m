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

#import "FormViewController.h"

@implementation FormViewController

@synthesize controls;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.scrollEnabled = NO;
        self.tableView.delegate = self;
        
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
    [infoBar release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    UITextField *textField = [controls objectAtIndex:0];
    [textField becomeFirstResponder];
}

- (void)applicationWillResignActive:(id)sender {
    for (UITextField *textField in controls) {
        if ([textField isFirstResponder]) {
            [textField resignFirstResponder];
        }
    }
}

- (void)showErrorMessage:(NSString *)message {
    [self.view bringSubviewToFront:infoBar];
    infoBar.label.text = message;
    [infoBar showBar];
}

- (void)okPressed:(id)sender {
    if ([delegate respondsToSelector:@selector(formViewController:button:)]) {
        [delegate formViewController:self button:FormViewControllerButtonOk];
    }
}

- (void)cancelPressed:(id)sender {
    if ([delegate respondsToSelector:@selector(formViewController:button:)]) {
        [delegate formViewController:self button:FormViewControllerButtonCancel];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [controls count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    UIView *view = [controls objectAtIndex:indexPath.row];
    if ([view isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell*)view;
    } else {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGRect frame = cell.frame;
        frame.size.width -= 40;
        frame.size.height -= 22;
        frame.origin.x = 20;
        frame.origin.y = 11;
        
        view.frame = frame;
        [cell addSubview:view];
    }
    
    return cell;
}

@end
