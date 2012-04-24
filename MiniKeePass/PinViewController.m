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
#import "PinViewController.h"
#import "PinTextField.h"
#import "MiniKeePassAppDelegate.h"

@implementation PinViewController

@synthesize delegate;
@synthesize textLabel;

- (id)init {
    return [self initWithText:NSLocalizedString(@"Enter your PIN to unlock", nil)];
}

- (id)initWithText:(NSString*)text {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];        
        CGFloat screenWidth = [appDelegate currentScreenWidth];
        
        textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        textField.delegate = self;
        textField.hidden = YES;
        textField.secureTextEntry = YES;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.keyboardAppearance = UIKeyboardAppearanceAlert;
        [self.view addSubview:textField];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
        
        // Create topbar
        textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 95)];
        textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
        textLabel.numberOfLines = 0;
        textLabel.textAlignment = UITextAlignmentCenter;
        textLabel.text = text;
        
        UIToolbar *topBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 95)];
        topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        topBar.barStyle = UIBarStyleBlackTranslucent;
        [topBar addSubview:textLabel];
        
        [self.view addSubview:topBar];
        [topBar release];
        
        // Create PIN bar
        CGFloat pinTextFieldWidth = 61.0f;
        CGFloat pinTextFieldHeight = 52.0f;
        CGFloat textFieldSpace = 10.0f;
        
        CGFloat textFieldViewWidth = pinTextFieldWidth * 4 + textFieldSpace * 3;
        
        UIView *textFieldsView = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - textFieldViewWidth) / 2, 22, textFieldViewWidth, pinTextFieldHeight)];
        textFieldsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        CGFloat xOrigin = 0;
        
        PinTextField *pinTextField1 = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, pinTextFieldWidth, pinTextFieldHeight)];
        xOrigin += (pinTextFieldWidth + textFieldSpace);
        [textFieldsView addSubview:pinTextField1];
        
        PinTextField *pinTextField2 = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, pinTextFieldWidth, pinTextFieldHeight)];
        xOrigin += (pinTextFieldWidth + textFieldSpace);
        [textFieldsView addSubview:pinTextField2];
      
        PinTextField *pinTextField3 = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, pinTextFieldWidth, pinTextFieldHeight)];
        xOrigin += (pinTextFieldWidth + textFieldSpace);
        [textFieldsView addSubview:pinTextField3];
      
        PinTextField *pinTextField4 = [[PinTextField alloc] initWithFrame:CGRectMake(xOrigin, 0, pinTextFieldWidth, pinTextFieldHeight)];
        [textFieldsView addSubview:pinTextField4];
        
        pinTextFields = [[NSArray arrayWithObjects:pinTextField1, pinTextField2, pinTextField3, pinTextField4, nil] retain];
        
        [pinTextField1 release];
        [pinTextField2 release];
        [pinTextField3 release];
        [pinTextField4 release];
        
        UIToolbar *PINbar= [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 95)];
        PINbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [PINbar setBarStyle:UIBarStyleBlackTranslucent];
        [PINbar addSubview:textFieldsView];
      
        textField.inputAccessoryView = PINbar;
        [PINbar release];
        
        // If the keyboard is dismissed, show it again.
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(keyboardDidHide)
//                                                     name:UIKeyboardDidHideNotification
//                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [textField release];
    [pinTextFields release];
    [textLabel release];
    [delegate release];
    [super dealloc];
}

- (UIColor *)backgroundColor {
    return self.view.backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.view.backgroundColor = backgroundColor;
}

- (void)keyboardDidHide {
    // If the keyboard is dismissed, show it again.
    [self becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self clearEntry];
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
    if ([delegate respondsToSelector:@selector(pinViewController:pinEntered:)]) {
        [delegate pinViewController:self pinEntered:textField.text];
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
