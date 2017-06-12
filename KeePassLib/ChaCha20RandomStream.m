/*
 * Copyright 2017 Jason Rush and John Flanagan. All rights reserved.
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

#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import "ChaCha20RandomStream.h"
#import "ChaCha20Cipher.h"


@interface ChaCha20RandomStream (PrivateMethods)
- (void)setKey:(uint8_t*)key;
- (void)setIV:(uint8_t*)iv;
- (uint)uint8To32Little:(uint8_t*)buffer offset:(uint32_t)offset;
- (uint32_t)rotl:(uint32_t)x y:(uint32_t)y;
- (void)updateState;
@end

@implementation ChaCha20RandomStream

- (id)init:(NSData *)key {
    self = [super init];
    if (self) {
        uint8_t key64[64];
        uint8_t key32[32];
        uint8_t iv12[12];

        CC_SHA512(key.bytes, (CC_LONG)key.length, key64);
        memcpy(key32, key64, 32);
        memcpy(iv12, &key64[32], 12);
        
        NSData *hkey = [[NSData alloc] initWithBytes:key32 length:32];
        NSData *iv = [[NSData alloc] initWithBytes:iv12 length:12];
        
        cipher = [[ChaCha20Cipher alloc] init:hkey iv:iv];
    }
    return self;
}

- (uint8_t)getByte {
    NSMutableData *value = [[NSMutableData alloc] initWithLength:1];
    [cipher Encrypt:value];
    uint8_t ret = ((uint8_t *)value.bytes)[0];
    
    return ret;
}

@end
