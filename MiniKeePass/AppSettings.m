/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "AppSettings.h"
#import "CharacterSetsViewController.h"

#define EXIT_TIME                  @"exitTime"
#define PIN_ENABLED                @"pinEnabled"
#define PIN_LOCK_TIMEOUT           @"pinLockTimeout"
#define PIN_FAILED_ATTEMPTS        @"pinFailedAttempts"
#define DELETE_ON_FAILURE_ENABLED  @"deleteOnFailureEnabled"
#define DELETE_ON_FAILURE_ATTEMPTS @"deleteOnFailureAttempts"
#define CLOSE_ENABLED              @"closeEnabled"
#define CLOSE_TIMEOUT              @"closeTimeout"
#define REMEMBER_PASSWORDS_ENABLED @"rememberPasswordsEnabled"
#define HIDE_PASSWORDS             @"hidePasswords"
#define SORT_ALPHABETICALLY        @"sortAlphabetically"
#define PASSWORD_ENCODING          @"passwordEncoding"
#define CLEAR_CLIPBOARD_ENABLED    @"clearClipboardEnabled"
#define CLEAR_CLIPBOARD_TIMEOUT    @"clearClipboardTimeout"
#define PW_GEN_LENGTH              @"pwGenLength"
#define PW_GEN_CHAR_SETS           @"pwGenCharSets"

@interface AppSettings () {
    NSUserDefaults *userDefaults;
}
@end

@implementation AppSettings

static NSInteger pinLockTimeoutValues[] = {
    0,
    30,
    60,
    120,
    300
};

static NSInteger deleteOnFailureAttemptsValues[] = {
    3,
    5,
    10,
    15
};

static NSInteger closeTimeoutValues[] = {
    0,
    30,
    60,
    120,
    300
};

static NSInteger clearClipboardTimeoutValues[] = {
    30,
    60,
    120,
    180
};

static NSStringEncoding passwordEncodingValues[] = {
    NSUTF8StringEncoding,
    NSUTF16BigEndianStringEncoding,
    NSUTF16LittleEndianStringEncoding,
    NSISOLatin1StringEncoding,
    NSISOLatin2StringEncoding,
    NSASCIIStringEncoding,
    NSJapaneseEUCStringEncoding,
    NSISO2022JPStringEncoding
};

static AppSettings *sharedInstance;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[AppSettings alloc] init];
    }
}

+ (AppSettings *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        userDefaults = [NSUserDefaults standardUserDefaults];

        // Register the default values
        NSMutableDictionary *defaultsDict = [NSMutableDictionary dictionary];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:PIN_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:1] forKey:PIN_LOCK_TIMEOUT];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:DELETE_ON_FAILURE_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:1] forKey:DELETE_ON_FAILURE_ATTEMPTS];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:CLOSE_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:4] forKey:CLOSE_TIMEOUT];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:REMEMBER_PASSWORDS_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:HIDE_PASSWORDS];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:SORT_ALPHABETICALLY];
        [defaultsDict setValue:[NSNumber numberWithInt:0] forKey:PASSWORD_ENCODING];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:CLEAR_CLIPBOARD_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:NO] forKey:CLEAR_CLIPBOARD_TIMEOUT];
        [defaultsDict setValue:[NSNumber numberWithInt:10] forKey:PW_GEN_LENGTH];
        [defaultsDict setValue:[NSNumber numberWithInt:CHARACTER_SET_DEFAULT] forKey:PW_GEN_CHAR_SETS];
        [userDefaults registerDefaults:defaultsDict];
    }
    return self;
}

- (NSDate *)exitTime {
    return [userDefaults valueForKey:EXIT_TIME];
}

- (void)setExitTime:(NSDate *)exitTime {
    [userDefaults setValue:exitTime forKey:EXIT_TIME];
}

- (BOOL)pinEnabled {
    return [userDefaults boolForKey:PIN_ENABLED];
}

- (void)setPinEnabled:(BOOL)pinEnabled {
    [userDefaults setBool:pinEnabled forKey:PIN_ENABLED];
}

- (NSInteger)pinLockTimeout {
    return pinLockTimeoutValues[[userDefaults integerForKey:PIN_LOCK_TIMEOUT]];
}

- (NSInteger)pinLockTimeoutIndex {
    return [userDefaults integerForKey:PIN_LOCK_TIMEOUT];
}

- (void)setPinLockTimeoutIndex:(NSInteger)pinLockTimeoutIndex {
    [userDefaults setInteger:pinLockTimeoutIndex forKey:PIN_LOCK_TIMEOUT];
}

- (NSInteger)pinFailedAttempts {
    return [userDefaults integerForKey:PIN_FAILED_ATTEMPTS];
}

- (void)setPinFailedAttempts:(NSInteger)pinFailedAttempts {
    [userDefaults setInteger:pinFailedAttempts forKey:PIN_FAILED_ATTEMPTS];
}

- (BOOL)deleteOnFailureEnabled {
    return [userDefaults boolForKey:DELETE_ON_FAILURE_ENABLED];
}

- (void)setDeleteOnFailureEnabled:(BOOL)deleteOnFailureEnabled {
    [userDefaults setBool:deleteOnFailureEnabled forKey:DELETE_ON_FAILURE_ENABLED];
}

- (NSInteger)deleteOnFailureAttempts {
    return deleteOnFailureAttemptsValues[[userDefaults integerForKey:DELETE_ON_FAILURE_ATTEMPTS]];
}

- (NSInteger)deleteOnFailureAttemptsIndex {
    return [userDefaults integerForKey:DELETE_ON_FAILURE_ATTEMPTS];
}

- (void)setDeleteOnFailureAttemptsIndex:(NSInteger)deleteOnFailureAttemptsIndex {
    [userDefaults setInteger:deleteOnFailureAttemptsIndex forKey:DELETE_ON_FAILURE_ATTEMPTS];
}

- (BOOL)closeEnabled {
    return [userDefaults boolForKey:CLOSE_ENABLED];
}

- (void)setCloseEnabled:(BOOL)closeEnabled {
    [userDefaults setBool:closeEnabled forKey:CLOSE_ENABLED];
}

- (NSInteger)closeTimeout {
    return closeTimeoutValues[[userDefaults integerForKey:CLOSE_TIMEOUT]];
}

- (NSInteger)closeTimeoutIndex {
    return [userDefaults integerForKey:CLOSE_TIMEOUT];
}

- (void)setCloseTimeoutIndex:(NSInteger)closeTimeoutIndex {
    [userDefaults setInteger:closeTimeoutIndex forKey:CLOSE_TIMEOUT];
}

- (BOOL)rememberPasswordsEnabled {
    return [userDefaults boolForKey:REMEMBER_PASSWORDS_ENABLED];
}

- (void)setRememberPasswordsEnabled:(BOOL)rememberPasswordsEnabled {
    [userDefaults setBool:rememberPasswordsEnabled forKey:REMEMBER_PASSWORDS_ENABLED];
}

- (BOOL)hidePasswords {
    return [userDefaults boolForKey:HIDE_PASSWORDS];
}

- (void)setHidePasswords:(BOOL)hidePasswords {
    [userDefaults setBool:hidePasswords forKey:HIDE_PASSWORDS];
}

- (BOOL)sortAlphabetically {
    return [userDefaults boolForKey:SORT_ALPHABETICALLY];
}

- (void)setSortAlphabetically:(BOOL)sortAlphabetically {
    [userDefaults setBool:sortAlphabetically forKey:SORT_ALPHABETICALLY];
}

- (NSStringEncoding)passwordEncoding {
    return passwordEncodingValues[[userDefaults integerForKey:PASSWORD_ENCODING]];
}

- (NSInteger)passwordEncodingIndex {
    return [userDefaults integerForKey:PASSWORD_ENCODING];
}

- (void)setPasswordEncodingIndex:(NSInteger)passwordEncodingIndex {
    [userDefaults setInteger:passwordEncodingIndex forKey:PASSWORD_ENCODING];
}

- (BOOL)clearClipboardEnabled {
    return [userDefaults boolForKey:CLEAR_CLIPBOARD_ENABLED];
}

- (void)setClearClipboardEnabled:(BOOL)clearClipboardEnabled {
    [userDefaults setBool:clearClipboardEnabled forKey:CLEAR_CLIPBOARD_ENABLED];
}

- (NSInteger)clearClipboardTimeout {
    return clearClipboardTimeoutValues[[userDefaults integerForKey:CLEAR_CLIPBOARD_TIMEOUT]];
}

- (NSInteger)clearClipboardTimeoutIndex {
    return [userDefaults integerForKey:CLEAR_CLIPBOARD_TIMEOUT];
}

- (void)setClearClipboardTimeoutIndex:(NSInteger)clearClipboardTimeoutIndex {
    [userDefaults setInteger:clearClipboardTimeoutIndex forKey:CLEAR_CLIPBOARD_TIMEOUT];
}

- (NSInteger)pwGenLength {
    return [userDefaults integerForKey:PW_GEN_LENGTH];
}

- (void)setPwGenLength:(NSInteger)pwGenLength {
    [userDefaults setInteger:pwGenLength forKey:PW_GEN_LENGTH];
}

- (NSInteger)pwGenCharSets {
    return [userDefaults integerForKey:PW_GEN_CHAR_SETS];
}

- (void)setPwGenCharSets:(NSInteger)pwGenCharSets {
    [userDefaults setInteger:pwGenCharSets forKey:PW_GEN_CHAR_SETS];
}

@end
