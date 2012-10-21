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

- (BOOL) connect;

- (BOOL) hasLink;

- (BOOL) syncFrom: (NSString *) dbFile;


@end
