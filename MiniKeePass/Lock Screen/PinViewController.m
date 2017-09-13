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
#import "KeypadView.h"

#define PIN_LENGTH 4

@interface PinViewController () <KeypadViewDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) UIView *pinView;
@property (nonatomic, strong) UILabel *pinLabel;
@property (nonatomic, strong) KeypadView *keypadView;
@property (nonatomic, strong) NSString *pin;
@end

@implementation PinViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Create a container view to hold everything
        self.pinView = [[UIView alloc] init];
        self.pinView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

        CGFloat w = self.view.bounds.size.width;
        CGFloat y = 0.0f;

        // Create the title label
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.text = NSLocalizedString(@"Enter your PIN to unlock", nil);
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.textColor = [UIColor darkGrayColor];
        self.titleLabel.font = [self.titleLabel.font fontWithSize:18];
        [self.titleLabel sizeToFit];
        [self.pinView addSubview:self.titleLabel];

        // Layout the title label
        CGFloat titleLabelHeight = self.titleLabel.bounds.size.height;
        self.titleLabel.frame = CGRectMake(0, y, w, titleLabelHeight);
        y += titleLabelHeight + 0.0f;

        // Create the pin label
        self.pinLabel = [[UILabel alloc] init];
        self.pinLabel.text = @"\u25CB";
        self.pinLabel.textAlignment = NSTextAlignmentCenter;
        self.pinLabel.textColor = [UIColor darkGrayColor];
        self.pinLabel.font = [UIFont fontWithName:@"ArialMT" size:36];
        [self.pinLabel sizeToFit];
        [self.pinView addSubview:self.pinLabel];

        // Layout the pin label
        CGFloat pinLabelHeight = self.pinLabel.bounds.size.height;
        self.pinLabel.frame = CGRectMake(0, y, w, pinLabelHeight);
        y += pinLabelHeight + 10.0f;

        // Create the keypad view
        self.keypadView = [[KeypadView alloc] init];
        self.keypadView.delegate = self;
        [self.pinView addSubview:self.keypadView];

        // Layout the keypad view
        CGSize keypadSize = self.keypadView.bounds.size;
        self.keypadView.frame = CGRectMake((w - keypadSize.width) / 2.0f, y, keypadSize.width, keypadSize.height);
        y += keypadSize.height;

        // Layout the container view
        self.pinView.frame = CGRectMake(0, 0, w, y);
        self.pinView.center = self.view.center;
        [self.view addSubview:self.pinView];

        [self clearPin];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self clearPin];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - KeypadView delegate

- (void)keypadView:(KeypadView *)keypadView numberPressed:(NSString *)str {
    if (self.pin.length < PIN_LENGTH) {
        self.pin = [self.pin stringByAppendingString:str];

        if (self.pin.length == PIN_LENGTH) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
                [self.delegate pinViewController:self pinEntered:self.pin];
            });
        }
    }
}

- (void)keypadViewDeletePressed:(KeypadView *)keypadView {
    NSInteger n = self.pin.length;
    if (n > 0) {
        self.pin = [self.pin substringToIndex:n - 1];
    }
}

- (void)keypadViewAlphaPressed:(KeypadView *)keypadView {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter your PIN to unlock", nil)
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alertView show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UITextField *textField = [alertView textFieldAtIndex:0];
    if (textField.text.length > 0) {
        [self clearPin];
        _pin = textField.text;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
            [self.delegate pinViewController:self pinEntered:self.pin];
        });
    }
}

#pragma mark - PIN related methods

- (void)setPin:(NSString *)pin {
    _pin = pin;

    NSMutableString *str = [NSMutableString string];

    NSInteger n = _pin.length;
    for (NSInteger i = 0; i < PIN_LENGTH; i++) {
        if (i < n) {
            [str appendString:@"\u25CF"];
        } else {
            [str appendString:@"\u25CB"];
        }

        if (i < (PIN_LENGTH - 1)) {
            [str appendString:@" "];
        }
    }
    self.pinLabel.text = str;
}

- (void)clearPin {
    self.pin = @"";
}

- (void)showPinKeypad:(BOOL)show {
    self.pinView.hidden = !show;
}

@end
