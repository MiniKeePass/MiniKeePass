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
    id<PinViewControllerDelegate> delegate;
}

@property (nonatomic, retain) id<PinViewControllerDelegate> delegate;

@end

@protocol PinViewControllerDelegate <NSObject>
- (BOOL)pinViewController:(PinViewController*)controller checkPin:(NSString*)pin;
@end
