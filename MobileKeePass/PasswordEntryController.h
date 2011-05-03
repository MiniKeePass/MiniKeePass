//
//  PasswordEntryController.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PasswordEntryControllerDelegate;

@interface PasswordEntryController : UIViewController <UITextFieldDelegate> {
    UITextField *passwordTextField;
    UIButton *okButton;
    UIButton *cancelButton;
    UILabel *statusLabel;
    id<PasswordEntryControllerDelegate> delegate;
}

@property (nonatomic, retain) UITextField *passwordTextField;
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) id<PasswordEntryControllerDelegate> delegate;

- (void)okPressed;
- (void)cancelPressed;

@end

@protocol PasswordEntryControllerDelegate <NSObject>
- (BOOL)passwordEntryController:(PasswordEntryController*)controller passwordEntered:(NSString*)password;
@end
