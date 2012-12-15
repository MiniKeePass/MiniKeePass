//
//  CreateCustomLabelViewController.h
//  MiniKeePass
//
//  Created by John on 12/15/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CreateCustomLabelViewControllerDelegate;

@interface CreateCustomLabelViewController : UITableViewController <UITextFieldDelegate>
@property (nonatomic, assign) id<CreateCustomLabelViewControllerDelegate> delegate;
@end

@protocol CreateCustomLabelViewControllerDelegate <NSObject>
- (void)createCustomLabelViewController:(CreateCustomLabelViewController *)controller createdLabel:(NSString *)string;
@end