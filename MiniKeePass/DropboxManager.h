//
//  DropboxManager.h
//  MiniKeePass
//
//  Created by Albert Choy on 10/12/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DropboxManager : NSObject 
{
    NSString *relinkUserId;
}

@property (nonatomic, retain) UIViewController *rootController;
@property (nonatomic, copy) NSString *syncVersion;
@property (nonatomic, copy) NSString *cloudVersion;
@property (nonatomic, copy) NSString *localDb;

+ (DropboxManager *) singleton;

- (BOOL) activateLink: (UIViewController *) viewController;

// Connect to Dropbox
- (BOOL) connect;

// Has link to Dropbox user account
- (BOOL) hasLink;

// Sync from Dropbox file, initiatize database load
- (BOOL) syncFrom: (NSString *) dbFile;

// Sync to Dropbox file
- (BOOL) syncToDropbox;


@end
