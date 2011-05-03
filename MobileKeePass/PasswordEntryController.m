//
//  PasswordEntryController.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "PasswordEntryController.h"

#define SPACER 8
#define LABEL_FIELD_HEIGHT 21
#define TEXT_FIELD_HEIGHT 31
#define BUTTON_HEIGHT 37
#define BUTTON_WIDTH (140 - SPACER / 2)

@implementation PasswordEntryController

@synthesize passwordTextField;
@synthesize statusLabel;
@synthesize delegate;

- (void)viewDidLoad {
    int y = 20;
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 280, LABEL_FIELD_HEIGHT)];
    label.text = @"Password:";
    label.textColor = [UIColor darkTextColor];
    label.backgroundColor = [UIColor clearColor];
    [self.view addSubview:label];
    [label release];
    y += LABEL_FIELD_HEIGHT + SPACER;
    
    passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, y, 280, TEXT_FIELD_HEIGHT)];
    passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    passwordTextField.secureTextEntry = YES;
    passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    passwordTextField.returnKeyType = UIReturnKeyDone;
    passwordTextField.delegate = self;
    [self.view addSubview:passwordTextField];
    y += TEXT_FIELD_HEIGHT + SPACER;
    
    okButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    okButton.frame = CGRectMake(20, y, BUTTON_WIDTH, BUTTON_HEIGHT);
    [okButton setTitle:@"OK" forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(okPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:okButton];
    
    cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cancelButton.frame = CGRectMake(20 + BUTTON_WIDTH + SPACER, y, BUTTON_WIDTH, BUTTON_HEIGHT);
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
    y += BUTTON_HEIGHT + SPACER;
    
    statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 280, LABEL_FIELD_HEIGHT)];
    statusLabel.textColor = [UIColor redColor];
    statusLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:statusLabel];
    y += LABEL_FIELD_HEIGHT + SPACER;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    passwordTextField.text = @"";
    statusLabel.text = @"";
    
    [passwordTextField becomeFirstResponder];
}

- (void)dealloc {
    [passwordTextField release];
    [statusLabel release];
    [super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self okPressed];
    return YES;
}

- (void)okPressed {
    BOOL shouldDismiss = YES;
    
    if ([delegate respondsToSelector:@selector(passwordEntryController:passwordEntered:)]) {
        shouldDismiss = [delegate passwordEntryController:self passwordEntered:passwordTextField.text];
    }
    
    if (shouldDismiss) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)cancelPressed {
    [self dismissModalViewControllerAnimated:YES];
}

@end
