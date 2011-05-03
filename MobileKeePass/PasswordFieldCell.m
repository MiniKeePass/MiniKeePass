//
//  PasswordFieldCell.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "PasswordFieldCell.h"

@implementation PasswordFieldCell

- (id)initWithParent:(UITableView *)parent {
    self = [super initWithParent:parent];
    if (self) {
        // Initialization code
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        textField.secureTextEntry = [userDefaults boolForKey:@"hidePasswords"];
        
        textField.returnKeyType = UIReturnKeyDone;
    }
    return self;
}

- (void)textFieldDidBeginEditing:(UITextField *)field {
    [super textFieldDidBeginEditing:field];
    
    textField.secureTextEntry = NO;
    textField.returnKeyType = UIReturnKeyDone;
}

- (void)textFieldDidEndEditing:(UITextField *)field {
    [super textFieldDidEndEditing:field];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    textField.secureTextEntry = [userDefaults boolForKey:@"hidePasswords"];
    
    textField.returnKeyType = UIReturnKeyDone;
}

@end
