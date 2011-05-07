//
//  GroupViewController.h
//  MobileKeePass
//
//  Created by Jason Rush on 4/30/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface GroupViewController : UITableViewController {
    Group *group;
}

@property (nonatomic, assign) Group *group;

@end
