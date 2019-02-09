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
#import "KeychainUtils.h"
#import "PasswordUtils.h"
#import "AppDelegate.h"
#import "MiniKeePass-Swift.h"

#define VERSION                    @"version"
#define EXIT_TIME                  @"exitTime"
#define PIN_ENABLED                @"pinEnabled"
#define PIN                        @"PIN"
#define PIN_LOCK_TIMEOUT           @"pinLockTimeout"
#define PIN_FAILED_ATTEMPTS        @"pinFailedAttempts"
#define TOUCH_ID_ENABLED           @"touchIdEnabled"
#define DELETE_ON_FAILURE_ENABLED  @"deleteOnFailureEnabled"
#define DELETE_ON_FAILURE_ATTEMPTS @"deleteOnFailureAttempts"
#define CLOSE_ENABLED              @"closeEnabled"
#define CLOSE_TIMEOUT              @"closeTimeout"
#define REMEMBER_PASSWORDS         @"rememberPasswords"
#define REMEMBER_PASSWORDS_ENABLED @"rememberPasswordsEnabled"
#define HIDE_PASSWORDS             @"hidePasswords"
#define SORT_ALPHABETICALLY        @"sortAlphabetically"
#define SEARCH_TITLE_ONLY          @"searchTitleOnly"
#define PASSWORD_ENCODING          @"passwordEncoding"
#define CLEAR_CLIPBOARD_ENABLED    @"clearClipboardEnabled"
#define BACKUP_DISABLED            @"backupDisabled"
#define CLEAR_CLIPBOARD_TIMEOUT    @"clearClipboardTimeout"
#define WEB_BROWSER_INTEGRATED     @"webBrowserIntegrated"
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

static RememberPasswords rememberPasswordsValues[] = {
    Never,
    WhenConfigured,
    Always
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
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:TOUCH_ID_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:DELETE_ON_FAILURE_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:1] forKey:DELETE_ON_FAILURE_ATTEMPTS];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:CLOSE_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:4] forKey:CLOSE_TIMEOUT];
        [defaultsDict setValue:[NSNumber numberWithInt:0] forKey:REMEMBER_PASSWORDS];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:HIDE_PASSWORDS];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:SORT_ALPHABETICALLY];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:SEARCH_TITLE_ONLY];
        [defaultsDict setValue:[NSNumber numberWithInt:0] forKey:PASSWORD_ENCODING];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:CLEAR_CLIPBOARD_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:0] forKey:CLEAR_CLIPBOARD_TIMEOUT];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:BACKUP_DISABLED];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:WEB_BROWSER_INTEGRATED];
        [defaultsDict setValue:[NSNumber numberWithInt:10] forKey:PW_GEN_LENGTH];
        [defaultsDict setValue:[NSNumber numberWithInt:0x07] forKey:PW_GEN_CHAR_SETS];
        [userDefaults registerDefaults:defaultsDict];

        [self upgrade];
    }
    return self;
}


// This allows version such as "1.0" to be compared to "1.0.1", which will return <0
// if (lhsVersion < rhsVersion) then return <0
// if (lhsVersion == rhsVersion) then return 0
// if (lhsVersion > rhsVersion) then return >0
- (int)versionCompare:(NSString *)lhsVersion rhsVersion:(NSString *)rhsVersion {
    NSString *delimeter = @".";
    NSArray *lhsVersionArr = [lhsVersion componentsSeparatedByString:delimeter];
    NSArray *rhsVersionArr = [rhsVersion componentsSeparatedByString:delimeter];

    for(int i = 0; i < [lhsVersionArr count] && i < [rhsVersionArr count]; ++i) {
        int lhs = [lhsVersionArr[i] intValue];
        int rhs = [rhsVersionArr[i] intValue];
        if (lhs < rhs) {
            return -1;
        }
        if (lhs > rhs) {
            return 1;
        }
    }
    if ([lhsVersionArr count] < [rhsVersionArr count]) {
        return -1;
    } else if ([lhsVersionArr count] > [rhsVersionArr count]) {
        return 1;
    }
    return 0;
}

- (void)clearKeychainForUpgrade {
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_PIN_SERVICE];
    
    // Clear all versions of keychain passwords
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_PASSWORDS_SERVICE];
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_PASSWORDS_V1_SERVICE];
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_PASSWORDS_V2_SERVICE];

    // Clear all versions of keyfile passwords
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_KEYFILES_SERVICE];
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_KEYFILES_V1_SERVICE];
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_KEYFILES_V2_SERVICE];

    // Clear the version last so that there isn't a race condition with the keychain version
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_VERSION_SERVICE];
}

- (void)upgrade {
    NSString *version = [self version];
    NSString *keychainVersion = [KeychainUtils stringForKey:VERSION andServiceName:KEYCHAIN_VERSION_SERVICE];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    if (version == nil) {
        // Version 1.6 was released Jun 14, 2015, this was the first version
        // to set the version number. Version 1.6 was also the first version to
        // have upgrade instructions. So prior versions didn't set the version
        // number stored in the configuration. The EXIT_TIME, PIN_ENABLED,
        // PIN_LOCK_TIMEOUT, and PIN_FAILED_ATTEMPTS properties are used to
        // determine the difference between an upgrade from a verion prior to
        // version 1.6 and a fresh install of the current version.
        if ([userDefaults objectForKey:EXIT_TIME] != nil ||
            [userDefaults objectForKey:PIN_ENABLED] != nil ||
            [userDefaults objectForKey:PIN_LOCK_TIMEOUT] != nil ||
            [userDefaults objectForKey:PIN_FAILED_ATTEMPTS] != nil) {
            version = @"1.5.2"; // The version is at most 1.5.2
        }
    }
    
    if (version != nil) {
        // This is not a fresh install, so upgrade the configuration
        if (keychainVersion != nil) {
            if ([self versionCompare:version rhsVersion:keychainVersion] != 0 ||
                [self versionCompare:currentVersion rhsVersion:keychainVersion] < 0) {
                // The version is being rolled back or it does not match the expected version
                // so clear out the keychain to protect against malicous activity
                [self clearKeychainForUpgrade];
            }
        }
        
        if ([self versionCompare:version rhsVersion:@"1.5.2"] <= 0) {
            [self upgrade152];
        }
    
        if ([self versionCompare:version rhsVersion:@"1.7.2"] <= 0) {
            [self upgrade172];
        }
    } else {
        // This is a fresh install
        // The keychain setting may survive from a previous version of the app
        // which was deleted.
        [self clearKeychainForUpgrade];
    }


    [self setVersion:currentVersion];
}

// Upgrade configuration from 1.5.2
- (void)upgrade152 {
    // Migrate the pin enabled setting
    BOOL pinEnabled = [userDefaults boolForKey:PIN_ENABLED];
    [self setPinEnabled:pinEnabled];
    
    // Migrate the pin lock timeout setting
    NSInteger pinLockTimeoutIndex = [userDefaults boolForKey:PIN_LOCK_TIMEOUT];
    [self setPinLockTimeoutIndex:pinLockTimeoutIndex];
    
    // Migrate the pin failed attempts setting
    NSInteger pinFailedAttempts = [userDefaults boolForKey:PIN_FAILED_ATTEMPTS];
    [self setPinFailedAttempts:pinFailedAttempts];

    // Check if we need to migrate the plaintext pin to the hashed pin
    NSString *pin = [self pin];
    if (![pin hasPrefix:@"sha512"]) {
        NSString *pinHash = [PasswordUtils hashPassword:pin];
        [self setPin:pinHash];
    }

    // Remove the old keys
    [userDefaults removeObjectForKey:EXIT_TIME];
    [userDefaults removeObjectForKey:PIN_ENABLED];
    [userDefaults removeObjectForKey:PIN_LOCK_TIMEOUT];
    [userDefaults removeObjectForKey:PIN_FAILED_ATTEMPTS];
}

// Upgrade configuration from 1.7.2
- (void)upgrade172 {
    // Remove keys which didn't exist in version 1.7.2 to protect against a malicious user rolling back the
    // version to reset the PIN
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_PASSWORDS_V2_SERVICE];
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_KEYFILES_V2_SERVICE];

    // Migrate the remember passwords enabled setting
    BOOL rememberPasswordsEnabled = [userDefaults boolForKey:REMEMBER_PASSWORDS_ENABLED];
    if (rememberPasswordsEnabled) {
        [self setRememberPasswordsIndex:(2)];
    }

    // Upgrade from v1 to v2 keychain services
    [KeychainUtils renameAllForServiceName:KEYCHAIN_PASSWORDS_V1_SERVICE newServiceName:KEYCHAIN_PASSWORDS_V2_SERVICE];
    [KeychainUtils renameAllForServiceName:KEYCHAIN_KEYFILES_V1_SERVICE newServiceName:KEYCHAIN_KEYFILES_V2_SERVICE];
    
    // Remove the old keys
    [userDefaults removeObjectForKey:REMEMBER_PASSWORDS_ENABLED];
}

- (NSString *)version {
    return [userDefaults stringForKey:VERSION];
}

- (void)setVersion:(NSString *)version {
    [userDefaults setValue:version forKey:VERSION];
    [KeychainUtils setString:version forKey:VERSION andServiceName:KEYCHAIN_VERSION_SERVICE];
}

- (NSDate *)exitTime {
    NSString *string = [KeychainUtils stringForKey:EXIT_TIME andServiceName:KEYCHAIN_PIN_SERVICE];
    if (string == nil) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSinceReferenceDate:[string doubleValue]];
}

- (void)setExitTime:(NSDate *)exitTime {
    NSNumber *number = [NSNumber numberWithDouble:[exitTime timeIntervalSinceReferenceDate]];
    [KeychainUtils setString:[number stringValue] forKey:EXIT_TIME andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (BOOL)pinEnabled {
    NSString *string = [KeychainUtils stringForKey:PIN_ENABLED andServiceName:KEYCHAIN_PIN_SERVICE];
    if (string == nil) {
        return NO;
    }
    return [string boolValue];
}

- (void)setPinEnabled:(BOOL)pinEnabled {
    NSNumber *number = [NSNumber numberWithBool:pinEnabled];
    [KeychainUtils setString:[number stringValue] forKey:PIN_ENABLED andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (NSString *)pin {
    return [KeychainUtils stringForKey:PIN andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (void)setPin:(NSString *)pin {
    [KeychainUtils setString:pin forKey:PIN andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (NSInteger)pinLockTimeout {
    NSInteger pinLockTimeoutIndex = [self pinLockTimeoutIndex];
    return pinLockTimeoutValues[pinLockTimeoutIndex];
}

- (NSInteger)pinLockTimeoutIndex {
    NSString *string = [KeychainUtils stringForKey:PIN_LOCK_TIMEOUT andServiceName:KEYCHAIN_PIN_SERVICE];
    if (string == nil) {
        return 1; // Default Value
    }
    return [string intValue];
}

- (void)setPinLockTimeoutIndex:(NSInteger)pinLockTimeoutIndex {
    NSNumber *number = [NSNumber numberWithInteger:pinLockTimeoutIndex];
    [KeychainUtils setString:[number stringValue] forKey:PIN_LOCK_TIMEOUT andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (NSInteger)pinFailedAttempts {
    NSString *string = [KeychainUtils stringForKey:PIN_FAILED_ATTEMPTS andServiceName:KEYCHAIN_PIN_SERVICE];
    if (string == nil) {
        return 0;
    }
    return [string integerValue];
}

- (void)setPinFailedAttempts:(NSInteger)pinFailedAttempts {
    NSNumber *number = [NSNumber numberWithInteger:pinFailedAttempts];
    [KeychainUtils setString:[number stringValue] forKey:PIN_FAILED_ATTEMPTS andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (BOOL)deleteOnFailureEnabled {
    return [userDefaults boolForKey:DELETE_ON_FAILURE_ENABLED];
}

- (BOOL)touchIdEnabled {
    return [userDefaults boolForKey:TOUCH_ID_ENABLED];
}

- (void)setTouchIdEnabled:(BOOL)touchIdEnabled {
    [userDefaults setBool:touchIdEnabled forKey:TOUCH_ID_ENABLED];
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

- (BOOL)backupDisabled {
    return [userDefaults boolForKey:BACKUP_DISABLED];
}

- (void)setBackupDisabled:(BOOL)backupDisabled {
    [userDefaults setBool:backupDisabled forKey:BACKUP_DISABLED];

    NSURL *url = [NSURL fileURLWithPath:[AppDelegate documentsDirectory] isDirectory:YES];

    NSError *error = nil;
    if (![url setResourceValue:[NSNumber numberWithBool:!backupDisabled] forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        NSLog(@"Error excluding %@ from backup: %@", url, error);
    }
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

- (RememberPasswords)rememberPasswords {
    NSInteger rememberPasswordsIndex = [self rememberPasswordsIndex];
    return rememberPasswordsValues[rememberPasswordsIndex];
}

- (NSInteger)rememberPasswordsIndex {
    return [userDefaults integerForKey:REMEMBER_PASSWORDS];
}

- (void)setRememberPasswordsIndex:(NSInteger)rememberPasswordsIndex {
    [userDefaults setInteger:rememberPasswordsIndex forKey:REMEMBER_PASSWORDS];
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

- (BOOL)searchTitleOnly {
    return [userDefaults boolForKey:SEARCH_TITLE_ONLY];
}

- (void)setSearchTitleOnly:(BOOL)searchTitleOnly {
    [userDefaults setBool:searchTitleOnly forKey:SEARCH_TITLE_ONLY];
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

- (BOOL)webBrowserIntegrated {
    return [userDefaults boolForKey:WEB_BROWSER_INTEGRATED];
}

- (void)setWebBrowserIntegrated:(BOOL)webBrowserIntegrated {
    [userDefaults setBool:webBrowserIntegrated forKey:WEB_BROWSER_INTEGRATED];
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
