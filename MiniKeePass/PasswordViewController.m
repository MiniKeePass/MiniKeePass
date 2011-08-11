//
//  PasswordViewController.m
//  MiniKeePass
//
//  Created by Jason Rush on 8/11/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "PasswordViewController.h"

@implementation PasswordViewController

@synthesize passwordTextField;
@synthesize keyFileTextField;

- (id)initWithFilename:(NSString*)filename {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Password";
        self.headerTitle = @"Password";
        self.footerTitle = [NSString stringWithFormat:@"Enter the password for the %@ database.", filename];
        
        passwordTextField = [[UITextField alloc] init];
        passwordTextField.placeholder = @"Password";
        passwordTextField.secureTextEntry = YES;
        passwordTextField.returnKeyType = UIReturnKeyDone;
        passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        keyFileTextField = [[UITextField alloc] init];
        keyFileTextField.placeholder = @"Keyfile";
        keyFileTextField.returnKeyType = UIReturnKeyDone;
        keyFileTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.controls = [NSArray arrayWithObjects:passwordTextField, keyFileTextField, nil];
    }
    return self;
}

- (void)dealloc {
    [passwordTextField release];
    [keyFileTextField release];
    [super dealloc];
}

@end
