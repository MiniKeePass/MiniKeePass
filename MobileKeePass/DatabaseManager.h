//
//  DatabaseManager.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/9/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PasswordEntryController.h"

@interface DatabaseManager : NSObject <PasswordEntryControllerDelegate> {
    NSString *selectedPath;
    BOOL animated;
}

@property (nonatomic, retain) NSString *selectedPath;
@property (nonatomic) BOOL animated;

+ (DatabaseManager*)sharedInstance;
- (void)openDatabaseDocument:(NSString*)path animated:(BOOL)newAnimated;

@end
