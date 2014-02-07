//
//  UIAlertViewAutoDismiss.m
//  MiniKeePass
//
//  Created by Jason Rush on 2/6/14.
//  Copyright (c) 2014 Self. All rights reserved.
//

#import "UIAlertViewAutoDismiss.h"

@implementation UIAlertViewAutoDismiss

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidEnterBackground:(id)sender {
    [self dismissWithClickedButtonIndex:self.cancelButtonIndex animated:NO];
}

@end
