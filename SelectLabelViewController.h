//
//  SelectLabelViewController.h
//  MiniKeePass
//
//  Created by John on 12/15/12.
//  Copyright (c) 2012 Self. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "AutorotatingTableViewController.h"

#import "CreateCustomLabelViewController.h"

@protocol SelectLabelViewControllerDelegate;

@interface SelectLabelViewController : AutorotatingTableViewController <CreateCustomLabelViewControllerDelegate>

- (void) setCurrentLabel:(NSString *)currentLabel;

@property (nonatomic, retain) id object;
@property (nonatomic, assign) id<SelectLabelViewControllerDelegate> delegate;

@end

@protocol SelectLabelViewControllerDelegate <NSObject>
- (void)selectionLabelViewController:(SelectLabelViewController *)controller selectedLabel:(NSString *)label forObject:(id)object;
@end