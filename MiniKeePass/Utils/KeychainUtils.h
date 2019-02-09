//
//  SFHFKeychainUtils.h
//
//  Created by Buzz Andersen on 10/20/08.
//  Based partly on code by Jonathan Wight, Jon Crosby, and Mike Malone.
//  Copyright 2008 Sci-Fi Hi-Fi. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import <UIKit/UIKit.h>

#define KEYCHAIN_VERSION_SERVICE   @"com.jflan.MiniKeePass.version"
#define KEYCHAIN_PIN_SERVICE       @"com.jflan.MiniKeePass.pin"

// The V2 services protect against a malicious user rolling back the version
// to a version that didn't check for version compatibility using the keychain
// and thus was vulnerable to vulnerabilites in the prior versions. Specifically,
// there was a vulnerability where a malicious user could delete the app and
// and install an old version which would set the PIN to disabled but database
// passwords that were remembered were not forgotten.
#define KEYCHAIN_PASSWORDS_V1_SERVICE @"com.jflan.MiniKeePass.passwords"
#define KEYCHAIN_PASSWORDS_V2_SERVICE @"com.jflan.MiniKeePass.passwords2"
#define KEYCHAIN_PASSWORDS_SERVICE KEYCHAIN_PASSWORDS_V2_SERVICE

#define KEYCHAIN_KEYFILES_V1_SERVICE  @"com.jflan.MiniKeePass.keyfiles"
#define KEYCHAIN_KEYFILES_V2_SERVICE  @"com.jflan.MiniKeePass.keyfiles2"
#define KEYCHAIN_KEYFILES_SERVICE  KEYCHAIN_KEYFILES_V2_SERVICE

@interface KeychainUtils : NSObject

+ (NSString *)stringForKey:(NSString *)key andServiceName:(NSString *)serviceName;
+ (BOOL)setString:(NSString *)string forKey:(NSString *)key andServiceName:(NSString *)serviceName;
+ (BOOL)deleteStringForKey:(NSString *)key andServiceName:(NSString *)serviceName;
+ (BOOL)deleteAllForServiceName:(NSString *)serviceName;
+ (BOOL)renameAllForServiceName:(NSString *)serviceName newServiceName:(NSString *)newServiceName;

@end
