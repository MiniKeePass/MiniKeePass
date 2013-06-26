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

#import "KeychainUtils.h"
#import <Security/Security.h>

@implementation KeychainUtils

+ (NSString *)stringForKey:(NSString *)key andServiceName:(NSString *)serviceName {
    CFTypeRef result_data = NULL;
	OSStatus status;

    // Check the arguments
    if (key == nil || serviceName == nil) {
        return nil;
    }

    NSDictionary *query = @{
                            (__bridge id)kSecReturnData : (id)kCFBooleanTrue,
                            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : serviceName,
                            (__bridge id)kSecAttrAccount : key,
                            };

    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result_data);
	if (status != errSecSuccess) {
        return nil;
    }

    NSData *resultData = (__bridge_transfer NSData *)result_data;
    NSString *string = [[NSString alloc] initWithData:(id)resultData encoding:NSUTF8StringEncoding];

	return string;
}

+ (BOOL)setString:(NSString *)string forKey:(NSString *)key andServiceName:(NSString *)serviceName {
    OSStatus status;

    // Check the arguments
    if (string == nil || key == nil || serviceName == nil) {
        return NO;
    }

    // Check if the item already exists
    NSString *existingPassword = [KeychainUtils stringForKey:key andServiceName:serviceName];
    if (existingPassword != nil) {
        // Update
        NSDictionary *query = @{
                                (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrService : serviceName,
                                (__bridge id)kSecAttrAccount : key,
                                };

        NSDictionary *attributesToUpdate = @{
                                             (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked,
                                             (__bridge id)kSecValueData : [string dataUsingEncoding:NSUTF8StringEncoding],
                                             };

        status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
    } else {
        // Add
        NSDictionary *attributes = @{
                                     (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                     (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked,
                                     (__bridge id)kSecAttrService : serviceName,
                                     (__bridge id)kSecAttrAccount : key,
                                     (__bridge id)kSecValueData : [string dataUsingEncoding:NSUTF8StringEncoding],
                                     };

        status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
    }

    return status == errSecSuccess;
}

+ (BOOL)deleteStringForKey:(NSString *)key andServiceName:(NSString *)serviceName {
    OSStatus status;

    // Check the arguments
    if (key == nil || serviceName == nil) {
        return NO;
    }

    NSDictionary *query = @{
                            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : serviceName,
                            (__bridge id)kSecAttrAccount : key,
                            };
    
    status = SecItemDelete((__bridge CFDictionaryRef)query);
    
    return status == errSecSuccess;
}

+ (BOOL)deleteAllForServiceName:(NSString *)serviceName {
    OSStatus status;

    // Check the arguments
    if (serviceName == nil) {
        return NO;
    }

    NSDictionary *query = @{
                            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : serviceName,
                            };
    
    status = SecItemDelete((__bridge CFDictionaryRef)query);
    
    return status == errSecSuccess;
}

@end
