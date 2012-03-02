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
        
        textField = [[UITextField alloc] initWithFrame:CGRectMake(320, 240, 0, 0)];
        textField.delegate = self;
        textField.hidden = YES;
        textField.secureTextEntry = YES;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.keyboardAppearance = UIKeyboardAppearanceAlert;
        [self.view addSubview:textField];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:textField];

        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 240, 96)];
        [toolbar setBarStyle:UIBarStyleBlackTranslucent];
        
        PinTextField *pinTextField1 = [[PinTextField alloc] initWithFrame:CGRectMake(23, 22, 61, 53)];
        [toolbar addSubview:pinTextField1];
        
        PinTextField *pinTextField2 = [[PinTextField alloc] initWithFrame:CGRectMake(94, 21, 61, 53)];
        [toolbar addSubview:pinTextField2];
      
        PinTextField *pinTextField3 = [[PinTextField alloc] initWithFrame:CGRectMake(165, 21, 61, 53)];
        [toolbar addSubview:pinTextField3];
      
        PinTextField *pinTextField4 = [[PinTextField alloc] initWithFrame:CGRectMake(236, 21, 61, 53)];
        [toolbar addSubview:pinTextField4];
      
        pinTextFields = [[NSArray arrayWithObjects:pinTextField1, pinTextField2, pinTextField3, pinTextField4, nil] retain];
        
        [pinTextField1 release];
        [pinTextField2 release];
        [pinTextField3 release];
        [pinTextField4 release];
        
        textField.inputAccessoryView = toolbar;
        [toolbar release];
        
        textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 95)];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
        textLabel.numberOfLines = 0;
        textLabel.textAlignment = UITextAlignmentCenter;
        textLabel.text = text;
        
        UIToolbar *topBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 95)];
        topBar.barStyle = UIBarStyleBlackTranslucent;
        [topBar addSubview:textLabel];
        
        [self.view addSubview:topBar];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self clearEntry];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:textField];
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
