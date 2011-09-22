//
//  DBSession.h
//  DropboxSDK
//
//  Created by Brian Smith on 4/8/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "MPOAuthCredentialConcreteStore.h"

extern NSString* kDBDropboxAPIHost;
extern NSString* kDBDropboxAPIContentHost;
extern NSString* kDBDropboxAPIVersion;

@protocol DBSessionDelegate;


/*  Creating and setting the shared DBSession should be done before any other Dropbox objects are
    used, perferrably in the UIApplication delegate. */
@interface DBSession : NSObject {
    MPOAuthCredentialConcreteStore* credentialStore;
    id<DBSessionDelegate> delegate;
}

+ (DBSession*)sharedSession;
+ (void)setSharedSession:(DBSession*)session;

- (id)initWithConsumerKey:(NSString*)key consumerSecret:(NSString*)secret;
- (BOOL)isLinked; // If not linked, you can only call loginWithEmail:password from the DBRestClient

- (void)updateAccessToken:(NSString*)token accessTokenSecret:(NSString*)secret;
- (void)unlink;

@property (nonatomic, readonly) MPOAuthCredentialConcreteStore* credentialStore;
@property (nonatomic, assign) id<DBSessionDelegate> delegate;

@end


@protocol DBSessionDelegate

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session;

@end
