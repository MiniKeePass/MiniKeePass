//
//  StringFieldViewController.h
//  MiniKeePass
//
//  Created by Jason Rush on 12/16/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "FormViewController.h"
#import "Kdb4Node.h"
#import "SwitchCell.h"

@protocol StringFieldViewDelegate;

@interface StringFieldViewController : FormViewController <FormViewControllerDelegate>

@property (nonatomic, retain) StringField *stringField;
@property (nonatomic, readonly) UITextField *keyTextField;
@property (nonatomic, readonly) UITextField *valueTextField;
@property (nonatomic, readonly) SwitchCell *protectedSwitchCell;

@property (nonatomic, retain) id object;
@property (nonatomic, retain) id<StringFieldViewDelegate> stringFieldViewDelegate;

- (id)initWithStringField:(StringField *)stringField;

@end

@protocol StringFieldViewDelegate <NSObject>
- (void)stringFieldViewController:(StringFieldViewController *)controller
                updateStringField:(StringField *)stringField;
@end
