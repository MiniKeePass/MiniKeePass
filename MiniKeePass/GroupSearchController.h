//
//  GroupSearchController.h
//  MiniKeePass
//
//  Created by John on 12/23/13.
//  Copyright (c) 2013 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KdbLib.h"
#import "GroupViewController.h"

@interface GroupSearchController : NSObject <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic, weak) GroupViewController *groupViewController;

@end
