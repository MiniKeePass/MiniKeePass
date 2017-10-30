//
//  Salsa20RandomStream.m
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import "Salsa20RandomStream.h"
#import "Salsa20Cipher.h"

@interface Salsa20RandomStream (PrivateMethods)
- (uint8_t)getByte;
@end

@implementation Salsa20RandomStream

- (id)init {
    uint8_t buffer[256];
    
    (void) SecRandomCopyBytes(kSecRandomDefault, sizeof(buffer), buffer);
    
    return [self init:[NSData dataWithBytes:buffer length:sizeof(buffer)]];
}

- (id)init:(NSData *)key {
    self = [super init];
    if (self) {
        uint8_t key32[32];
        CC_SHA256(key.bytes, (CC_LONG)key.length, key32);
        
        uint8_t ivvec[] = {0xE8, 0x30, 0x09, 0x4B, 0x97, 0x20, 0x5D, 0x2A};
        
        NSData *hkey = [[NSData alloc] initWithBytes:key32 length:32];
        NSData *iv = [[NSData alloc] initWithBytes:ivvec length:sizeof(ivvec)];
        cipher = [[Salsa20Cipher alloc] init:hkey iv:iv];
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
