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

#import "PasswordGeneratorViewController.h"
#import "Salsa20RandomStream.h"

#define CHARSET_LOWER_CASE @"abcdefghijklmnopqrstuvwxyz"
#define CHARSET_UPPER_CASE @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define CHARSET_DIGITS     @"0123456789"
#define CHARSET_SPECIAL    @"!@#$%^&*_-+=?"
#define CHARSET_BRACKETS   @"(){}[]<>"

@implementation PasswordGeneratorViewController

@synthesize passwordTextField;

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        UIPickerView *lengthPickerView = [[UIPickerView alloc] init];
        lengthPickerView.delegate = self;
        lengthPickerView.dataSource = self;
        lengthPickerView.showsSelectionIndicator = YES;
        
        lengthCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        lengthCell.textLabel.text = @"Character Sets";
        lengthCell.detailTextLabel.text = @"Upper, Lower, Digits, Minus, Underline, Space, Special, Brackets";
        lengthCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        lowerCaseSwitchCell = [[SwitchCell alloc] initWithLabel:@"Lower Case"];
        lowerCaseSwitchCell.switchControl.on = YES;
        
        upperCaseSwitchCell = [[SwitchCell alloc] initWithLabel:@"Upper Case"];
        upperCaseSwitchCell.switchControl.on = YES;
        
        digitsSwitchCell = [[SwitchCell alloc] initWithLabel:@"Digits"];
        digitsSwitchCell.switchControl.on = YES;
        
        specialSwitchCell = [[SwitchCell alloc] initWithLabel:@"Special"];
        
        bracketsSwitchCell = [[SwitchCell alloc] initWithLabel:@"Brackets"];
        
        passwordTextField = [[UITextField alloc] init];
        
        self.controls = [NSArray arrayWithObjects:lengthCell, lowerCaseSwitchCell, upperCaseSwitchCell, digitsSwitchCell, specialSwitchCell, bracketsSwitchCell, passwordTextField, nil];
    }
    return self;
}

- (void)dealloc {
    [lengthCell release];
    [lowerCaseSwitchCell release];
    [upperCaseSwitchCell release];
    [digitsSwitchCell release];
    [specialSwitchCell release];
    [bracketsSwitchCell release];
    [passwordTextField release];
    [super dealloc];
}

- (void)generate {
    NSMutableString *charSet = [NSMutableString string];
    if (lowerCaseSwitchCell.switchControl.on) {
        [charSet appendString:CHARSET_LOWER_CASE];
    }
    if (upperCaseSwitchCell.switchControl.on) {
        [charSet appendString:CHARSET_UPPER_CASE];
    }
    if (digitsSwitchCell.switchControl.on) {
        [charSet appendString:CHARSET_DIGITS];
    }
    if (specialSwitchCell.switchControl.on) {
        [charSet appendString:CHARSET_SPECIAL];
    }
    if (bracketsSwitchCell.switchControl.on) {
        [charSet appendString:CHARSET_BRACKETS];
    }
    
    RandomStream *cryptoRandomStream = [[Salsa20RandomStream alloc] init];
    
    NSInteger length = [lengthCell.detailTextLabel.text integerValue];
    NSMutableString *password = [NSMutableString string];
    for (NSUInteger i = 0; i < length; i++) {
        NSUInteger idx = [cryptoRandomStream getInt] % [charSet length];
        [password appendString:[charSet substringWithRange:NSMakeRange(idx, 1)]];
    }
    
    [cryptoRandomStream release];
    
    passwordTextField.text = password;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 99;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[NSNumber numberWithInteger:row] stringValue];
}

@end
