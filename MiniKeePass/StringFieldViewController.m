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

#import "StringFieldViewController.h"

@implementation StringFieldViewController

- (id)initWithStringField:(StringField *)stringField {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _stringField = [stringField retain];

        self.title = NSLocalizedString(@"Custom Field", nil);

        _keyTextField = [[UITextField alloc] init];
        _keyTextField.placeholder = NSLocalizedString(@"Name", nil);
        _keyTextField.returnKeyType = UIReturnKeyNext;
        _keyTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _keyTextField.delegate = self;
        _keyTextField.text = stringField.key;

        _valueTextField = [[UITextField alloc] init];
        _valueTextField.placeholder = NSLocalizedString(@"Value", nil);
        _valueTextField.returnKeyType = UIReturnKeyDone;
        _valueTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _valueTextField.delegate = self;
        _valueTextField.text = stringField.value;

        _protectedSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"In Memory Protection", nil)];
        _protectedSwitchCell.switchControl.on = stringField.protected;

        self.controls = @[_keyTextField, _valueTextField, _protectedSwitchCell];
        self.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [_stringField release];
    [_keyTextField release];
    [_valueTextField release];
    [_protectedSwitchCell release];
    [_object release];
    [_stringFieldViewDelegate release];
    [super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _keyTextField) {
        [_valueTextField becomeFirstResponder];
    } else if (textField == _valueTextField) {
        [self okPressed:nil];
    }

    return YES;
}

- (void)okPressed:(id)sender {
    if (self.keyTextField.text.length == 0) {
        NSString *title = NSLocalizedString(@"Name cannot be empty", nil);
        NSString *ok = NSLocalizedString(@"Ok", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:ok otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }

    [super okPressed:sender];
}

- (void)formViewController:(FormViewController *)controller button:(FormViewControllerButton)button {
    if (button == FormViewControllerButtonOk) {
        _stringField.key = _keyTextField.text;
        _stringField.value = _valueTextField.text;
        _stringField.protected = _protectedSwitchCell.switchControl.on;

        if ([_stringFieldViewDelegate respondsToSelector:@selector(stringFieldViewController:updateStringField:)]) {
            [_stringFieldViewDelegate stringFieldViewController:self updateStringField:_stringField];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
