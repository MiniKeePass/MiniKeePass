//
//  TextFieldCell.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EntryViewController;

@interface TextFieldCell : UITableViewCell <UITextFieldDelegate, UIActionSheetDelegate> {
    EntryViewController *entryViewController;
    UILabel *label;
    UITextField *textField;
    UIGestureRecognizer *tapGesture;
}

@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) UITextField *textField;

- (id)initWithParent:(EntryViewController*)parent;
- (void)tapPressed;

@end
