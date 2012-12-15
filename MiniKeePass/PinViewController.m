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

#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import "PinViewController.h"
#import "PinTextField.h"
#import "MiniKeePassAppDelegate.h"

#define PINTEXTFIELDWIDTH  61.0f
#define PINTEXTFIELDHEIGHT 52.0f
#define TEXTFIELDSPACE     10.0f

@interface PinViewController () {
    UITextField *textField;
    NSArray *pinTextFields;
    UIToolbar *topBar;
    UIToolbar *pinBar;
}
@end

@implementation PinViewController

- (id)init {
    return [self initWithText:NSLocalizedString(@"Enter your PIN to unlock", nil)];
}

- (id)initWithText:(NSString*)text {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor darkGrayColor];
        CGFloat frameWidth = CGRectGetWidth(self.view.frame);

        textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        textField.delegate = self;
        textField.hidden = YES;
        textField.secureTextEntry = YES;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.keyboardAppearance = UIKeyboardAppearanceAlert;
        [self.view addSubview:textField];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
        
        // Create topbar
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frameWidth, 95)];
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
        self.textLabel.numberOfLines = 0;
        self.textLabel.textAlignment = UITextAlignmentCenter;
        self.textLabel.text = text;
        
        topBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, frameWidth, 95)];
        topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        topBar.barStyle = UIBarStyleBlackTranslucent;

        [topBar addSubview:self.textLabel];

        [self.view addSubview:topBar];
        
        CGFloat textFieldViewWidth = PINTEXTFIELDWIDTH * 4 + TEXTFIELDSPACE * 3;
        
        UIView *textFieldsView = [[[UIView alloc] initWithFrame:CGRectMake((frameWidth - textFieldViewWidth) / 2, 22, textFieldViewWidth, PINTEXTFIELDHEIGHT)] autorelease];
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
        
        pinTextFields = [[NSArray arrayWithObjects:pinTextField1, pinTextField2, pinTextField3, pinTextField4, nil] retain];
        
        [pinTextField1 release];
        [pinTextField2 release];
        [pinTextField3 release];
        [pinTextField4 release];
        
        pinBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, frameWidth, 95)];
        pinBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [pinBar setBarStyle:UIBarStyleBlackTranslucent];
        [pinBar addSubview:textFieldsView];

        textField.inputAccessoryView = pinBar;

        // If the keyboard is dismissed, show it again.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [topBar release];
    [pinBar release];
    [textField release];
    [pinTextFields release];
    [_textLabel release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if ([self.delegate respondsToSelector:@selector(pinViewControllerShouldAutorotateToInterfaceOrientation:)]) {
        return [self.delegate pinViewControllerShouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    } else {
        return NO;
    }
}

- (void)resizeToolbarsToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    // Nothing needs to be done for the iPad; return
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) return;

    CGRect newFrame = topBar.frame;
    newFrame.size.height = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 95 : 68;

    topBar.frame = newFrame;
    self.textLabel.frame = newFrame;
    pinBar.frame = newFrame;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self resizeToolbarsToInterfaceOrientation:toInterfaceOrientation];
    }];
}

- (void)keyboardDidHide {
    // If the keyboard is dismissed, show it again.
    [self becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Required for 4.3 to show keyboard
    [self becomeFirstResponder];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if ([self shouldAutorotateToInterfaceOrientation:orientation]) {
        [self resizeToolbarsToInterfaceOrientation:orientation];
    }

    [self clearEntry];
}

- (void)viewDidAppear:(BOOL)animated {
    if ([self.delegate respondsToSelector:@selector(pinViewControllerDidShow:)]) {
        [self.delegate pinViewControllerDidShow:self];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)textField:(UITextField *)field shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([field.text length] >= 4 && range.length > 0) {
        return NO;
    } else {
        return YES;
    }
}

- (void)textDidChange:(NSNotification*)notification {
    NSUInteger n = [textField.text length];
    for (NSUInteger i = 0; i < 4; i++) {
        PinTextField *pinTextField = [pinTextFields objectAtIndex:i];
        if (i < n) {
            pinTextField.label.text = @"●";
        } else {
            pinTextField.label.text = @"";
        }
    }
    
    if ([textField.text length] == 4) {
        [self performSelector:@selector(checkPin:) withObject:nil afterDelay:0.3];
    }
}

- (void)checkPin:(id)sender {
    if ([self.delegate respondsToSelector:@selector(pinViewController:pinEntered:)]) {
        [self.delegate pinViewController:self pinEntered:textField.text];
    }
}

- (BOOL)becomeFirstResponder {
    [super becomeFirstResponder];
    
    return [textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    
    return [textField resignFirstResponder];
}

- (void)clearEntry {
    textField.text = @"";
    
    for (PinTextField *pinTextField in pinTextFields) {
        pinTextField.label.text = @"";
    }
}

@end
