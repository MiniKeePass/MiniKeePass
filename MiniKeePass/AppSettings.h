//
//  AppSettings.h
//  MiniKeePass
//
//  Created by Jason Rush on 9/28/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppSettings : NSObject

+ (AppSettings *)sharedInstance;

- (NSDate *)exitTime;
- (void)setExitTime:(NSDate *)exitTime;

- (BOOL)pinEnabled;
- (void)setPinEnabled:(BOOL)pinEnabled;

- (NSInteger)pinLockTimeout;
- (NSInteger)pinLockTimeoutIndex;
- (void)setPinLockTimeoutIndex:(NSInteger)pinLockTimeoutIndex;

- (NSInteger)pinFailedAttempts;
- (void)setPinFailedAttempts:(NSInteger)pinFailedAttempts;

- (BOOL)deleteOnFailureEnabled;
- (void)setDeleteOnFailureEnabled:(BOOL)deleteOnFailureEnabled;

- (NSInteger)deleteOnFailureAttempts;
- (NSInteger)deleteOnFailureAttemptsIndex;
- (void)setDeleteOnFailureAttemptsIndex:(NSInteger)deleteOnFailureAttemptsIndex;

- (BOOL)closeEnabled;
- (void)setCloseEnabled:(BOOL)closeEnabled;

- (NSInteger)closeTimeout;
- (NSInteger)closeTimeoutIndex;
- (void)setCloseTimeoutIndex:(NSInteger)closeTimeoutIndex;

- (BOOL)rememberPasswordsEnabled;
- (void)setRememberPasswordsEnabled:(BOOL)rememberPasswordsEnabled;

- (BOOL)hidePasswords;
- (void)setHidePasswords:(BOOL)hidePasswords;

- (NSString *)dropboxDirectory;

- (BOOL)sortAlphabetically;
- (void)setSortAlphabetically:(BOOL)sortAlphabetically;

- (NSStringEncoding)passwordEncoding;
- (NSInteger)passwordEncodingIndex;
- (void)setPasswordEncodingIndex:(NSInteger)passwordEncodingIndex;

- (BOOL)clearClipboardEnabled;
- (void)setClearClipboardEnabled:(BOOL)clearClipboardEnabled;

- (NSInteger)clearClipboardTimeout;
- (NSInteger)clearClipboardTimeoutIndex;
- (void)setClearClipboardTimeoutIndex:(NSInteger)clearClipboardTimeoutIndex;

- (NSInteger)pwGenLength;
- (void)setPwGenLength:(NSInteger)pwGenLength;

- (NSInteger)pwGenCharSets;
- (void)setPwGenCharSets:(NSInteger)pwGenCharSets;

@end
