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

@interface FormViewController ()
@property (nonatomic, strong) NSMutableArray *cells;
@property (nonatomic, strong) InfoBar *infoBar;
@end

@implementation FormViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.scrollEnabled = NO;
        self.tableView.delegate = self;

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(donePressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelPressed:)];

        self.infoBar = [[InfoBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 20)];
        self.infoBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:self.infoBar];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:UIApplicationWillResignActiveNotification
                                object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UITextField *textField = [self.controls objectAtIndex:0];
    [textField becomeFirstResponder];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self resizeControlsForOrientation:toInterfaceOrientation];
    }];
}

- (void)resizeControlsForOrientation:(UIInterfaceOrientation)orientation {
    for (UIView *controlView in self.controls) {
        if (![controlView isKindOfClass:[UITableViewCell class]]) {
            controlView.frame = [self calculateNewFrameForView:controlView inOrientation:orientation];
        }
    }
}


- (void)applicationWillResignActive:(id)sender {
    for (UITextField *textField in self.controls) {
        if ([textField isFirstResponder]) {
            [textField resignFirstResponder];
        }
    }
}

- (void)setControls:(NSArray *)controls {
    _controls = controls;

    if (self.cells == nil) {
        self.cells = [[NSMutableArray alloc] initWithCapacity:[_controls count]];
    } else {
        [self.cells removeAllObjects];
    }

    UITableViewCell *cell;
    for (UIView *controlView in _controls) {
        if ([controlView isKindOfClass:[UITableViewCell class]]) {
            cell = (UITableViewCell*)controlView;
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            controlView.frame = [self calculateNewFrameForView:controlView
                                                 inOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
            [cell addSubview:controlView];
        }
        [self.cells addObject:cell];
    }
}

- (CGRect)calculateNewFrameForView:(UIView *)view inOrientation:(UIInterfaceOrientation)orientation {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat currentWidth = UIInterfaceOrientationIsPortrait(orientation) ? CGRectGetWidth(screenBounds) : CGRectGetHeight(screenBounds);

    CGFloat xOrigin = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 56.0f : 20.0f;
    CGFloat yOrigin = 11;
    CGFloat width = currentWidth - 2 * xOrigin;
    CGFloat height = 22;

    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (void)showErrorMessage:(NSString *)message {
    [self.view bringSubviewToFront:self.infoBar];
    self.infoBar.label.text = message;
    [self.infoBar showBar];
}

#pragma mark - Button actions

- (void)donePressed:(id)sender {
    if (self.donePressed != nil) {
        self.donePressed(self);
    }
}

- (void)cancelPressed:(id)sender {
    if (self.cancelPressed != nil) {
        self.cancelPressed(self);
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.controls count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.headerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.footerTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.cells objectAtIndex:indexPath.row];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self donePressed:nil];
    return YES;
}

@end
