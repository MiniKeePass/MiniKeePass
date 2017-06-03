/*
 * Copyright 2011-2015 Jason Rush and John Flanagan. All rights reserved.
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

#import "PasswordUtils.h"

#import <CommonCrypto/CommonKeyDerivation.h>

@implementation PasswordUtils

static NSUInteger const kDefaultSaltSize = 64;
static NSUInteger const kDefaultKeySize = 64;
static NSUInteger const kDefaultRounds = 10000;

+ (NSData *)generateSaltOfSize:(NSInteger)size {
    NSMutableData *data = [NSMutableData dataWithLength:size];
    (void) SecRandomCopyBytes(kSecRandomDefault, size, data.mutableBytes);
    return data;
}

+ (NSString *)hashPassword:(NSString *)password withSalt:(NSData *)salt andRounds:(NSUInteger)rounds andKeySize:(NSInteger)keySize {
    NSMutableData *derivedKey = [NSMutableData dataWithLength:keySize];

    // Get the data by converting the string to ISO 8859-1 characters
    NSData *passwordData = [password dataUsingEncoding:NSISOLatin1StringEncoding];

    CCKeyDerivationPBKDF(kCCPBKDF2, passwordData.bytes, passwordData.length, salt.bytes, salt.length, kCCPRFHmacAlgSHA512, (unsigned int)rounds, derivedKey.mutableBytes, derivedKey.length);

    return [NSString stringWithFormat:@"sha512.%u.%@.%@", (unsigned int)rounds, [PasswordUtils hexStringFromData:salt], [PasswordUtils hexStringFromData:derivedKey]];
}

+ (NSString *)hashPassword:(NSString *)password {
    NSData *salt = [PasswordUtils generateSaltOfSize:kDefaultSaltSize];
    return [PasswordUtils hashPassword:password withSalt:salt andRounds:kDefaultRounds andKeySize:kDefaultKeySize];
}

+ (BOOL)validatePassword:(NSString *)password againstHash:(NSString *)hash {
    NSArray *tokens = [hash componentsSeparatedByString:@"."];

    NSString *algorithm = [tokens objectAtIndex:0];
    if (![algorithm isEqualToString:@"sha512"]) {
        NSLog(@"Invalid hash algorithm: %@", algorithm);
        return false;
    }

    NSString *roundsStr = [tokens objectAtIndex:1];
    NSInteger rounds = [roundsStr integerValue];

    NSString *saltHex = [tokens objectAtIndex:2];
    NSData *salt = [PasswordUtils dataFromHexString:saltHex];

    NSString *str = [PasswordUtils hashPassword:password withSalt:salt andRounds:rounds andKeySize:kDefaultKeySize];

    return [str isEqualToString:hash];
}

+ (NSData *)dataFromHexString:(NSString *)string {
    NSData *strData = [string dataUsingEncoding:NSISOLatin1StringEncoding];
    const uint8_t *strBytes = strData.bytes;
    NSUInteger n = strData.length;

    NSMutableData *data = [NSMutableData dataWithLength:n / 2];
    uint8_t *dataBytes = data.mutableBytes;

    for (int i = 0, j = 0; i < n; i += 2, j++) {
        char hex[3] = {strBytes[i], strBytes[i + 1], '\0'};
        dataBytes[j] = strtol(hex, NULL, 16);
    }

    return data;
}

+ (NSString *)hexStringFromData:(NSData *)data {
    const uint8_t *bytes = data.bytes;
    NSUInteger n = data.length;

    NSMutableString *string = [NSMutableString stringWithCapacity:n * 2];

    for (int i = 0; i < n; i++) {
        [string appendFormat:@"%02X", bytes[i]];
    }

    return string;
}

@end
