//
//  PinViewController.h
//  MobileKeePass
//
//  Created by John on 5/3/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PinViewController : UIViewController <UITextFieldDelegate> {
    UITextField *textField;
    NSArray *pinTextFields;
    UILabel *infoLabel;
}

@end
