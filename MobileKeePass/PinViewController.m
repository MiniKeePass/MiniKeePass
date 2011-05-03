//
//  PinViewController.m
//  MobileKeePass
//
//  Created by John on 5/3/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "PinViewController.h"
#import "PinTextField.h"

@implementation PinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    textField = [[UITextField alloc] initWithFrame:CGRectMake(320, 240, 0, 0)];
    textField.delegate = self;
    textField.hidden = YES;
    textField.secureTextEntry = YES;
    textField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:textField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
    
    PinTextField *pinTextField1 = [[PinTextField alloc] initWithFrame:CGRectMake(26, 117, 61, 53)];
    [self.view addSubview:pinTextField1];
    
    PinTextField *pinTextField2 = [[PinTextField alloc] initWithFrame:CGRectMake(95, 117, 61, 52)];
    [self.view addSubview:pinTextField2];
    
    PinTextField *pinTextField3 = [[PinTextField alloc] initWithFrame:CGRectMake(164, 117, 61, 53)];
    [self.view addSubview:pinTextField3];
    
    PinTextField *pinTextField4 = [[PinTextField alloc] initWithFrame:CGRectMake(233, 117, 61, 54)];
    [self.view addSubview:pinTextField4];
    
    pinTextFields = [[NSArray arrayWithObjects:pinTextField1, pinTextField2, pinTextField3, pinTextField4, nil] retain];
    
    [pinTextField1 release];
    [pinTextField2 release];
    [pinTextField3 release];
    [pinTextField4 release];
    
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, 320, 20)];
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.textAlignment = UITextAlignmentCenter;
    infoLabel.text = @"Enter your PIN to unlock";
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
        //FIXME CHECK PIN
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FULL" message:@"No More" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    }
}

@end
