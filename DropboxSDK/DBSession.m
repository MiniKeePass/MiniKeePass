//
//  DBSession.m
//  DropboxSDK
//
//  Created by Brian Smith on 4/8/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBSession.h"
#import "MPOAuthCredentialConcreteStore.h"
#import "MPOAuthSignatureParameter.h"


NSString* kDBDropboxAPIHost = @"api.dropbox.com";
NSString* kDBDropboxAPIContentHost = @"api-content.dropbox.com";
NSString* kDBDropboxAPIVersion = @"0";

static DBSession* _sharedSession = nil;
static NSString* kDBDropboxSavedCredentialsKey = @"kDBDropboxSavedCredentialsKey";


@interface DBSession ()

- (NSDictionary*)savedCredentials;
- (void)saveCredentials:(NSDictionary*)credentials;
- (void)clearSavedCredentials;

@end


@implementation DBSession

+ (DBSession*)sharedSession {
    return _sharedSession;
}

+ (void)setSharedSession:(DBSession*)session {
    if (session == _sharedSession) return;
    [_sharedSession release];
    _sharedSession = [session retain];
}

- (id)initWithConsumerKey:(NSString*)key consumerSecret:(NSString*)secret {
    if ((self = [super init])) {
        
        NSMutableDictionary* credentials = 
            [NSMutableDictionary dictionaryWithObjectsAndKeys:
                key, kMPOAuthCredentialConsumerKey,
                secret, kMPOAuthCredentialConsumerSecret, 
                kMPOAuthSignatureMethodHMACSHA1, kMPOAuthSignatureMethod, nil];
        
        NSDictionary* savedCredentials = [self savedCredentials];
        if (savedCredentials != nil) {
            if ([key isEqualToString:[savedCredentials objectForKey:kMPOAuthCredentialConsumerKey]]) {
                
                [credentials setObject:[savedCredentials objectForKey:kMPOAuthCredentialAccessToken] 
                    forKey:kMPOAuthCredentialAccessToken];
                [credentials setObject:[savedCredentials objectForKey:kMPOAuthCredentialAccessTokenSecret] 
                    forKey:kMPOAuthCredentialAccessTokenSecret];
            } else {
                [self clearSavedCredentials];
            }
        }
        
        credentialStore = [[MPOAuthCredentialConcreteStore alloc] initWithCredentials:credentials];
    }
    return self;
}

- (void)dealloc {
    [credentialStore release];
    [super dealloc];
}

@synthesize credentialStore;
@synthesize delegate;

- (void)updateAccessToken:(NSString*)token accessTokenSecret:(NSString*)secret {
    credentialStore.accessToken = token;
    credentialStore.accessTokenSecret = secret;
    NSDictionary* credentials = [NSDictionary dictionaryWithObjectsAndKeys:
        credentialStore.consumerKey, kMPOAuthCredentialConsumerKey,
        credentialStore.accessToken, kMPOAuthCredentialAccessToken,
        credentialStore.accessTokenSecret, kMPOAuthCredentialAccessTokenSecret,
        nil];
    [self saveCredentials:credentials];
}

- (BOOL) isLinked {
    return credentialStore.accessToken != nil;
}

- (void)unlink {
    credentialStore.accessToken = nil;
    credentialStore.accessTokenSecret = nil;
    [self clearSavedCredentials];
}

#pragma mark private methods

- (NSDictionary*)savedCredentials {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kDBDropboxSavedCredentialsKey];
}

- (void)saveCredentials:(NSDictionary*)credentials {
    if (credentials == nil) return;
    
    [[NSUserDefaults standardUserDefaults] 
            setObject:credentials forKey:kDBDropboxSavedCredentialsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearSavedCredentials {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDBDropboxSavedCredentialsKey];
}

@end
