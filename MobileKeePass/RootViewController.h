//
//  RootViewController.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupViewController.h"
#import "FileViewController.h"

@interface RootViewController : GroupViewController {
    FileViewController *fileViewController;
}

- (void)openPressed:(id)sender;

@end
