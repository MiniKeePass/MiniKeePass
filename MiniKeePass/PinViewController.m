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

#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import "PinViewController.h"
#import "PinTextField.h"
#import "MiniKeePassAppDelegate.h"

#define PINTEXTFIELDWIDTH  61.0f
#define PINTEXTFIELDHEIGHT 52.0f
#define TEXTFIELDSPACE     10.0f
#define PIN_NUM_DIGITS     4

@interface PinViewController ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSArray *pinTextFields;
@property (nonatomic, strong) UIToolbar *topBar;
@property (nonatomic, strong) UIToolbar *pinBar;

@end

@implementation PinViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor darkGrayColor];
    CGFloat frameWidth = CGRectGetWidth(self.view.frame);

    // In iOS 7 don't layout under the status bar
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    // Add a invisible text field where the typing actually occurs
    _textField = [[UITextField alloc] initWithFrame:CGRectZero];
    _textField.delegate = self;
    _textField.hidden = YES;
    _textField.secureTextEntry = YES;
    _textField.keyboardType = UIKeyboardTypeNumberPad;
    _textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    [self.view addSubview:_textField];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:_textField];

    // Create topbar
    _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frameWidth, 95)];
    _textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textLabel.backgroundColor = [UIColor clearColor];
    _textLabel.textColor = [UIColor whiteColor];
    _textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
    _textLabel.numberOfLines = 0;
    _textLabel.textAlignment = UITextAlignmentCenter;
    _textLabel.text = NSLocalizedString(@"Enter your PIN to unlock", nil);

    // Hack for iOS 7
    CGFloat y = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 ? 20.0f : 0.0f;

    _topBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, y, frameWidth, 95.0f)];
    _topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _topBar.barStyle = UIBarStyleBlackTranslucent;
    [_topBar addSubview:_textLabel];
    [self.view addSubview:_topBar];

    CGFloat textFieldViewWidth = PINTEXTFIELDWIDTH * 4 + TEXTFIELDSPACE * 3;

    UIView *textFieldsView = [[UIView alloc] initWithFrame:CGRectMake((frameWidth - textFieldViewWidth) / 2, 22, textFieldViewWidth, PINTEXTFIELDHEIGHT)];
    textFieldsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    CGFloat xOrigin = 0;

    PinTextField *pinTextField1 = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, PINTEXTFIELDWIDTH, PINTEXTFIELDHEIGHT)];
    xOrigin += (PINTEXTFIELDWIDTH + TEXTFIELDSPACE);
    [textFieldsView addSubview:pinTextField1];

    PinTextField *pinTextField2 = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, PINTEXTFIELDWIDTH, PINTEXTFIELDHEIGHT)];
    xOrigin += (PINTEXTFIELDWIDTH + TEXTFIELDSPACE);
    [textFieldsView addSubview:pinTextField2];

    PinTextField *pinTextField3 = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, PINTEXTFIELDWIDTH, PINTEXTFIELDHEIGHT)];
    xOrigin += (PINTEXTFIELDWIDTH + TEXTFIELDSPACE);
    [textFieldsView addSubview:pinTextField3];

    PinTextField *pinTextField4 = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, PINTEXTFIELDWIDTH, PINTEXTFIELDHEIGHT)];
    [textFieldsView addSubview:pinTextField4];

    _pinTextFields = @[pinTextField1, pinTextField2, pinTextField3, pinTextField4];

    _pinBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, frameWidth, 95)];
    _pinBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_pinBar setBarStyle:UIBarStyleBlackTranslucent];
    [_pinBar addSubview:textFieldsView];
    _textField.inputAccessoryView = _pinBar;

    // If the keyboard is dismissed, show it again.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardDidHide {
    [self.textField becomeFirstResponder];
}

- (void)resizeToolbarsToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    // Nothing needs to be done for the iPad; return
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return;
    }

    CGRect topBarFrame = self.topBar.frame;
    CGRect pinBarFrame = self.pinBar.frame;
    CGFloat height = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 95 : 68;

    self.topBar.frame = CGRectMake(topBarFrame.origin.x, topBarFrame.origin.y, topBarFrame.size.width, height);
    self.pinBar.frame = CGRectMake(pinBarFrame.origin.x, pinBarFrame.origin.y, pinBarFrame.size.width, height);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:false];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self resizeToolbarsToInterfaceOrientation:orientation];

    [self clearEntry];

    [self.textField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:false];
    if ([self.delegate respondsToSelector:@selector(pinViewControllerDidShow:)]) {
        [self.delegate pinViewControllerDidShow:self];
    }

    [self.textField becomeFirstResponder];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self resizeToolbarsToInterfaceOrientation:toInterfaceOrientation];
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
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

- (void)checkPin:(id)sender {
    if ([self.delegate respondsToSelector:@selector(pinViewController:pinEntered:)]) {
        [self.delegate pinViewController:self pinEntered:self.textField.text];
    }
}

- (void)clearEntry {
    self.textField.text = @"";
    
    for (PinTextField *pinTextField in self.pinTextFields) {
        pinTextField.label.text = @"";
    }
}

@end
