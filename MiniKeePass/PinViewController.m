/*
 * Copyright 2011-2014 Jason Rush and John Flanagan. All rights reserved.
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

#import "PinViewController.h"
#import "PinTextField.h"

#define PIN_NUM_DIGITS           4

#define TOOLBAR_HEIGHT_PORTRAIT  95.0f
#define TOOLBAR_HEIGHT_LANDSCAPE 68.0f

#define PIN_TEXT_FIELD_WIDTH     61.0f
#define PIN_TEXT_FIELD_HEIGHT    52.0f
#define PIN_TEXT_FIELD_SPACE     10.0f

@interface PinViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSMutableArray *pinTextFields;
@property (nonatomic, strong) UIToolbar *titleToolbar;
@property (nonatomic, strong) UIToolbar *pinToolbar;

@end

@implementation PinViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // In iOS 7 don't layout under the status bar
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.view.backgroundColor = [UIColor darkGrayColor];

    CGFloat frameWidth = CGRectGetWidth(self.view.frame);

    // Create the title label
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frameWidth, TOOLBAR_HEIGHT_PORTRAIT)];
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = UITextAlignmentCenter;
    self.titleLabel.text = NSLocalizedString(@"Enter your PIN to unlock", nil);

    // Hack for iOS 7
    CGFloat y = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 ? 20.0f : 0.0f;

    // Add the title label to a toolbar
    self.titleToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, y, frameWidth, 95.0f)];
    self.titleToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.titleToolbar.barStyle = UIBarStyleBlackTranslucent;
    [self.titleToolbar addSubview:self.titleLabel];
    [self.view addSubview:self.titleToolbar];

    CGFloat w = PIN_TEXT_FIELD_WIDTH * PIN_NUM_DIGITS + PIN_TEXT_FIELD_SPACE * (PIN_NUM_DIGITS - 1);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake((frameWidth - w) / 2, 22, w, PIN_TEXT_FIELD_HEIGHT)];
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    // Create the PIN text fields
    CGFloat xOrigin = 0;
    self.pinTextFields = [NSMutableArray arrayWithCapacity:PIN_NUM_DIGITS];
    for (int i = 0; i < PIN_NUM_DIGITS; i++) {
        PinTextField *pinTextField = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, PIN_TEXT_FIELD_WIDTH, PIN_TEXT_FIELD_HEIGHT)];
        xOrigin += (PIN_TEXT_FIELD_WIDTH + PIN_TEXT_FIELD_SPACE);
        [view addSubview:pinTextField];

        [self.pinTextFields addObject:pinTextField];
    }

    // Create a toolbar that contains the PIN text fields
    self.pinToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, frameWidth, TOOLBAR_HEIGHT_PORTRAIT)];
    self.pinToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.pinToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [self.pinToolbar addSubview:view];

    // Add a hidden text field where the typing actually occurs
    self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.textField.inputAccessoryView = self.pinToolbar;
    self.textField.delegate = self;
    self.textField.hidden = YES;
    self.textField.secureTextEntry = YES;
    self.textField.keyboardType = UIKeyboardTypeNumberPad;
    self.textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    [self.view addSubview:self.textField];

    // Add a listener to whenever the hidden PIN text field is changed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.textField];

    // Add a listener to when the keyboard hides
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];

    [self.textField becomeFirstResponder];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self resizeToolbarsToInterfaceOrientation:orientation];

    [self clearPinEntry];

    [self.textField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.textField becomeFirstResponder];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self resizeToolbarsToInterfaceOrientation:toInterfaceOrientation];
    }];
}

- (void)resizeToolbarsToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    // Nothing needs to be done for the iPad; return
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return;
    }

    // Shrink the height of the two toolbars in landscape mode
    CGFloat height = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? TOOLBAR_HEIGHT_PORTRAIT : TOOLBAR_HEIGHT_LANDSCAPE;

    CGRect frame = self.titleToolbar.frame;
    self.titleToolbar.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, height);

    frame = self.pinToolbar.frame;
    self.pinToolbar.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, height);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Keybord/TextField methods

- (void)keyboardDidHide {
    // If the keyboard is dismissed, show it again.
    [self.textField becomeFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger oldLength = textField.text.length;
    NSUInteger replacementLength = string.length;
    NSUInteger rangeLength = range.length;

    NSUInteger newLength = oldLength - rangeLength + replacementLength;

    return newLength <= PIN_NUM_DIGITS;
}

- (void)textDidChange:(NSNotification*)notification {
    NSUInteger n = [self.textField.text length];
    for (NSUInteger i = 0; i < PIN_NUM_DIGITS; i++) {
        PinTextField *pinTextField = [self.pinTextFields objectAtIndex:i];
        if (i < n) {
            pinTextField.label.text = @"●";
        } else {
            pinTextField.label.text = @"";
        }
    }

    if (n == PIN_NUM_DIGITS) {
        [self performSelector:@selector(checkPin:) withObject:nil afterDelay:0.3];
    }
}

#pragma mark - PIN methods

- (void)checkPin:(id)sender {
    if ([self.delegate respondsToSelector:@selector(pinViewController:pinEntered:)]) {
        [self.delegate pinViewController:self pinEntered:self.textField.text];
    }
}

- (void)clearPinEntry {
    self.textField.text = @"";

    for (PinTextField *pinTextField in self.pinTextFields) {
        pinTextField.label.text = @"";
    }
}

@end
