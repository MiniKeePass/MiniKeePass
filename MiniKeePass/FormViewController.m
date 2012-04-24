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
@synthesize headerTitle;
@synthesize footerTitle;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.scrollEnabled = NO;
        self.tableView.delegate = self;
        
        headerTitle = nil;
        footerTitle = nil;
        
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
    [controls release];
    [infoBar release];
    [headerTitle release];
    [footerTitle release];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return headerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return footerTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    UIView *view = [controls objectAtIndex:indexPath.row];
    if ([view isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell*)view;
    } else {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        view.frame = [self calculateNewFrameForView:view inOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        [cell addSubview:view];
    }
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self okPressed:nil];
    return YES;
}

- (CGRect)calculateNewFrameForView:(UIView *)view inOrientation:(UIInterfaceOrientation)orientation{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat currentWidth = UIInterfaceOrientationIsPortrait(orientation) ? CGRectGetWidth(screenBounds) : CGRectGetHeight(screenBounds);
    
    CGFloat xOrigin = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 56.0f : 20.0f;
    CGFloat yOrigin = 11;
    CGFloat width = currentWidth - 2 * xOrigin;
    CGFloat height = 22;
    
    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (void)resizeControlsForOrientation:(UIInterfaceOrientation)orientation {
    for (UIView *view in self.controls) {
        if (![view isKindOfClass:[UITableViewCell class]]) {
            view.frame = [self calculateNewFrameForView:view inOrientation:orientation];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {	
    // Not sure why, but the non-UITableViewCell controls do not seem to get resized during rotation, so adjust here.
    [UIView animateWithDuration:duration animations:^{
        [self resizeControlsForOrientation:toInterfaceOrientation];
    }];
}

@end
