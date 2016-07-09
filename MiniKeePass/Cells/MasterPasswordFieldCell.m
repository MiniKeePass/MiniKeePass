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

#import "MasterPasswordFieldCell.h"

@implementation MasterPasswordFieldCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.textField.frame = CGRectMake(15, 0, self.contentView.bounds.size.width - 15, self.contentView.bounds.size.height);
        self.textField.placeholder = NSLocalizedString(@"Password", nil);
        self.textField.secureTextEntry = YES;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.returnKeyType = UIReturnKeyDone;
        self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.textField.font = [UIFont fontWithName:@"Andale Mono" size:16];

        self.accessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.accessoryButton.frame = CGRectMake(0.0, 0.0, 40, 40);
        [self.accessoryButton setImage:[UIImage imageNamed:@"eye"] forState:UIControlStateNormal];
        [self.accessoryButton addTarget:self action:@selector(togglePasswordVisible) forControlEvents:UIControlEventTouchUpInside];

        self.accessoryView = self.accessoryButton;
    }
    return self;
}

- (void)togglePasswordVisible {
    if (self.textField.secureTextEntry) {
        self.textField.secureTextEntry = NO;

        [self.accessoryButton setImage:[UIImage imageNamed:@"eye-slash"] forState:UIControlStateNormal];
    } else {
        BOOL wasFirstResponder = [self.textField isFirstResponder];
        self.textField.enabled = NO;
        self.textField.secureTextEntry = YES;
        self.textField.enabled = YES;
        self.textField.returnKeyType = UIReturnKeyDone;
        if (wasFirstResponder) {
            [self.textField becomeFirstResponder];
        }

        [self.accessoryButton setImage:[UIImage imageNamed:@"eye"] forState:UIControlStateNormal];
    }
}

@end
