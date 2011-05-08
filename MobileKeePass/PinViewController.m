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
@synthesize string;

- (id)init {
    return [self initWithText:@"Enter your PIN to unlock"];
}

- (id)initWithText:(NSString*)text {
    [super init];
    if (self) {
        string = text;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

    UIImage *icon = [UIImage imageNamed:@"icon"];
    UIView *iconView = [[UIView alloc] initWithFrame:CGRectMake(131, 20, icon.size.width,icon.size.height)];
    iconView.backgroundColor = [UIColor colorWithPatternImage:icon];
    [self.view addSubview:iconView];
    [iconView release];
    
    UIButton *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarStyleBlack target:self action:@selector(cancelButtonPressed:)];

    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.translucent = YES;    
    toolbar.items = [NSArray arrayWithObject:cancelButton];
    [cancelButton release];

    textField = [[UITextField alloc] initWithFrame:CGRectMake(320, 240, 0, 0)];
    textField.delegate = self;
    textField.hidden = YES;
    textField.secureTextEntry = YES;
    textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    textField.inputAccessoryView = toolbar;
    [toolbar release];
    
    [self.view addSubview:textField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
    
    PinTextField *pinTextField1 = [[PinTextField alloc] initWithFrame:CGRectMake(26, 100, 61, 53)];
    [self.view addSubview:pinTextField1];
    
    PinTextField *pinTextField2 = [[PinTextField alloc] initWithFrame:CGRectMake(95, 100, 61, 52)];
    [self.view addSubview:pinTextField2];
    
    PinTextField *pinTextField3 = [[PinTextField alloc] initWithFrame:CGRectMake(164, 100, 61, 53)];
    [self.view addSubview:pinTextField3];
    
    PinTextField *pinTextField4 = [[PinTextField alloc] initWithFrame:CGRectMake(233, 100, 61, 54)];
    [self.view addSubview:pinTextField4];
    
    pinTextFields = [[NSArray arrayWithObjects:pinTextField1, pinTextField2, pinTextField3, pinTextField4, nil] retain];
    
    [pinTextField1 release];
    [pinTextField2 release];
    [pinTextField3 release];
    [pinTextField4 release];
    
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 165, 320, 20)];
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.textAlignment = UITextAlignmentCenter;
    infoLabel.text = string;
    [self.view addSubview:infoLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    textField.text = @"";
    
    for (PinTextField *pinTextField in pinTextFields) {
        pinTextField.label.text = @"";
    }
    
    [textField becomeFirstResponder];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:textField];
}

- (void)dealloc {
    [textField release];
    [pinTextFields release];
    [infoLabel release];
    [super dealloc];
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
 
- (void)cancelButtonPressed:(id)sender {
    if ([delegate respondsToSelector:@selector(pinViewControllerCancelButtonPressed:)]) {
        [delegate pinViewControllerCancelButtonPressed:self];
    }
}

- (void)clearEntry {
    textField.text = @"";
}

- (void)setString:(NSString *)inString {
    string = inString;
    infoLabel.text = string;
}

@end
