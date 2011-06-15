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

#import "TextEntryController.h"

@implementation TextEntryController

@synthesize textField;
@synthesize textEntryDelegate;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.delegate = self;
        
        textField = [[UITextField alloc] init];
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyDone;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.controls = [NSArray arrayWithObject:textField];
    }
    return self;
}

- (void)dealloc {
    [textField release];
    [textEntryDelegate release];
    [super dealloc];
}

- (void)formViewController:(FormViewController *)controller button:(FormViewControllerButton)button {
    if (button == FormViewControllerButtonOk) {
        if ([textEntryDelegate respondsToSelector:@selector(textEntryController:textEntered:)]) {
            [textEntryDelegate textEntryController:self textEntered:textField.text];
        }
    } else {
        if ([textEntryDelegate respondsToSelector:@selector(textEntryControllerCancelButtonPressed:)]) {
            [textEntryDelegate textEntryControllerCancelButtonPressed:self];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self formViewController:self button:FormViewControllerButtonOk];
    return YES;
}

@end
