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
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        
        infoBar = [[InfoBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 20)];
        infoBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

// Create a local array of pre-generated cells.
// This has potential memory issues if a large number of cells are created, but it solves a probem with scrolling the form
- (void)setControls:(NSArray *)newControls {
    controls = newControls;
    
    if (cells == nil) {
        cells = [[NSMutableArray alloc] initWithCapacity:[controls count]];
    } else {
        [cells removeAllObjects];
    }
    
    UITableViewCell *cell;
    for (UIView *controlView in controls) {
        if ([controlView isKindOfClass:[UITableViewCell class]]) {
            cell = (UITableViewCell*)controlView;
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            controlView.frame = [self calculateNewFrameForView:controlView inOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
            [cell addSubview:controlView];
        }
        [cells addObject:cell];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [cells objectAtIndex:indexPath.row];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self okPressed:nil];
    return YES;
}

- (CGRect)calculateNewFrameForView:(UIView *)view inOrientation:(UIInterfaceOrientation)orientation{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat currentWidth = UIInterfaceOrientationIsPortrait(orientation) ? CGRectGetWidth(screenBounds) : CGRectGetHeight(screenBounds);
    
    CGFloat xOrigin = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 56.0f : 20.0f;
    if([[UIDevice currentDevice].systemVersion floatValue] >= 7) {
        xOrigin = 15.0f;
    }
    CGFloat yOrigin = 11;
    CGFloat width = currentWidth - 2 * xOrigin;
    CGFloat height = 22;
    
    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (void)resizeControlsForOrientation:(UIInterfaceOrientation)orientation {
    for (UIView *controlView in self.controls) {
        if (![controlView isKindOfClass:[UITableViewCell class]]) {
            controlView.frame = [self calculateNewFrameForView:controlView inOrientation:orientation];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {	
    [UIView animateWithDuration:duration animations:^{
        [self resizeControlsForOrientation:toInterfaceOrientation];
    }];
}

@end
