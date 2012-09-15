//
//  Kdb3Utils.m
//  MiniKeePass
//
//  Created by Jason Rush on 9/14/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "Kdb3Utils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Kdb3Utils

+ (NSData *)hashHeader:(kdb3_header_t *)header {
    uint8_t *buffer = (uint8_t *)header;
    size_t endCount = sizeof(header->masterSeed2) + sizeof(header->keyEncRounds);
    size_t startCount = sizeof(kdb3_header_t) - sizeof(header->contentsHash) - endCount;
    uint8_t hash[32];

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, buffer, startCount);
    CC_SHA256_Update(&ctx, buffer + (sizeof(kdb3_header_t) - endCount), endCount);
    CC_SHA256_Final(hash, &ctx);

    return [NSData dataWithBytes:hash length:sizeof(hash)];
}

@end
