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

#import "PasswordFieldCell.h"
#import "AppSettings.h"

@implementation PasswordFieldCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.textField.secureTextEntry = [[AppSettings sharedInstance] hidePasswords];
        self.textField.font = [UIFont fontWithName:@"Andale Mono" size:16];
        
        UIImage *accessoryImage = [UIImage imageNamed:@"eye"];
        UIImage *editAccessoryImage = [UIImage imageNamed:@"wrench"];
        
        self.accessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.accessoryButton.frame = CGRectMake(0.0, 0.0, 40, 40);
        [self.accessoryButton setImage:accessoryImage forState:UIControlStateNormal];

        self.editAccessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.editAccessoryButton.frame = CGRectMake(0.0, 0.0, 40, 40);
        [self.editAccessoryButton setImage:editAccessoryImage forState:UIControlStateNormal];

        self.accessoryView = self.accessoryButton;
        self.editingAccessoryView = self.editAccessoryButton;
    }
    return self;
}

- (void)textFieldDidBeginEditing:(UITextField *)field {
    [super textFieldDidBeginEditing:field];

    self.textField.secureTextEntry = NO;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.returnKeyType = UIReturnKeyNext;
}

- (void)textFieldDidEndEditing:(UITextField *)field {
    [super textFieldDidEndEditing:field];
    
    self.textField.secureTextEntry = [[AppSettings sharedInstance] hidePasswords];
    self.textField.returnKeyType = UIReturnKeyDone;
}

@end
