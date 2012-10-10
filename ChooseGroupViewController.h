//
//  MoveItemsViewController.h
//  MiniKeePass
//
//  Created by John on 10/9/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "AutorotatingTableViewController.h"
#import "Kdb.h"

@protocol ChooseGroupDelegate;

@interface ChooseGroupViewController : AutorotatingTableViewController

@property (nonatomic, retain) KdbGroup *group;
@property (nonatomic, assign) id<ChooseGroupDelegate> delegate;

@end

@protocol ChooseGroupDelegate <NSObject>

- (BOOL)checkChoiceValidity:(KdbGroup *)chosenGroup success:(void (^)(void))success failure:(void (^)(NSString *errorMessage))failure;
- (void)chooseGroup:(KdbGroup *)chosenGroup;

@end