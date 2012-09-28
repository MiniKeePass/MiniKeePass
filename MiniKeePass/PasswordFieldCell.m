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

#import "PasswordFieldCell.h"
#import "AppSettings.h"

@implementation PasswordFieldCell

@synthesize accessoryButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        textField.secureTextEntry = [[AppSettings sharedInstance] hidePasswords];
        textField.font = [UIFont fontWithName:@"Andale Mono" size:16];
        textField.clearButtonMode = UITextFieldViewModeNever;
        
        UIImage *image = [UIImage imageNamed:@"wrench"];
        
        accessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        accessoryButton.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        [accessoryButton setImage:image forState:UIControlStateNormal];
        
        self.accessoryView = accessoryButton;
    }
    return self;
}

- (void)textFieldDidBeginEditing:(UITextField *)field {
    [super textFieldDidBeginEditing:field];
    
    textField.secureTextEntry = NO;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.returnKeyType = UIReturnKeyNext;
    
}

- (void)textFieldDidEndEditing:(UITextField *)field {
    [super textFieldDidEndEditing:field];
    
    textField.secureTextEntry = [[AppSettings sharedInstance] hidePasswords];
    textField.returnKeyType = UIReturnKeyDone;
}

@end
