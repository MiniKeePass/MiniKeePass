//
//  Sha256OutputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "OutputStream.h"

@interface Sha256OutputStream : OutputStream {
    OutputStream *outputStream;
    
    CC_SHA256_CTX shaCtx;
    uint8_t hash[32];
}

- (id)initWithOutputStream:(OutputStream*)stream;
- (uint8_t*)getHash;

@end
