//
//  PinViewController.h
//  MobileKeePass
//
//  Created by John on 5/3/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PinViewControllerDelegate;

@interface PinViewController : UIViewController <UITextFieldDelegate> {
    UITextField *textField;
    NSArray *pinTextFields;
    UILabel *infoLabel;
    NSString *string;
    id<PinViewControllerDelegate> delegate;
}

- (id)initWithText:(NSString*)text;
- (void)clearEntry;

@property (nonatomic, retain) id<PinViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *string;

@end

@protocol PinViewControllerDelegate <NSObject>
- (void)pinViewController:(PinViewController*)controller pinEntered:(NSString*)pin;
- (void)pinViewControllerCancelButtonPressed:(PinViewController*)controller;
@end
