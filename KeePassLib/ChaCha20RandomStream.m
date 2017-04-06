//
//  Salsa20RandomStream.m
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

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
        memcpy( key32, key64, 32);
        memcpy( iv12, &key64[32], 12);
        
        NSData *hkey = [[NSData alloc] initWithBytes:key32 length:sizeof(key32)];
        NSData *iv = [[NSData alloc] initWithBytes:iv12 length:sizeof(iv12)];
        cipher = [[ChaCha20Cipher alloc] init:hkey iv:iv];
    }
    return self;
}

- (uint8_t)getByte {
    NSMutableData *value = [[NSMutableData alloc] initWithLength:1];
    [cipher Encrypt:value];
    uint8_t ret = ((uint8_t *) value.bytes)[0];
    
    return ret;
}

@end
