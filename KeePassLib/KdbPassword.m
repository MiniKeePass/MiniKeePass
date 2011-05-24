//
//  Password.m
//  KeePass2
//
//  Created by Qiang Yu on 1/5/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "KdbPassword.h"
#import "Utils.h"

@interface KdbPassword(PrivateMethods)
- (void)transformKeyHash:(uint8_t*)keyHash result:(uint8_t*)result;
@end

@implementation KdbPassword

+ (NSData*)createFinalKey32ForPasssword:(NSString*)password encoding:(NSStringEncoding)encoding kdbVersion:(uint8_t)version masterSeed:(NSData*)masterSeed transformSeed:(NSData*)transformSeed rounds:(uint64_t)rounds {
    NSData *pass = [password dataUsingEncoding:encoding];
    
    uint8_t keyHash[32];
    CC_SHA256(pass.bytes, pass.length, keyHash);
    if (version == 4) {
        CC_SHA256(keyHash, 32, keyHash);
    }
    
    // Step 1 transform the key
    CCCryptorRef cryptorRef;
    CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, transformSeed.bytes, kCCKeySizeAES256, nil, &cryptorRef);
    
    size_t tmp;
    for (int i = 0; i < rounds; i++) {
        CCCryptorUpdate(cryptorRef, keyHash, 32, keyHash, 32, &tmp);
    }
    
    CCCryptorRelease(cryptorRef);
    
    uint8_t transformed[32];
    CC_SHA256(keyHash, 32, transformed);
    
    // Step 2 hash the transform result
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, masterSeed.bytes, masterSeed.length);
    CC_SHA256_Update(&ctx, transformed, 32);
    
    uint8_t key[32];
    CC_SHA256_Final(key, &ctx);
    
    return [NSData dataWithBytes:key length:32];
}

@end
